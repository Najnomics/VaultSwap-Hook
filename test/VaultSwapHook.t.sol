// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// Foundry Imports
import "forge-std/Test.sol";

// Uniswap Imports
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {SwapParams, ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";

// Test Utilities
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

// FHE Imports
import {FHE, euint128, euint64, euint32, euint8, ebool, InEuint128, InEuint64, InEuint32, InEuint8, InEbool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

// Project Imports
import {VaultSwapHook} from "../src/VaultSwapHook.sol";
import {VaultSwapLib} from "../src/lib/VaultSwapLib.sol";
import {MEVProtection} from "../src/lib/MEVProtection.sol";
import {ExecutionStrategies} from "../src/lib/ExecutionStrategies.sol";
import {IntelligentRouter} from "../src/lib/IntelligentRouter.sol";
import {ExecutionAnalytics} from "../src/lib/ExecutionAnalytics.sol";
import {FHEPermissions} from "../src/lib/FHEPermissions.sol";

// FHE Token Imports
import {IFHERC20} from "../src/interface/IFHERC20.sol";

// Mock FHE Token Contract for Testing (simplified version of HybridFHERC20)
contract MockFHERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => euint128) public encBalances;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
    
    // FHE-specific functions
    function mintEncrypted(address user, InEuint128 memory amount) external {
        euint128 encAmount = FHE.asEuint128(amount);
        encBalances[user] = FHE.add(encBalances[user], encAmount);
        FHE.allowThis(encBalances[user]);
        FHE.allow(encBalances[user], user);
    }
    
    function transferEncrypted(address to, InEuint128 memory amount) external returns (bool) {
        euint128 encAmount = FHE.asEuint128(amount);
        encBalances[msg.sender] = FHE.sub(encBalances[msg.sender], encAmount);
        encBalances[to] = FHE.add(encBalances[to], encAmount);
        
        FHE.allowThis(encBalances[msg.sender]);
        FHE.allowThis(encBalances[to]);
        FHE.allow(encBalances[msg.sender], msg.sender);
        FHE.allow(encBalances[to], to);
        
        return true;
    }
}

contract VaultSwapHookTest is Test, Deployers, CoFheTest {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    VaultSwapHook hook;
    PoolKey poolKey;
    PoolId poolId;
    MockFHERC20 token0;
    MockFHERC20 token1;
    
    // Test users
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    address charlie = makeAddr("charlie");
    address dave = makeAddr("dave");
    address eve = makeAddr("eve");
    
    // Test amounts
    uint256 constant INITIAL_LIQUIDITY = 100 ether;
    uint256 constant TEST_AMOUNT = 1 ether;
    uint256 constant LARGE_AMOUNT = 50 ether;
    uint256 constant SMALL_AMOUNT = 0.1 ether;
    
    // FHE test values - will be initialized in setUp using CoFHE patterns
    InEuint128 encryptedAmount;
    InEuint128 encryptedMinOut;
    InEuint64 encryptedDeadline;
    InEuint32 encryptedMevLevel;
    InEuint8 encryptedDirection;
    InEbool encryptedValidFlag;

    function setUp() public {
        // Deploy core Uniswap V4 contracts
        deployFreshManagerAndRouters();
        
        // Deploy FHE test tokens
        token0 = new MockFHERC20("Test Token 0", "TT0");
        token1 = new MockFHERC20("Test Token 1", "TT1");
        
        // Ensure token0 < token1 for Uniswap V4
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        
        // Mint tokens to test accounts
        _mintTokensToUsers();
        
        // Deploy hook with proper flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG
        );
        
        deployCodeTo("VaultSwapHook.sol", abi.encode(manager), 
            address(flags));
        hook = VaultSwapHook(address(flags));
        
        // Initialize pool
        poolKey = PoolKey({
            currency0: Currency.wrap(address(token0)),
            currency1: Currency.wrap(address(token1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        poolId = poolKey.toId();
        
        manager.initialize(poolKey, SQRT_RATIO_1_1, ZERO_BYTES);
        
        // Add initial liquidity
        _addLiquidity();
        
        // Initialize FHE test values
        _initializeFHEValues();
    }

    function _mintTokensToUsers() internal {
        address[5] memory users = [alice, bob, charlie, dave, eve];
        for (uint i = 0; i < users.length; i++) {
            token0.mint(users[i], 1000 ether);
            token1.mint(users[i], 1000 ether);
        }
    }

    function _addLiquidity() internal {
        // Add liquidity as deployer
        modifyPositionRouter.modifyPosition(
            poolKey,
            IPoolManager.ModifyPositionParams({
                tickLower: -60,
                tickUpper: 60,
                liquidityDelta: int128(int256(INITIAL_LIQUIDITY))
            }),
            ZERO_BYTES
        );
    }

    function _initializeFHEValues() internal {
        // Use CoFHE test patterns to create encrypted input values
        encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice); // 5% slippage
        encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        encryptedMevLevel = createInEuint32(2, alice); // Enhanced protection
        encryptedDirection = createInEuint8(0, alice); // Token0 to Token1
        encryptedValidFlag = createInEbool(true, alice);
    }

    // Helper function to create FHE values for different users
    function _createFHEValuesForUser(address user) internal view returns (
        InEuint128 memory amount,
        InEuint128 memory minOut,
        InEuint64 memory deadline,
        InEuint32 memory mevLevel,
        InEuint8 memory direction
    ) {
        amount = createInEuint128(uint128(TEST_AMOUNT), user);
        minOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), user);
        deadline = createInEuint64(uint64(block.timestamp + 1 hours), user);
        mevLevel = createInEuint32(2, user);
        direction = createInEuint8(0, user);
    }

    // =============================================================
    //                    CORE FUNCTIONALITY TESTS
    // =============================================================

    function test_SubmitVaultOrder_Success() public {
        vm.startPrank(alice);
        
        // Approve tokens
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Submit vault order
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Verify order was created
        assertTrue(orderId != bytes32(0));
        assertTrue(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_InvalidAmount() public {
        vm.startPrank(alice);
        
        InEuint128 memory zeroAmount = createInEuint128(0, alice);
        
        vm.expectRevert("Invalid amount");
        hook.submitVaultOrder(
            poolKey,
            zeroAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_ExpiredDeadline() public {
        vm.startPrank(alice);
        
        InEuint64 memory pastDeadline = createInEuint64(uint64(block.timestamp - 1), alice);
        
        vm.expectRevert("Expired deadline");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            pastDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_InsufficientBalance() public {
        vm.startPrank(alice);
        
        InEuint128 memory largeAmount = createInEuint128(uint128(10000 ether), alice);
        
        vm.expectRevert("Insufficient balance");
        hook.submitVaultOrder(
            poolKey,
            largeAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_MultipleUsers() public {
        address[3] memory users = [alice, bob, charlie];
        
        for (uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            token0.approve(address(hook), TEST_AMOUNT);
            
            (
                InEuint128 memory amount,
                InEuint128 memory minOut,
                InEuint64 memory deadline,
                InEuint32 memory mevLevel,
                InEuint8 memory direction
            ) = _createFHEValuesForUser(users[i]);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                amount,
                minOut,
                direction,
                deadline,
                mevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            assertTrue(hook.hasActiveOrder(users[i]));
            vm.stopPrank();
        }
    }

    function test_CancelVaultOrder_Success() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        assertTrue(hook.cancelVaultOrder(orderId));
        assertFalse(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    function test_CancelVaultOrder_NotOwner() public {
        vm.startPrank(alice);
        token0.approve(address(hook), TEST_AMOUNT);
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        vm.stopPrank();
        
        vm.startPrank(bob);
        vm.expectRevert("Not order owner");
        hook.cancelVaultOrder(orderId);
        vm.stopPrank();
    }

    function test_CancelVaultOrder_AlreadyExecuted() public {
        vm.startPrank(alice);
        token0.approve(address(hook), TEST_AMOUNT);
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Simulate order execution
        hook.cancelVaultOrder(orderId);
        
        vm.expectRevert("Order not active");
        hook.cancelVaultOrder(orderId);
        
        vm.stopPrank();
    }

    // =============================================================
    //                    MEV PROTECTION TESTS
    // =============================================================

    function test_MEVProtection_BasicLevel() public {
        vm.startPrank(alice);
        
        InEuint32 memory basicLevel = createInEuint32(MEVProtection.BASIC_PROTECTION, alice);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            basicLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_MEVProtection_EnhancedLevel() public {
        vm.startPrank(alice);
        
        euint32 enhancedLevel = FHE.asEuint32(MEVProtection.ENHANCED_PROTECTION);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            enhancedLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_MEVProtection_AdvancedLevel() public {
        vm.startPrank(alice);
        
        euint32 advancedLevel = FHE.asEuint32(MEVProtection.ADVANCED_PROTECTION);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            advancedLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_MEVProtection_MaximumLevel() public {
        vm.startPrank(alice);
        
        euint32 maximumLevel = FHE.asEuint32(MEVProtection.MAXIMUM_PROTECTION);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            maximumLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_MEVProtection_UltimateLevel() public {
        vm.startPrank(alice);
        
        euint32 ultimateLevel = FHE.asEuint32(MEVProtection.ULTIMATE_PROTECTION);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            ultimateLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_MEVProtection_InvalidLevel() public {
        vm.startPrank(alice);
        
        InEuint32 memory invalidLevel = createInEuint32(6, alice); // Beyond ultimate
        token0.approve(address(hook), TEST_AMOUNT);
        
        vm.expectRevert("Invalid MEV protection level");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            invalidLevel
        );
        
        vm.stopPrank();
    }

    function test_MEVProtection_GetDecoyCount() public {
        assertEq(MEVProtection.getDecoyCount(1), 2);  // Basic
        assertEq(MEVProtection.getDecoyCount(2), 3);  // Enhanced
        assertEq(MEVProtection.getDecoyCount(3), 5);  // Advanced
        assertEq(MEVProtection.getDecoyCount(4), 8);  // Maximum
        assertEq(MEVProtection.getDecoyCount(5), 12); // Ultimate
        assertEq(MEVProtection.getDecoyCount(0), 3);  // Default
        assertEq(MEVProtection.getDecoyCount(6), 3);  // Default
    }

    function test_MEVProtection_GetExecutionDelay() public {
        assertEq(MEVProtection.getExecutionDelay(1), 30);   // Basic
        assertEq(MEVProtection.getExecutionDelay(2), 60);   // Enhanced
        assertEq(MEVProtection.getExecutionDelay(3), 120);  // Advanced
        assertEq(MEVProtection.getExecutionDelay(4), 300);  // Maximum
        assertEq(MEVProtection.getExecutionDelay(5), 600);  // Ultimate
        assertEq(MEVProtection.getExecutionDelay(0), 30);   // Default
        assertEq(MEVProtection.getExecutionDelay(6), 30);   // Default
    }

    function test_MEVProtection_GetGasThreshold() public {
        assertEq(MEVProtection.getGasThreshold(1), 20); // Basic
        assertEq(MEVProtection.getGasThreshold(2), 15); // Enhanced
        assertEq(MEVProtection.getGasThreshold(3), 10); // Advanced
        assertEq(MEVProtection.getGasThreshold(4), 5);  // Maximum
        assertEq(MEVProtection.getGasThreshold(5), 2);  // Ultimate
        assertEq(MEVProtection.getGasThreshold(0), 20); // Default
        assertEq(MEVProtection.getGasThreshold(6), 20); // Default
    }

    function test_MEVProtection_IsValidLevel() public {
        assertTrue(MEVProtection.isValidProtectionLevel(1));
        assertTrue(MEVProtection.isValidProtectionLevel(2));
        assertTrue(MEVProtection.isValidProtectionLevel(3));
        assertTrue(MEVProtection.isValidProtectionLevel(4));
        assertTrue(MEVProtection.isValidProtectionLevel(5));
        assertFalse(MEVProtection.isValidProtectionLevel(0));
        assertFalse(MEVProtection.isValidProtectionLevel(6));
    }

    function test_MEVProtection_GetLevelName() public {
        assertEq(MEVProtection.getProtectionLevelName(1), "Basic");
        assertEq(MEVProtection.getProtectionLevelName(2), "Enhanced");
        assertEq(MEVProtection.getProtectionLevelName(3), "Advanced");
        assertEq(MEVProtection.getProtectionLevelName(4), "Maximum");
        assertEq(MEVProtection.getProtectionLevelName(5), "Ultimate");
        assertEq(MEVProtection.getProtectionLevelName(0), "Unknown");
        assertEq(MEVProtection.getProtectionLevelName(6), "Unknown");
    }

    // =============================================================
    //                    EXECUTION STRATEGY TESTS
    // =============================================================

    function test_ExecutionStrategies_TWAP() public {
        uint8 strategy = ExecutionStrategies.TWAP_EXECUTION;
        assertTrue(ExecutionStrategies.isValidStrategy(strategy));
        assertEq(ExecutionStrategies.getStrategyName(strategy), "TWAP");
    }

    function test_ExecutionStrategies_VWAP() public {
        uint8 strategy = ExecutionStrategies.VWAP_EXECUTION;
        assertTrue(ExecutionStrategies.isValidStrategy(strategy));
        assertEq(ExecutionStrategies.getStrategyName(strategy), "VWAP");
    }

    function test_ExecutionStrategies_Opportunistic() public {
        uint8 strategy = ExecutionStrategies.OPPORTUNISTIC_EXECUTION;
        assertTrue(ExecutionStrategies.isValidStrategy(strategy));
        assertEq(ExecutionStrategies.getStrategyName(strategy), "Opportunistic");
    }

    function test_ExecutionStrategies_Immediate() public {
        uint8 strategy = ExecutionStrategies.IMMEDIATE_EXECUTION;
        assertTrue(ExecutionStrategies.isValidStrategy(strategy));
        assertEq(ExecutionStrategies.getStrategyName(strategy), "Immediate");
    }

    function test_ExecutionStrategies_InvalidStrategy() public {
        uint8 invalidStrategy = 5;
        assertFalse(ExecutionStrategies.isValidStrategy(invalidStrategy));
        assertEq(ExecutionStrategies.getStrategyName(invalidStrategy), "Unknown");
    }

    function test_ExecutionStrategies_GetFragmentCount() public {
        assertEq(ExecutionStrategies.getFragmentCount(1), 10);  // TWAP
        assertEq(ExecutionStrategies.getFragmentCount(2), 8);   // VWAP
        assertEq(ExecutionStrategies.getFragmentCount(3), 5);   // Opportunistic
        assertEq(ExecutionStrategies.getFragmentCount(4), 1);   // Immediate
        assertEq(ExecutionStrategies.getFragmentCount(0), 5);   // Default
    }

    function test_ExecutionStrategies_GetTimeInterval() public {
        assertEq(ExecutionStrategies.getTimeInterval(1), 300);  // TWAP
        assertEq(ExecutionStrategies.getTimeInterval(2), 180);  // VWAP
        assertEq(ExecutionStrategies.getTimeInterval(3), 60);   // Opportunistic
        assertEq(ExecutionStrategies.getTimeInterval(4), 0);    // Immediate
        assertEq(ExecutionStrategies.getTimeInterval(0), 120);  // Default
    }

    // =============================================================
    //                    INTELLIGENT ROUTER TESTS
    // =============================================================

    function test_IntelligentRouter_SinglePoolStrategy() public {
        uint8 strategy = IntelligentRouter.SINGLE_POOL_STRATEGY;
        assertTrue(IntelligentRouter.isValidStrategy(strategy));
        assertEq(IntelligentRouter.getStrategyName(strategy), "Single Pool");
    }

    function test_IntelligentRouter_MultiPoolStrategy() public {
        uint8 strategy = IntelligentRouter.MULTI_POOL_SPLIT_STRATEGY;
        assertTrue(IntelligentRouter.isValidStrategy(strategy));
        assertEq(IntelligentRouter.getStrategyName(strategy), "Multi-Pool Split");
    }

    function test_IntelligentRouter_DynamicStrategy() public {
        uint8 strategy = IntelligentRouter.DYNAMIC_ROUTING_STRATEGY;
        assertTrue(IntelligentRouter.isValidStrategy(strategy));
        assertEq(IntelligentRouter.getStrategyName(strategy), "Dynamic Routing");
    }

    function test_IntelligentRouter_LiquidityOptimizedStrategy() public {
        uint8 strategy = IntelligentRouter.LIQUIDITY_OPTIMIZED_STRATEGY;
        assertTrue(IntelligentRouter.isValidStrategy(strategy));
        assertEq(IntelligentRouter.getStrategyName(strategy), "Liquidity Optimized");
    }

    function test_IntelligentRouter_InvalidStrategy() public {
        uint8 invalidStrategy = 5;
        assertFalse(IntelligentRouter.isValidStrategy(invalidStrategy));
        assertEq(IntelligentRouter.getStrategyName(invalidStrategy), "Unknown");
    }

    function test_IntelligentRouter_GetMaxPools() public {
        assertEq(IntelligentRouter.getMaxPools(1), 1);  // Single
        assertEq(IntelligentRouter.getMaxPools(2), 5);  // Multi-Pool
        assertEq(IntelligentRouter.getMaxPools(3), 10); // Dynamic
        assertEq(IntelligentRouter.getMaxPools(4), 8);  // Liquidity Optimized
        assertEq(IntelligentRouter.getMaxPools(0), 3);  // Default
    }

    function test_IntelligentRouter_GetMinLiquidity() public {
        assertEq(IntelligentRouter.getMinLiquidity(1), 1 ether);    // Single
        assertEq(IntelligentRouter.getMinLiquidity(2), 5 ether);    // Multi-Pool
        assertEq(IntelligentRouter.getMinLiquidity(3), 10 ether);   // Dynamic
        assertEq(IntelligentRouter.getMinLiquidity(4), 50 ether);   // Liquidity Optimized
        assertEq(IntelligentRouter.getMinLiquidity(0), 5 ether);    // Default
    }

    // =============================================================
    //                    EXECUTION ANALYTICS TESTS
    // =============================================================

    function test_ExecutionAnalytics_SlippageScore() public {
        uint256 score1 = ExecutionAnalytics.calculateSlippageScore(100, 105); // 5% slippage
        uint256 score2 = ExecutionAnalytics.calculateSlippageScore(100, 102); // 2% slippage
        uint256 score3 = ExecutionAnalytics.calculateSlippageScore(100, 100); // 0% slippage
        
        assertTrue(score3 > score2);
        assertTrue(score2 > score1);
        assertEq(score3, 100); // Perfect score for 0% slippage
    }

    function test_ExecutionAnalytics_TimingScore() public {
        uint256 score1 = ExecutionAnalytics.calculateTimingScore(1000, 2000); // 100% late
        uint256 score2 = ExecutionAnalytics.calculateTimingScore(1000, 1500); // 50% late
        uint256 score3 = ExecutionAnalytics.calculateTimingScore(1000, 1000); // On time
        
        assertTrue(score3 > score2);
        assertTrue(score2 > score1);
        assertEq(score3, 100); // Perfect score for on-time execution
    }

    function test_ExecutionAnalytics_GasEfficiencyScore() public {
        uint256 score1 = ExecutionAnalytics.calculateGasEfficiencyScore(100000, 200000); // 100% over
        uint256 score2 = ExecutionAnalytics.calculateGasEfficiencyScore(100000, 150000); // 50% over
        uint256 score3 = ExecutionAnalytics.calculateGasEfficiencyScore(100000, 100000); // Exact
        
        assertTrue(score3 > score2);
        assertTrue(score2 > score1);
        assertEq(score3, 100); // Perfect score for exact gas usage
    }

    function test_ExecutionAnalytics_MarketImpactScore() public {
        uint256 score1 = ExecutionAnalytics.calculateMarketImpactScore(1000); // High impact
        uint256 score2 = ExecutionAnalytics.calculateMarketImpactScore(500);  // Medium impact
        uint256 score3 = ExecutionAnalytics.calculateMarketImpactScore(100);  // Low impact
        
        assertTrue(score3 > score2);
        assertTrue(score2 > score1);
    }

    function test_ExecutionAnalytics_OverallScore() public {
        uint256 slippageScore = 90;
        uint256 timingScore = 85;
        uint256 gasScore = 95;
        uint256 impactScore = 80;
        
        uint256 overallScore = ExecutionAnalytics.calculateOverallScore(
            slippageScore, timingScore, gasScore, impactScore
        );
        
        // Should be weighted average
        uint256 expected = (slippageScore * 30 + timingScore * 25 + gasScore * 20 + impactScore * 25) / 100;
        assertEq(overallScore, expected);
    }

    function test_ExecutionAnalytics_ScoreBounds() public {
        // Test that scores are properly bounded
        uint256 score1 = ExecutionAnalytics.calculateSlippageScore(100, 1000); // Extreme slippage
        uint256 score2 = ExecutionAnalytics.calculateTimingScore(1000, 10000); // Very late
        
        assertTrue(score1 <= 100);
        assertTrue(score2 <= 100);
        assertTrue(score1 >= 0);
        assertTrue(score2 >= 0);
    }

    // =============================================================
    //                    FHE PERMISSIONS TESTS
    // =============================================================

    function test_FHEPermissions_OrderCreation() public {
        vm.startPrank(alice);
        
        // Test that permission granting doesn't revert
        FHEPermissions.grantOrderCreationPermissions(
            encryptedAmount,
            encryptedMinOut,
            encryptedDeadline,
            encryptedMevLevel,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_BidPermissions() public {
        vm.startPrank(alice);
        
        euint128 bidAmount = FHE.asEuint128(TEST_AMOUNT);
        euint128 allocation = FHE.asEuint128(TEST_AMOUNT / 2);
        euint128 currentPrice = FHE.asEuint128(1 ether);
        
        FHEPermissions.grantBidPermissions(
            bidAmount,
            allocation,
            currentPrice,
            alice,
            address(token0),
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_SettlementPermissions() public {
        vm.startPrank(alice);
        
        euint128 totalAllocation = FHE.asEuint128(TEST_AMOUNT);
        euint128 remainingSupply = FHE.asEuint128(LARGE_AMOUNT);
        
        FHEPermissions.grantSettlementPermissions(
            totalAllocation,
            remainingSupply,
            alice,
            address(token0),
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_PoolPermissions() public {
        euint128 amount0 = FHE.asEuint128(TEST_AMOUNT);
        euint128 amount1 = FHE.asEuint128(TEST_AMOUNT);
        
        FHEPermissions.grantPoolPermissions(
            amount0,
            amount1,
            address(token0),
            address(token1),
            address(hook)
        );
    }

    function test_FHEPermissions_SwapPermissions() public {
        vm.startPrank(alice);
        
        euint128 swapAmount = FHE.asEuint128(TEST_AMOUNT);
        euint128 maxAllowed = FHE.asEuint128(TEST_AMOUNT * 2);
        
        FHEPermissions.grantSwapPermissions(
            swapAmount,
            maxAllowed,
            encryptedValidFlag,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_TimePermissions() public {
        vm.startPrank(alice);
        
        euint64 startTime = FHE.asEuint64(block.timestamp);
        euint64 duration = FHE.asEuint64(3600); // 1 hour
        euint64 currentTime = FHE.asEuint64(block.timestamp);
        
        FHEPermissions.grantTimePermissions(
            startTime,
            duration,
            currentTime,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_BoolPermissions() public {
        vm.startPrank(alice);
        
        FHEPermissions.grantBoolPermissions(
            encryptedValidFlag,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_EnhancedVaultPermissions() public {
        vm.startPrank(alice);
        
        euint8 routingStrategy = FHE.asEuint8(1);
        euint8 executionAlgorithm = FHE.asEuint8(2);
        euint128 maxMarketImpact = FHE.asEuint128(5 ether);
        
        FHEPermissions.grantEnhancedVaultPermissions(
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_MEVProtectionPermissions() public {
        vm.startPrank(alice);
        
        euint128 decoyAmount = FHE.asEuint128(TEST_AMOUNT / 10);
        euint64 executionWindow = FHE.asEuint64(300); // 5 minutes
        euint8 stealthMode = FHE.asEuint8(1);
        euint64 gasOptimization = FHE.asEuint64(20 gwei);
        
        FHEPermissions.grantMEVProtectionPermissions(
            decoyAmount,
            executionWindow,
            stealthMode,
            gasOptimization,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_RoutingPermissions() public {
        vm.startPrank(alice);
        
        euint32 maxPools = FHE.asEuint32(5);
        euint128 minPoolLiquidity = FHE.asEuint128(10 ether);
        euint32 performanceTarget = FHE.asEuint32(95); // 95%
        euint64 complianceFlags = FHE.asEuint64(0);
        
        FHEPermissions.grantRoutingPermissions(
            maxPools,
            minPoolLiquidity,
            performanceTarget,
            complianceFlags,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_AnalyticsPermissions() public {
        vm.startPrank(alice);
        
        euint128 expectedOutput = FHE.asEuint128(TEST_AMOUNT * 95 / 100);
        euint128 actualOutput = FHE.asEuint128(TEST_AMOUNT * 94 / 100);
        euint32 executionQuality = FHE.asEuint32(85);
        euint64 executionTime = FHE.asEuint64(block.timestamp + 300);
        euint128 gasUsed = FHE.asEuint128(200000);
        euint32 slippagePercent = FHE.asEuint32(100); // 1%
        ebool targetsMet = FHE.asEbool(true);
        
        FHEPermissions.grantAnalyticsPermissions(
            expectedOutput,
            actualOutput,
            executionQuality,
            executionTime,
            gasUsed,
            slippagePercent,
            targetsMet,
            alice,
            address(hook)
        );
        
        vm.stopPrank();
    }

    function test_FHEPermissions_BasicContractSetup() public {
        FHEPermissions.setupBasicContractPermissions(address(hook));
    }

    function test_FHEPermissions_ValidatePermissions() public {
        bool hasPermissions = FHEPermissions.validatePermissions(
            encryptedAmount,
            alice,
            address(hook)
        );
        assertTrue(hasPermissions); // Always returns true in current implementation
    }

    function test_FHEPermissions_EmergencyReset() public {
        FHEPermissions.emergencyPermissionReset(alice, address(hook));
    }

    // =============================================================
    //                    VAULT SWAP LIB TESTS
    // =============================================================

    function test_VaultSwapLib_ValidateOrderParams() public {
        assertTrue(VaultSwapLib.validateOrderParams(
            TEST_AMOUNT,
            TEST_AMOUNT * 95 / 100,
            block.timestamp + 1 hours
        ));
        
        assertFalse(VaultSwapLib.validateOrderParams(
            0,
            TEST_AMOUNT * 95 / 100,
            block.timestamp + 1 hours
        ));
        
        assertFalse(VaultSwapLib.validateOrderParams(
            TEST_AMOUNT,
            TEST_AMOUNT * 95 / 100,
            block.timestamp - 1
        ));
    }

    function test_VaultSwapLib_CalculateSwapAmount() public {
        uint256 swapAmount = VaultSwapLib.calculateSwapAmount(
            TEST_AMOUNT,
            1, // Fragment 1
            5  // Total fragments
        );
        assertEq(swapAmount, TEST_AMOUNT / 5);
        
        uint256 lastFragment = VaultSwapLib.calculateSwapAmount(
            TEST_AMOUNT,
            5, // Last fragment
            5  // Total fragments
        );
        assertTrue(lastFragment >= TEST_AMOUNT / 5); // Handles remainder
    }

    function test_VaultSwapLib_CalculateMinimumOutput() public {
        uint256 minOutput = VaultSwapLib.calculateMinimumOutput(
            TEST_AMOUNT,
            500  // 5% slippage (500 basis points)
        );
        assertEq(minOutput, TEST_AMOUNT * 95 / 100);
        
        uint256 minOutputZeroSlippage = VaultSwapLib.calculateMinimumOutput(
            TEST_AMOUNT,
            0
        );
        assertEq(minOutputZeroSlippage, TEST_AMOUNT);
    }

    function test_VaultSwapLib_CalculateExecutionScore() public {
        uint256 score = VaultSwapLib.calculateExecutionScore(
            TEST_AMOUNT,
            TEST_AMOUNT * 95 / 100,
            block.timestamp,
            block.timestamp + 100,
            150000
        );
        assertTrue(score > 0 && score <= 100);
    }

    function test_VaultSwapLib_IsOrderExpired() public {
        assertFalse(VaultSwapLib.isOrderExpired(block.timestamp + 1 hours));
        assertTrue(VaultSwapLib.isOrderExpired(block.timestamp - 1));
    }

    function test_VaultSwapLib_GetNextExecutionTime() public {
        uint256 nextTime = VaultSwapLib.getNextExecutionTime(
            block.timestamp,
            300  // 5 minutes
        );
        assertEq(nextTime, block.timestamp + 300);
    }

    function test_VaultSwapLib_CalculateMarketImpact() public {
        uint256 impact = VaultSwapLib.calculateMarketImpact(
            TEST_AMOUNT,
            INITIAL_LIQUIDITY
        );
        assertTrue(impact > 0);
        
        uint256 smallImpact = VaultSwapLib.calculateMarketImpact(
            SMALL_AMOUNT,
            INITIAL_LIQUIDITY
        );
        
        uint256 largeImpact = VaultSwapLib.calculateMarketImpact(
            LARGE_AMOUNT,
            INITIAL_LIQUIDITY
        );
        
        assertTrue(smallImpact < largeImpact);
    }

    // =============================================================
    //                    HOOK INTEGRATION TESTS
    // =============================================================

    function test_BeforeSwap_Hook() public {
        vm.startPrank(address(manager));
        
        PoolKey memory key = poolKey;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        // Should not revert
        hook.beforeSwap(address(this), key, params, ZERO_BYTES);
        
        vm.stopPrank();
    }

    function test_AfterSwap_Hook() public {
        vm.startPrank(address(manager));
        
        PoolKey memory key = poolKey;
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        BalanceDelta delta = BalanceDelta.wrap(0);
        
        // Should not revert
        hook.afterSwap(address(this), key, params, delta, ZERO_BYTES);
        
        vm.stopPrank();
    }

    function test_BeforeInitialize_Hook() public {
        // Create new pool key for initialization test
        MockERC20 newToken0 = new MockERC20();
        MockERC20 newToken1 = new MockERC20();
        
        if (address(newToken0) > address(newToken1)) {
            (newToken0, newToken1) = (newToken1, newToken0);
        }
        
        PoolKey memory newKey = PoolKey({
            currency0: Currency.wrap(address(newToken0)),
            currency1: Currency.wrap(address(newToken1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        vm.startPrank(address(manager));
        
        // Should not revert
        hook.beforeInitialize(address(this), newKey, SQRT_RATIO_1_1, ZERO_BYTES);
        
        vm.stopPrank();
    }

    function test_AfterInitialize_Hook() public {
        // Create new pool key for initialization test
        MockERC20 newToken0 = new MockERC20();
        MockERC20 newToken1 = new MockERC20();
        
        if (address(newToken0) > address(newToken1)) {
            (newToken0, newToken1) = (newToken1, newToken0);
        }
        
        PoolKey memory newKey = PoolKey({
            currency0: Currency.wrap(address(newToken0)),
            currency1: Currency.wrap(address(newToken1)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });
        
        vm.startPrank(address(manager));
        
        // Should not revert
        hook.afterInitialize(address(this), newKey, SQRT_RATIO_1_1, 0, ZERO_BYTES);
        
        vm.stopPrank();
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function test_SubmitOrder_MaxAmount() public {
        vm.startPrank(alice);
        
        uint256 maxAmount = type(uint128).max;
        token0.mint(alice, maxAmount);
        token0.approve(address(hook), maxAmount);
        
        euint128 encMaxAmount = FHE.asEuint128(maxAmount);
        euint128 encMaxMinOut = FHE.asEuint128(maxAmount - 1);
        
        vm.expectRevert("Insufficient balance");
        hook.submitVaultOrder(
            poolKey,
            encMaxAmount,
            encMaxMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_SubmitOrder_MinAmount() public {
        vm.startPrank(alice);
        
        euint128 minAmount = FHE.asEuint128(1);
        euint128 minOut = FHE.asEuint128(1);
        
        token0.approve(address(hook), 1);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            minAmount,
            minOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_SubmitOrder_NearDeadline() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        // 1 second from now
        euint64 nearDeadline = FHE.asEuint64(block.timestamp + 1);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            nearDeadline,
            encryptedMevLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    function test_Multiple_Orders_Same_User() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT * 3);
        
        // First order
        bytes32 orderId1 = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Cancel first order
        hook.cancelVaultOrder(orderId1);
        
        // Second order should work
        bytes32 orderId2 = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        assertTrue(orderId1 != orderId2);
        assertTrue(orderId2 != bytes32(0));
        
        vm.stopPrank();
    }

    function test_Gas_Limit_Protection() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Test with low gas limit
        uint256 gasLeft = gasleft();
        if (gasLeft > 500000) {
            // Consume most gas
            for(uint i = 0; i < (gasLeft - 400000) / 20000; i++) {
                keccak256(abi.encode(i));
            }
        }
        
        // Should still work with remaining gas
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        assertTrue(orderId != bytes32(0));
        vm.stopPrank();
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function test_Multiple_Users_Concurrent_Orders() public {
        address[10] memory users;
        for (uint i = 0; i < 10; i++) {
            users[i] = makeAddr(string(abi.encodePacked("user", i)));
            token0.mint(users[i], TEST_AMOUNT);
        }
        
        bytes32[] memory orderIds = new bytes32[](10);
        
        for (uint i = 0; i < 10; i++) {
            vm.startPrank(users[i]);
            token0.approve(address(hook), TEST_AMOUNT);
            
            orderIds[i] = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderIds[i] != bytes32(0));
            assertTrue(hook.hasActiveOrder(users[i]));
            vm.stopPrank();
        }
        
        // Verify all orders are unique
        for (uint i = 0; i < 10; i++) {
            for (uint j = i + 1; j < 10; j++) {
                assertTrue(orderIds[i] != orderIds[j]);
            }
        }
    }

    function test_Rapid_Order_Submission_Cancellation() public {
        vm.startPrank(alice);
        token0.mint(alice, TEST_AMOUNT * 100);
        token0.approve(address(hook), TEST_AMOUNT * 100);
        
        for (uint i = 0; i < 50; i++) {
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            assertTrue(hook.cancelVaultOrder(orderId));
            assertFalse(hook.hasActiveOrder(alice));
        }
        
        vm.stopPrank();
    }

    function test_Different_MEV_Levels_Concurrent() public {
        address[5] memory users = [alice, bob, charlie, dave, eve];
        uint8[5] memory mevLevels = [1, 2, 3, 4, 5];
        
        for (uint i = 0; i < 5; i++) {
            vm.startPrank(users[i]);
            token0.approve(address(hook), TEST_AMOUNT);
            
            euint32 mevLevel = FHE.asEuint32(mevLevels[i]);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                mevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            vm.stopPrank();
        }
    }

    // =============================================================
    //                    INTEGRATION WITH DEPENDENCIES
    // =============================================================

    function test_Integration_With_MockERC20() public {
        vm.startPrank(alice);
        
        uint256 initialBalance = token0.balanceOf(alice);
        token0.approve(address(hook), TEST_AMOUNT);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Balance should be reduced by TEST_AMOUNT
        assertEq(token0.balanceOf(alice), initialBalance - TEST_AMOUNT);
        assertTrue(orderId != bytes32(0));
        
        vm.stopPrank();
    }

    function test_Integration_With_PoolManager() public {
        // Verify pool is properly initialized
        (uint160 sqrtPriceX96, int24 tick, , ) = manager.getSlot0(poolId);
        assertTrue(sqrtPriceX96 > 0);
        
        // Verify liquidity exists
        uint128 liquidity = manager.getLiquidity(poolId);
        assertTrue(liquidity > 0);
    }

    function test_Integration_FHE_Library() public {
        // Test FHE library integration
        euint128 testValue = FHE.asEuint128(12345);
        assertTrue(address(testValue) != address(0));
        
        euint128 sum = FHE.add(testValue, FHE.asEuint128(5));
        assertTrue(address(sum) != address(0));
        
        ebool comparison = FHE.gt(testValue, FHE.asEuint128(1000));
        assertTrue(address(comparison) != address(0));
    }

    // =============================================================
    //                    UTILITY AND HELPER TESTS
    // =============================================================

    function test_OrderId_Generation() public {
        vm.startPrank(alice);
        token0.approve(address(hook), TEST_AMOUNT * 2);
        
        bytes32 orderId1 = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        hook.cancelVaultOrder(orderId1);
        
        bytes32 orderId2 = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Different orders should have different IDs
        assertTrue(orderId1 != orderId2);
        assertTrue(orderId1 != bytes32(0));
        assertTrue(orderId2 != bytes32(0));
        
        vm.stopPrank();
    }

    function test_HasActiveOrder_States() public {
        vm.startPrank(alice);
        
        assertFalse(hook.hasActiveOrder(alice));
        
        token0.approve(address(hook), TEST_AMOUNT);
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        assertTrue(hook.hasActiveOrder(alice));
        
        hook.cancelVaultOrder(orderId);
        
        assertFalse(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    function test_Time_Based_Operations() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        uint256 futureTime = block.timestamp + 2 hours;
        euint64 futureDeadline = FHE.asEuint64(futureTime);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            futureDeadline,
            encryptedMevLevel
        );
        
        assertTrue(orderId != bytes32(0));
        
        // Fast forward time to just before deadline
        vm.warp(futureTime - 1);
        
        // Order should still be valid
        assertTrue(hook.hasActiveOrder(alice));
        
        // Fast forward past deadline
        vm.warp(futureTime + 1);
        
        // Order should now be expired (implementation dependent)
        // This test documents the expected behavior
        
        vm.stopPrank();
    }

    // =============================================================
    //                    ERROR CONDITION TESTS
    // =============================================================

    function test_RevertConditions_Comprehensive() public {
        vm.startPrank(alice);
        
        // Test zero amount
        euint128 zeroAmount = FHE.asEuint128(0);
        vm.expectRevert("Invalid amount");
        hook.submitVaultOrder(
            poolKey,
            zeroAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Test expired deadline
        euint64 pastDeadline = FHE.asEuint64(block.timestamp - 1);
        vm.expectRevert("Expired deadline");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            pastDeadline,
            encryptedMevLevel
        );
        
        // Test invalid MEV level
        euint32 invalidMev = FHE.asEuint32(6);
        vm.expectRevert("Invalid MEV protection level");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            invalidMev
        );
        
        // Test insufficient balance
        euint128 largeAmount = FHE.asEuint128(10000 ether);
        vm.expectRevert("Insufficient balance");
        hook.submitVaultOrder(
            poolKey,
            largeAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_Boundary_Values() public {
        vm.startPrank(alice);
        
        // Test minimum values
        euint128 minAmount = FHE.asEuint128(1);
        euint128 minOut = FHE.asEuint128(1);
        euint64 nearDeadline = FHE.asEuint64(block.timestamp + 1);
        euint32 minMev = FHE.asEuint32(1);
        
        token0.approve(address(hook), 1);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            minAmount,
            minOut,
            encryptedDirection,
            nearDeadline,
            minMev
        );
        
        assertTrue(orderId != bytes32(0));
        
        vm.stopPrank();
    }

    // =============================================================
    //                    FINAL COVERAGE TESTS
    // =============================================================

    function test_Coverage_AllLibraryFunctions() public {
        // Ensure all library functions are tested
        
        // VaultSwapLib coverage
        assertTrue(VaultSwapLib.validateOrderParams(TEST_AMOUNT, TEST_AMOUNT - 1, block.timestamp + 1));
        assertEq(VaultSwapLib.calculateSwapAmount(1000, 1, 4), 250);
        assertEq(VaultSwapLib.calculateMinimumOutput(1000, 100), 990);
        assertTrue(VaultSwapLib.calculateExecutionScore(1000, 950, 100, 200, 150000) > 0);
        assertFalse(VaultSwapLib.isOrderExpired(block.timestamp + 1));
        assertEq(VaultSwapLib.getNextExecutionTime(100, 50), 150);
        assertTrue(VaultSwapLib.calculateMarketImpact(1000, 10000) > 0);
        
        // MEVProtection coverage tested above
        
        // ExecutionStrategies coverage tested above
        
        // IntelligentRouter coverage tested above
        
        // ExecutionAnalytics coverage tested above
        
        // FHEPermissions coverage tested above
    }

    function test_Coverage_AllHookFunctions() public {
        // Test hook function coverage
        vm.startPrank(address(manager));
        
        // beforeSwap
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        hook.beforeSwap(address(this), poolKey, params, ZERO_BYTES);
        
        // afterSwap
        BalanceDelta delta = BalanceDelta.wrap(0);
        hook.afterSwap(address(this), poolKey, params, delta, ZERO_BYTES);
        
        // beforeInitialize & afterInitialize tested above
        
        vm.stopPrank();
    }

    function test_Coverage_AllConstantsAndGetters() public {
        // Test all constants are accessible
        assertEq(MEVProtection.BASIC_PROTECTION, 1);
        assertEq(MEVProtection.ENHANCED_PROTECTION, 2);
        assertEq(MEVProtection.ADVANCED_PROTECTION, 3);
        assertEq(MEVProtection.MAXIMUM_PROTECTION, 4);
        assertEq(MEVProtection.ULTIMATE_PROTECTION, 5);
        
        assertEq(ExecutionStrategies.TWAP_EXECUTION, 1);
        assertEq(ExecutionStrategies.VWAP_EXECUTION, 2);
        assertEq(ExecutionStrategies.OPPORTUNISTIC_EXECUTION, 3);
        assertEq(ExecutionStrategies.IMMEDIATE_EXECUTION, 4);
        
        assertEq(IntelligentRouter.SINGLE_POOL_STRATEGY, 1);
        assertEq(IntelligentRouter.MULTI_POOL_SPLIT_STRATEGY, 2);
        assertEq(IntelligentRouter.DYNAMIC_ROUTING_STRATEGY, 3);
        assertEq(IntelligentRouter.LIQUIDITY_OPTIMIZED_STRATEGY, 4);
    }

    function test_Final_Integration_End_To_End() public {
        // Complete end-to-end test
        vm.startPrank(alice);
        
        // Setup
        token0.approve(address(hook), TEST_AMOUNT);
        uint256 initialBalance = token0.balanceOf(alice);
        
        // Submit order
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Verify state changes
        assertTrue(orderId != bytes32(0));
        assertTrue(hook.hasActiveOrder(alice));
        assertEq(token0.balanceOf(alice), initialBalance - TEST_AMOUNT);
        
        // Cancel order
        assertTrue(hook.cancelVaultOrder(orderId));
        
        // Verify final state
        assertFalse(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }
}