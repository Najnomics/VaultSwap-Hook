// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VaultSwap} from "../src/VaultSwap.sol";
import {VaultSwapHook} from "../src/VaultSwapHook.sol";
import {VaultSwapSDK} from "../src/VaultSwapSDK.sol";
import {AdvancedMEVDetection} from "../src/AdvancedMEVDetection.sol";
import {IntelligentRouter} from "../src/IntelligentRouter.sol";
import {ExecutionStrategies} from "../src/ExecutionStrategies.sol";
import {VaultSwapAnalytics} from "../src/VaultSwapAnalytics.sol";
import {InstitutionalFeatures} from "../src/InstitutionalFeatures.sol";
import {Queue} from "../src/Queue.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {euint128, ebool, euint8, euint32, euint64, FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {InEuint128, InEuint8, InEuint32, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title VaultSwapIntegrationTest
 * @notice Comprehensive integration tests for VaultSwap Hook system
 * @dev Tests the complete integration following context contract patterns
 * 
 * @author VaultSwap Team
 * @version 1.0.0
 * @since 2024-01-01
 * 
 * @custom:integration Tests complete system integration
 * @custom:coverage Comprehensive test coverage
 */
contract VaultSwapIntegrationTest is Test {
    
    // =============================================================
    //                           CONTRACTS
    // =============================================================

    VaultSwap public vaultSwap;
    VaultSwapHook public vaultSwapHook;
    VaultSwapSDK public vaultSwapSDK;
    AdvancedMEVDetection public mevDetection;
    IntelligentRouter public router;
    ExecutionStrategies public executionStrategies;
    VaultSwapAnalytics public analytics;
    InstitutionalFeatures public institutionalFeatures;
    Queue public queue;

    // =============================================================
    //                           MOCKS
    // =============================================================

    IPoolManager public poolManager;
    PoolKey public poolKey;
    Currency public currency0;
    Currency public currency1;

    // =============================================================
    //                           USERS
    // =============================================================

    address public user1;
    address public user2;
    address public institutionalUser;
    address public admin;

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        // Setup users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        institutionalUser = makeAddr("institutionalUser");
        admin = makeAddr("admin");

        // Setup mock pool manager
        poolManager = IPoolManager(makeAddr("poolManager"));

        // Setup currencies
        currency0 = Currency.wrap(makeAddr("token0"));
        currency1 = Currency.wrap(makeAddr("token1"));

        // Setup pool key
        poolKey = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000,
            tickSpacing: 60,
            hooks: Hooks.CALL_BEFORE_SWAP_FLAG | Hooks.CALL_AFTER_SWAP_FLAG
        });

        // Deploy contracts
        vaultSwap = new VaultSwap(poolManager);
        vaultSwapHook = new VaultSwapHook(poolManager, vaultSwap);
        mevDetection = new AdvancedMEVDetection();
        router = new IntelligentRouter();
        executionStrategies = new ExecutionStrategies();
        analytics = new VaultSwapAnalytics();
        institutionalFeatures = new InstitutionalFeatures();
        queue = new Queue();

        // Deploy SDK
        vaultSwapSDK = new VaultSwapSDK(vaultSwap, vaultSwapHook);

        // Setup initial state
        vm.startPrank(admin);
        vaultSwap.setMEVDetection(address(mevDetection));
        vaultSwap.setRouter(address(router));
        vaultSwap.setExecutionStrategies(address(executionStrategies));
        vaultSwap.setAnalytics(address(analytics));
        vaultSwap.setInstitutionalFeatures(address(institutionalFeatures));
        vm.stopPrank();
    }

    // =============================================================
    //                    BASIC INTEGRATION TESTS
    // =============================================================

    function testCompleteSystemIntegration() public {
        console.log("Testing complete system integration...");

        // Test 1: Enable hook for pool
        _testEnableHook();

        // Test 2: Submit simple order
        _testSubmitSimpleOrder();

        // Test 3: Submit advanced order
        _testSubmitAdvancedOrder();

        // Test 4: Process orders
        _testProcessOrders();

        // Test 5: MEV protection
        _testMEVProtection();

        // Test 6: Analytics
        _testAnalytics();

        // Test 7: Institutional features
        _testInstitutionalFeatures();

        console.log("Complete system integration test passed!");
    }

    function _testEnableHook() internal {
        console.log("Testing hook enablement...");

        vm.startPrank(admin);
        
        VaultSwapHook.HookConfig memory config = VaultSwapHook.HookConfig({
            enabled: true,
            mevProtectionLevel: 2,
            routingStrategy: 0,
            executionStrategy: 0,
            maxOrderSize: 1000000,
            minOrderSize: 1000,
            maxOrdersPerBlock: 100,
            allowHighFrequency: true,
            allowCrossPool: true,
            allowMEVProtection: true,
            allowAdvancedStrategies: true
        });

        vaultSwapHook.enableHook(poolKey, config);
        
        assertTrue(vaultSwapHook.isHookEnabled(poolKey));
        
        vm.stopPrank();
        
        console.log("Hook enablement test passed!");
    }

    function _testSubmitSimpleOrder() internal {
        console.log("Testing simple order submission...");

        vm.startPrank(user1);

        bytes32 orderId = vaultSwapSDK.submitSimpleOrder(
            poolKey,
            100000, // 100k amount in
            95000,  // 95k min amount out (5% slippage)
            1,      // token1 -> token0
            86400   // 24 hour deadline
        );

        assertTrue(orderId != bytes32(0));
        
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertEq(order.user, user1);
        assertEq(uint8(order.status), uint8(VaultSwap.OrderStatus.Pending));
        
        vm.stopPrank();
        
        console.log("Simple order submission test passed!");
    }

    function _testSubmitAdvancedOrder() internal {
        console.log("Testing advanced order submission...");

        vm.startPrank(user2);

        bytes32 orderId = vaultSwapSDK.submitAdvancedOrder(
            poolKey,
            500000, // 500k amount in
            475000, // 475k min amount out (5% slippage)
            0,      // token0 -> token1
            3600,   // 1 hour deadline
            3,      // Level 3 MEV protection
            1,      // Lowest impact routing
            1,      // TWAP execution
            300     // 3% max market impact
        );

        assertTrue(orderId != bytes32(0));
        
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertEq(order.user, user2);
        assertEq(uint8(order.status), uint8(VaultSwap.OrderStatus.Pending));
        
        vm.stopPrank();
        
        console.log("Advanced order submission test passed!");
    }

    function _testProcessOrders() internal {
        console.log("Testing order processing...");

        // Submit multiple orders
        vm.startPrank(user1);
        bytes32 orderId1 = vaultSwapSDK.submitSimpleOrder(poolKey, 50000, 47500, 1, 86400);
        vm.stopPrank();

        vm.startPrank(user2);
        bytes32 orderId2 = vaultSwapSDK.submitSimpleOrder(poolKey, 75000, 71250, 1, 86400);
        vm.stopPrank();

        // Process orders (simulate hook call)
        vm.prank(address(poolManager));
        (bytes4 selector, IPoolManager.BeforeSwapDelta delta, uint24 fee) = vaultSwap.beforeSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: 100000,
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE
            }),
            ""
        );

        assertEq(selector, VaultSwapHook.beforeSwap.selector);
        assertEq(fee, 0);

        console.log("Order processing test passed!");
    }

    function _testMEVProtection() internal {
        console.log("Testing MEV protection...");

        vm.startPrank(user1);

        // Submit order with high MEV protection
        bytes32 orderId = vaultSwapSDK.submitAdvancedOrder(
            poolKey,
            1000000, // 1M amount in
            950000,  // 950k min amount out
            1,       // token1 -> token0
            3600,    // 1 hour deadline
            5,       // Level 5 MEV protection
            0,       // Best price routing
            0,       // Immediate execution
            200      // 2% max market impact
        );

        // Check MEV protection was applied
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertTrue(FHE.decrypt(order.mevProtectionLevel) >= 5);
        
        vm.stopPrank();
        
        console.log("MEV protection test passed!");
    }

    function _testAnalytics() internal {
        console.log("Testing analytics...");

        vm.startPrank(user1);

        // Submit order
        bytes32 orderId = vaultSwapSDK.submitSimpleOrder(poolKey, 100000, 95000, 1, 86400);

        // Check analytics
        VaultSwapAnalytics.PoolAnalytics memory poolAnalytics = vaultSwapSDK.getPoolAnalytics(poolKey);
        assertTrue(poolAnalytics.totalOrders >= 1);

        VaultSwapAnalytics.UserAnalytics memory userAnalytics = vaultSwapSDK.getUserAnalytics(user1);
        assertTrue(userAnalytics.totalOrders >= 1);
        
        vm.stopPrank();
        
        console.log("Analytics test passed!");
    }

    function _testInstitutionalFeatures() internal {
        console.log("Testing institutional features...");

        vm.startPrank(institutionalUser);

        // Submit large order
        bytes32 orderId = vaultSwapSDK.submitAdvancedOrder(
            poolKey,
            10000000, // 10M amount in
            9500000,  // 9.5M min amount out
            1,        // token1 -> token0
            86400,    // 24 hour deadline
            4,        // Level 4 MEV protection
            1,        // Lowest impact routing
            2,        // VWAP execution
            100       // 1% max market impact
        );

        // Check institutional features were applied
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertTrue(FHE.decrypt(order.mevProtectionLevel) >= 4);
        assertTrue(FHE.decrypt(order.executionAlgorithm) == 2); // VWAP
        
        vm.stopPrank();
        
        console.log("Institutional features test passed!");
    }

    // =============================================================
    //                    FHE INTEGRATION TESTS
    // =============================================================

    function testFHEIntegration() public {
        console.log("Testing FHE integration...");

        // Test encrypted value creation
        euint128 encryptedValue = FHE.asEuint128(100000);
        FHE.allowThis(encryptedValue);

        // Test encrypted operations
        euint128 result = FHE.add(encryptedValue, FHE.asEuint128(50000));
        FHE.allowThis(result);

        // Test encrypted comparisons
        ebool isGreater = FHE.gt(encryptedValue, FHE.asEuint128(50000));
        FHE.allowThis(isGreater);

        console.log("FHE integration test passed!");
    }

    function testQueueIntegration() public {
        console.log("Testing queue integration...");

        // Test queue operations
        euint128 value1 = FHE.asEuint128(100000);
        euint128 value2 = FHE.asEuint128(200000);
        euint128 value3 = FHE.asEuint128(300000);

        FHE.allowThis(value1);
        FHE.allowThis(value2);
        FHE.allowThis(value3);

        queue.push(value1);
        queue.push(value2);
        queue.push(value3);

        assertEq(queue.size(), 3);
        assertFalse(queue.isEmpty());

        euint128 popped = queue.pop();
        assertEq(queue.size(), 2);

        euint128 peeked = queue.peek();
        // Note: Can't directly compare encrypted values, but we can check queue state
        assertEq(queue.size(), 2);

        console.log("Queue integration test passed!");
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testEdgeCases() public {
        console.log("Testing edge cases...");

        // Test with zero amounts
        vm.startPrank(user1);
        vm.expectRevert();
        vaultSwapSDK.submitSimpleOrder(poolKey, 0, 0, 1, 86400);
        vm.stopPrank();

        // Test with expired deadline
        vm.startPrank(user1);
        vm.expectRevert();
        vaultSwapSDK.submitSimpleOrder(poolKey, 100000, 95000, 1, 0);
        vm.stopPrank();

        // Test with invalid MEV protection level
        vm.startPrank(user1);
        vm.expectRevert();
        vaultSwapSDK.submitAdvancedOrder(poolKey, 100000, 95000, 1, 86400, 6, 0, 0, 500);
        vm.stopPrank();

        console.log("Edge cases test passed!");
    }

    // =============================================================
    //                    GAS OPTIMIZATION TESTS
    // =============================================================

    function testGasOptimization() public {
        console.log("Testing gas optimization...");

        uint256 gasStart = gasleft();

        vm.startPrank(user1);
        vaultSwapSDK.submitSimpleOrder(poolKey, 100000, 95000, 1, 86400);
        vm.stopPrank();

        uint256 gasUsed = gasStart - gasleft();
        console.log("Gas used for simple order:", gasUsed);

        // Gas should be reasonable (adjust threshold as needed)
        assertTrue(gasUsed < 1000000);

        console.log("Gas optimization test passed!");
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function testStressTest() public {
        console.log("Testing stress scenarios...");

        // Submit many orders
        for (uint256 i = 0; i < 10; i++) {
            vm.startPrank(makeAddr(string(abi.encodePacked("user", i))));
            vaultSwapSDK.submitSimpleOrder(
                poolKey,
                uint128(10000 + i * 1000),
                uint128(9500 + i * 950),
                1,
                86400
            );
            vm.stopPrank();
        }

        // Process all orders
        vm.prank(address(poolManager));
        vaultSwap.beforeSwap(
            poolKey,
            SwapParams({
                zeroForOne: true,
                amountSpecified: 1000000,
                sqrtPriceLimitX96: TickMath.MAX_SQRT_PRICE
            }),
            ""
        );

        console.log("Stress test passed!");
    }

    // =============================================================
    //                    UTILITY FUNCTIONS
    // =============================================================

    function testUtilityFunctions() public {
        console.log("Testing utility functions...");

        // Test MEV protection level recommendation
        uint8 level = vaultSwapSDK.getOptimalMEVProtectionLevel(100000, 1000000);
        assertTrue(level >= 1 && level <= 5);

        // Test routing strategy recommendation
        uint8 strategy = vaultSwapSDK.getRecommendedRoutingStrategy(100000, 1);
        assertTrue(strategy >= 0 && strategy <= 3);

        // Test execution algorithm recommendation
        uint8 algorithm = vaultSwapSDK.getRecommendedExecutionAlgorithm(100000, 300);
        assertTrue(algorithm >= 0 && algorithm <= 3);

        console.log("Utility functions test passed!");
    }
}
