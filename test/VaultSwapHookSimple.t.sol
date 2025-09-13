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

// Test Utilities
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";

// FHE Imports
import {FHE, euint128, euint64, euint32, euint8, ebool, InEuint128, InEuint64, InEuint32, InEuint8, InEbool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";

// Project Imports
import {VaultSwapHook} from "../src/VaultSwapHook.sol";
import {MEVProtection} from "../src/lib/MEVProtection.sol";
import {ExecutionStrategies} from "../src/lib/ExecutionStrategies.sol";

// Mock FHE Token for Testing
contract MockFHEToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
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
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract VaultSwapHookSimpleTest is Test, Deployers, CoFheTest {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    VaultSwapHook hook;
    PoolKey poolKey;
    PoolId poolId;
    MockFHEToken token0;
    MockFHEToken token1;
    
    // Test users
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    
    // Test amounts
    uint256 constant INITIAL_LIQUIDITY = 100 ether;
    uint256 constant TEST_AMOUNT = 1 ether;

    function setUp() public {
        // Deploy core Uniswap V4 contracts
        deployFreshManagerAndRouters();
        
        // Deploy FHE test tokens
        token0 = new MockFHEToken("Test Token 0", "TT0");
        token1 = new MockFHEToken("Test Token 1", "TT1");
        
        // Ensure token0 < token1 for Uniswap V4
        if (address(token0) > address(token1)) {
            (token0, token1) = (token1, token0);
        }
        
        // Mint tokens to test accounts
        token0.mint(alice, 1000 ether);
        token1.mint(alice, 1000 ether);
        token0.mint(bob, 1000 ether);
        token1.mint(bob, 1000 ether);
        
        // Deploy hook with proper flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG
        );
        
        deployCodeTo("VaultSwapHook.sol", abi.encode(manager), address(flags));
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
    }

    // =============================================================
    //                    CORE FHE FUNCTIONALITY TESTS
    // =============================================================

    function test_SubmitVaultOrder_WithFHE() public {
        vm.startPrank(alice);
        
        // Approve tokens
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Create FHE encrypted values using CoFHE test patterns
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice); // Token0 to Token1
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice); // Enhanced protection
        
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

    function test_SubmitVaultOrder_InvalidAmount_FHE() public {
        vm.startPrank(alice);
        
        // Create encrypted zero amount
        InEuint128 memory zeroAmount = createInEuint128(0, alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
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

    function test_SubmitVaultOrder_ExpiredDeadline_FHE() public {
        vm.startPrank(alice);
        
        // Create encrypted values with past deadline
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory pastDeadline = createInEuint64(uint64(block.timestamp - 1), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
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

    function test_CancelVaultOrder_FHE() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Create and submit order
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Cancel order
        assertTrue(hook.cancelVaultOrder(orderId));
        assertFalse(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    // =============================================================
    //                    MEV PROTECTION TESTS
    // =============================================================

    function test_MEVProtection_Levels_FHE() public {
        vm.startPrank(alice);
        token0.approve(address(hook), TEST_AMOUNT * 5);
        
        // Test all MEV protection levels
        for (uint32 level = 1; level <= 5; level++) {
            InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
            InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
            InEuint8 memory encryptedDirection = createInEuint8(0, alice);
            InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
            InEuint32 memory encryptedMevLevel = createInEuint32(level, alice);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            
            // Cancel order for next iteration
            hook.cancelVaultOrder(orderId);
        }
        
        vm.stopPrank();
    }

    function test_MEVProtection_InvalidLevel_FHE() public {
        vm.startPrank(alice);
        
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory invalidMevLevel = createInEuint32(6, alice); // Beyond ultimate
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        vm.expectRevert("Invalid MEV protection level");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            invalidMevLevel
        );
        
        vm.stopPrank();
    }

    // =============================================================
    //                    MULTIPLE USERS TESTS
    // =============================================================

    function test_MultipleUsers_FHE() public {
        address[2] memory users = [alice, bob];
        
        for (uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            token0.approve(address(hook), TEST_AMOUNT);
            
            // Each user creates their own encrypted values
            InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), users[i]);
            InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), users[i]);
            InEuint8 memory encryptedDirection = createInEuint8(0, users[i]);
            InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), users[i]);
            InEuint32 memory encryptedMevLevel = createInEuint32(2, users[i]);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            assertTrue(hook.hasActiveOrder(users[i]));
            vm.stopPrank();
        }
    }

    // =============================================================
    //                    LIBRARY FUNCTION TESTS
    // =============================================================

    function test_MEVProtection_Constants() public {
        assertEq(MEVProtection.BASIC_PROTECTION, 1);
        assertEq(MEVProtection.ENHANCED_PROTECTION, 2);
        assertEq(MEVProtection.ADVANCED_PROTECTION, 3);
        assertEq(MEVProtection.MAXIMUM_PROTECTION, 4);
        assertEq(MEVProtection.ULTIMATE_PROTECTION, 5);
    }

    function test_MEVProtection_UtilityFunctions() public {
        assertTrue(MEVProtection.isValidProtectionLevel(1));
        assertTrue(MEVProtection.isValidProtectionLevel(5));
        assertFalse(MEVProtection.isValidProtectionLevel(0));
        assertFalse(MEVProtection.isValidProtectionLevel(6));
        
        assertEq(MEVProtection.getProtectionLevelName(1), "Basic");
        assertEq(MEVProtection.getProtectionLevelName(5), "Ultimate");
        assertEq(MEVProtection.getProtectionLevelName(0), "Unknown");
    }

    function test_ExecutionStrategies_Constants() public {
        assertEq(ExecutionStrategies.TWAP_EXECUTION, 1);
        assertEq(ExecutionStrategies.VWAP_EXECUTION, 2);
        assertEq(ExecutionStrategies.OPPORTUNISTIC_EXECUTION, 3);
        assertEq(ExecutionStrategies.IMMEDIATE_EXECUTION, 4);
    }

    function test_ExecutionStrategies_UtilityFunctions() public {
        assertTrue(ExecutionStrategies.isValidStrategy(1));
        assertTrue(ExecutionStrategies.isValidStrategy(4));
        assertFalse(ExecutionStrategies.isValidStrategy(0));
        assertFalse(ExecutionStrategies.isValidStrategy(5));
        
        assertEq(ExecutionStrategies.getStrategyName(1), "TWAP");
        assertEq(ExecutionStrategies.getStrategyName(4), "Immediate");
        assertEq(ExecutionStrategies.getStrategyName(0), "Unknown");
    }

    // =============================================================
    //                    HOOK INTEGRATION TESTS
    // =============================================================

    function test_BeforeSwap_Hook() public {
        vm.startPrank(address(manager));
        
        PoolKey memory key = poolKey;
        SwapParams memory params = SwapParams({
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
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        BalanceDelta delta = BalanceDelta.wrap(0);
        
        // Should not revert
        hook.afterSwap(address(this), key, params, delta, ZERO_BYTES);
        
        vm.stopPrank();
    }
}