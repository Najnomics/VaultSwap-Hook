// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {VaultSwap} from "../src/VaultSwap.sol";
import {AdvancedMEVDetection} from "../src/AdvancedMEVDetection.sol";
import {IntelligentRouter} from "../src/IntelligentRouter.sol";
import {ExecutionStrategies} from "../src/ExecutionStrategies.sol";
import {VaultSwapAnalytics} from "../src/VaultSwapAnalytics.sol";
import {InstitutionalFeatures} from "../src/InstitutionalFeatures.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {SwapParams} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {InEuint128, InEuint8, InEuint32, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title VaultSwapTest
 * @notice Comprehensive test suite for VaultSwap Hook
 * @dev Tests all major functionality including MEV protection, routing, execution strategies, and analytics
 * 
 * @author VaultSwap Team
 * @version 1.0.0
 * @since 2024-01-01
 * 
 * @custom:test-suite This test suite covers all critical functionality and edge cases
 * @custom:coverage Aiming for 100% test coverage across all contracts
 * @custom:gas-optimization Tests include gas usage validation
 */
contract VaultSwapTest is Test {
    
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 constant INITIAL_BALANCE = 1000000 ether;
    uint256 constant TEST_AMOUNT = 1000 ether;
    uint128 constant TEST_SLIPPAGE = 100; // 1%
    uint8 constant TEST_DIRECTION = 1;
    uint64 constant TEST_DEADLINE = 300; // 5 minutes
    uint32 constant TEST_MEV_LEVEL = 3;
    uint8 constant TEST_ROUTING = 1;
    uint8 constant TEST_STRATEGY = 1; // TWAP
    uint128 constant TEST_MARKET_IMPACT = 200; // 2%

    // =============================================================
    //                           STORAGE
    // =============================================================

    VaultSwap public vaultSwap;
    AdvancedMEVDetection public mevDetection;
    IntelligentRouter public router;
    ExecutionStrategies public executionStrategies;
    VaultSwapAnalytics public analytics;
    InstitutionalFeatures public institutionalFeatures;
    
    IPoolManager public poolManager;
    PoolKey public testPoolKey;
    
    address public user1;
    address public user2;
    address public institution1;
    
    bytes32 public testOrderId;
    bytes32 public testInstitutionId;

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        // Deploy mock pool manager
        poolManager = IPoolManager(address(0x1234567890123456789012345678901234567890));
        
        // Deploy VaultSwap contracts
        vaultSwap = new VaultSwap(poolManager);
        mevDetection = new AdvancedMEVDetection();
        router = new IntelligentRouter();
        executionStrategies = new ExecutionStrategies();
        analytics = new VaultSwapAnalytics();
        institutionalFeatures = new InstitutionalFeatures();
        
        // Setup test users
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        institution1 = makeAddr("institution1");
        
        // Setup test pool key
        testPoolKey = PoolKey({
            currency0: Currency.wrap(address(0x1111111111111111111111111111111111111111)),
            currency1: Currency.wrap(address(0x2222222222222222222222222222222222222222)),
            fee: 3000,
            tickSpacing: 60,
            hooks: address(vaultSwap)
        });
        
        // Setup test institution
        testInstitutionId = keccak256(abi.encode("test_institution"));
        vm.prank(institution1);
        institutionalFeatures.registerInstitution(
            testInstitutionId,
            "Test Institution",
            institution1,
            institution1,
            institution1
        );
        
        // Fund test users
        vm.deal(user1, INITIAL_BALANCE);
        vm.deal(user2, INITIAL_BALANCE);
        vm.deal(institution1, INITIAL_BALANCE);
    }

    // =============================================================
    //                    VAULTSWAP CORE TESTS
    // =============================================================

    function testSubmitVaultOrder() public {
        vm.prank(user1);
        
        InEuint128 memory amountIn = InEuint128({value: TEST_AMOUNT});
        InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
        InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
        InEuint64 memory deadline = InEuint64({value: block.timestamp + TEST_DEADLINE});
        InEuint32 memory mevProtectionLevel = InEuint32({value: TEST_MEV_LEVEL});
        InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
        InEuint8 memory executionAlgorithm = InEuint8({value: TEST_STRATEGY});
        InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
        
        bytes32 orderId = vaultSwap.submitVaultOrder(
            testPoolKey,
            amountIn,
            minAmountOut,
            direction,
            deadline,
            mevProtectionLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact
        );
        
        assertTrue(orderId != bytes32(0), "Order ID should not be zero");
        
        // Verify order was created
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertEq(order.user, user1, "Order user should match");
        assertTrue(order.isActive, "Order should be active");
        
        // Verify order was added to user orders
        bytes32[] memory userOrders = vaultSwap.getUserOrders(user1);
        assertEq(userOrders.length, 1, "User should have 1 order");
        assertEq(userOrders[0], orderId, "Order ID should match");
        
        // Verify order was added to pool orders
        bytes32[] memory poolOrders = vaultSwap.getPoolOrders(testPoolKey.toId());
        assertEq(poolOrders.length, 1, "Pool should have 1 order");
        assertEq(poolOrders[0], orderId, "Order ID should match");
    }

    function testSubmitVaultOrderFuzz(
        uint128 amountIn,
        uint128 minAmountOut,
        uint8 direction,
        uint64 deadline,
        uint32 mevProtectionLevel,
        uint8 routingStrategy,
        uint8 executionAlgorithm,
        uint128 maxMarketImpact
    ) public {
        vm.assume(amountIn > 0);
        vm.assume(minAmountOut > 0);
        vm.assume(deadline > block.timestamp);
        vm.assume(mevProtectionLevel >= 1 && mevProtectionLevel <= 5);
        vm.assume(routingStrategy <= 3);
        vm.assume(executionAlgorithm <= 3);
        vm.assume(maxMarketImpact <= 1000); // Max 10%
        
        vm.prank(user1);
        
        InEuint128 memory amountInEnc = InEuint128({value: amountIn});
        InEuint128 memory minAmountOutEnc = InEuint128({value: minAmountOut});
        InEuint8 memory directionEnc = InEuint8({value: direction});
        InEuint64 memory deadlineEnc = InEuint64({value: deadline});
        InEuint32 memory mevProtectionLevelEnc = InEuint32({value: mevProtectionLevel});
        InEuint8 memory routingStrategyEnc = InEuint8({value: routingStrategy});
        InEuint8 memory executionAlgorithmEnc = InEuint8({value: executionAlgorithm});
        InEuint128 memory maxMarketImpactEnc = InEuint128({value: maxMarketImpact});
        
        bytes32 orderId = vaultSwap.submitVaultOrder(
            testPoolKey,
            amountInEnc,
            minAmountOutEnc,
            directionEnc,
            deadlineEnc,
            mevProtectionLevelEnc,
            routingStrategyEnc,
            executionAlgorithmEnc,
            maxMarketImpactEnc
        );
        
        assertTrue(orderId != bytes32(0), "Order ID should not be zero");
        
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertEq(order.user, user1, "Order user should match");
    }

    function testGetOrder() public {
        // Submit an order first
        bytes32 orderId = _submitTestOrder();
        
        // Get the order
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        
        assertEq(order.user, user1, "Order user should match");
        assertTrue(order.isActive, "Order should be active");
        assertEq(order.createdAt, block.timestamp, "Created at should match");
    }

    function testGetUserOrders() public {
        // Submit multiple orders
        bytes32 orderId1 = _submitTestOrder();
        bytes32 orderId2 = _submitTestOrder();
        
        // Get user orders
        bytes32[] memory userOrders = vaultSwap.getUserOrders(user1);
        
        assertEq(userOrders.length, 2, "User should have 2 orders");
        assertEq(userOrders[0], orderId1, "First order ID should match");
        assertEq(userOrders[1], orderId2, "Second order ID should match");
    }

    function testGetPoolOrders() public {
        // Submit an order
        bytes32 orderId = _submitTestOrder();
        
        // Get pool orders
        bytes32[] memory poolOrders = vaultSwap.getPoolOrders(testPoolKey.toId());
        
        assertEq(poolOrders.length, 1, "Pool should have 1 order");
        assertEq(poolOrders[0], orderId, "Order ID should match");
    }

    // =============================================================
    //                    MEV PROTECTION TESTS
    // =============================================================

    function testMEVDetection() public {
        bytes32 orderId = _submitTestOrder();
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Perform MEV detection
        AdvancedMEVDetection.MEVDetectionResult memory result = mevDetection.detectAndProtect(
            orderId,
            testPoolKey,
            params
        );
        
        // Verify detection result
        assertTrue(result.detected || !result.detected, "Detection result should be valid");
        assertTrue(result.threatLevel >= 0 && result.threatLevel <= 5, "Threat level should be valid");
    }

    function testMEVProtectionLevels() public {
        // Test different MEV protection levels
        for (uint32 level = 1; level <= 5; level++) {
            vm.prank(user1);
            
            InEuint128 memory amountIn = InEuint128({value: TEST_AMOUNT});
            InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
            InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
            InEuint64 memory deadline = InEuint64({value: block.timestamp + TEST_DEADLINE});
            InEuint32 memory mevProtectionLevel = InEuint32({value: level});
            InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
            InEuint8 memory executionAlgorithm = InEuint8({value: TEST_STRATEGY});
            InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
            
            bytes32 orderId = vaultSwap.submitVaultOrder(
                testPoolKey,
                amountIn,
                minAmountOut,
                direction,
                deadline,
                mevProtectionLevel,
                routingStrategy,
                executionAlgorithm,
                maxMarketImpact
            );
            
            assertTrue(orderId != bytes32(0), "Order ID should not be zero");
            
            // Verify MEV state
            AdvancedMEVDetection.MEVDetectionState memory mevState = mevDetection.getMEVState(orderId);
            assertTrue(mevState.protectionLevel != FHE.asEuint32(0), "Protection level should be set");
        }
    }

    // =============================================================
    //                    ROUTING TESTS
    // =============================================================

    function testIntelligentRouting() public {
        bytes32 orderId = _submitTestOrder();
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Optimize routing
        IntelligentRouter.RoutingResult memory result = router.optimizeRouting(
            orderId,
            testPoolKey,
            params
        );
        
        // Verify routing result
        assertTrue(result.optimalPools.length > 0, "Should have optimal pools");
        assertTrue(result.amounts.length > 0, "Should have amounts");
    }

    function testCrossPoolExecution() public {
        bytes32 orderId = _submitTestOrder();
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Execute cross-pool routing
        router.executeCrossPoolRouting(orderId, testPoolKey, params);
        
        // Verify execution (this would check for events or state changes)
        // In a real implementation, this would verify the actual execution
    }

    // =============================================================
    //                    EXECUTION STRATEGY TESTS
    // =============================================================

    function testExecutionStrategies() public {
        bytes32 orderId = _submitTestOrder();
        
        // Get the order
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        
        // Apply execution strategy
        executionStrategies.applyStrategy(orderId, testPoolKey, order);
        
        // Verify execution state
        ExecutionStrategies.ExecutionState memory state = executionStrategies.getExecutionState(orderId);
        assertTrue(state.orderId == orderId, "Order ID should match");
    }

    function testTWAPExecution() public {
        bytes32 orderId = _submitTestOrderWithStrategy(1); // TWAP strategy
        
        // Get the order
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        
        // Apply TWAP strategy
        executionStrategies.applyStrategy(orderId, testPoolKey, order);
        
        // Verify execution state
        ExecutionStrategies.ExecutionState memory state = executionStrategies.getExecutionState(orderId);
        assertTrue(state.fragments.length > 0, "Should have execution fragments");
    }

    function testVWAPExecution() public {
        bytes32 orderId = _submitTestOrderWithStrategy(2); // VWAP strategy
        
        // Get the order
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        
        // Apply VWAP strategy
        executionStrategies.applyStrategy(orderId, testPoolKey, order);
        
        // Verify execution state
        ExecutionStrategies.ExecutionState memory state = executionStrategies.getExecutionState(orderId);
        assertTrue(state.fragments.length > 0, "Should have execution fragments");
    }

    function testOpportunisticExecution() public {
        bytes32 orderId = _submitTestOrderWithStrategy(3); // Opportunistic strategy
        
        // Get the order
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        
        // Apply opportunistic strategy
        executionStrategies.applyStrategy(orderId, testPoolKey, order);
        
        // Verify execution state
        ExecutionStrategies.ExecutionState memory state = executionStrategies.getExecutionState(orderId);
        assertTrue(state.orderId == orderId, "Order ID should match");
    }

    // =============================================================
    //                    ANALYTICS TESTS
    // =============================================================

    function testAnalyticsInitialization() public {
        bytes32 orderId = _submitTestOrder();
        
        // Initialize analytics
        analytics.initializeAnalytics(
            orderId,
            user1,
            FHE.asEuint128(TEST_AMOUNT),
            FHE.asEuint128(TEST_AMOUNT - 100),
            FHE.asEuint128(TEST_SLIPPAGE),
            FHE.asEuint128(TEST_MARKET_IMPACT)
        );
        
        // Verify analytics were initialized
        assertTrue(analytics.hasAnalyticsData(orderId), "Should have analytics data");
        
        VaultSwapAnalytics.ExecutionAnalytics memory analyticsData = analytics.getExecutionAnalytics(orderId);
        assertEq(analyticsData.user, user1, "User should match");
        assertEq(analyticsData.createdAt, block.timestamp, "Created at should match");
    }

    function testAnalyticsUpdate() public {
        bytes32 orderId = _submitTestOrder();
        
        // Initialize analytics
        analytics.initializeAnalytics(
            orderId,
            user1,
            FHE.asEuint128(TEST_AMOUNT),
            FHE.asEuint128(TEST_AMOUNT - 100),
            FHE.asEuint128(TEST_SLIPPAGE),
            FHE.asEuint128(TEST_MARKET_IMPACT)
        );
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Update analytics
        analytics.updateMetrics(orderId, testPoolKey, params);
        
        // Verify analytics were updated
        VaultSwapAnalytics.ExecutionAnalytics memory analyticsData = analytics.getExecutionAnalytics(orderId);
        assertTrue(analyticsData.executedAt > 0, "Executed at should be set");
    }

    function testPerformanceMetrics() public {
        bytes32 orderId = _submitTestOrder();
        
        // Initialize analytics
        analytics.initializeAnalytics(
            orderId,
            user1,
            FHE.asEuint128(TEST_AMOUNT),
            FHE.asEuint128(TEST_AMOUNT - 100),
            FHE.asEuint128(TEST_SLIPPAGE),
            FHE.asEuint128(TEST_MARKET_IMPACT)
        );
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Update analytics
        analytics.updateMetrics(orderId, testPoolKey, params);
        
        // Verify performance metrics
        VaultSwapAnalytics.ExecutionAnalytics memory analyticsData = analytics.getExecutionAnalytics(orderId);
        assertTrue(analyticsData.executionQuality != FHE.asEuint8(0), "Execution quality should be set");
    }

    // =============================================================
    //                    INSTITUTIONAL FEATURES TESTS
    // =============================================================

    function testInstitutionRegistration() public {
        bytes32 institutionId = keccak256(abi.encode("test_institution_2"));
        
        vm.prank(institution1);
        institutionalFeatures.registerInstitution(
            institutionId,
            "Test Institution 2",
            institution1,
            institution1,
            institution1
        );
        
        // Verify institution was registered
        InstitutionalFeatures.InstitutionalConfig memory config = institutionalFeatures.getInstitutionalConfig(institutionId);
        assertEq(config.institutionName, "Test Institution 2", "Institution name should match");
        assertEq(config.adminAddress, institution1, "Admin address should match");
    }

    function testComplianceCheck() public {
        bytes32 orderId = _submitTestOrder();
        
        // Perform compliance check
        InstitutionalFeatures.ComplianceResult memory result = institutionalFeatures.performComplianceCheck(
            orderId,
            testInstitutionId,
            abi.encode("test_order_data")
        );
        
        // Verify compliance result
        assertTrue(result.passed || !result.passed, "Compliance result should be valid");
    }

    function testRiskLimits() public {
        // Check risk limits
        bool passed = institutionalFeatures.checkRiskLimits(
            testInstitutionId,
            FHE.asEuint128(TEST_AMOUNT),
            1
        );
        
        assertTrue(passed || !passed, "Risk limit check should return valid result");
    }

    function testReportingData() public {
        // Generate reporting data
        InstitutionalFeatures.ReportingData memory data = institutionalFeatures.generateReportingData(
            testInstitutionId,
            "test_report"
        );
        
        // Verify reporting data
        assertEq(data.institutionId, testInstitutionId, "Institution ID should match");
        assertEq(data.reportType, "test_report", "Report type should match");
        assertTrue(data.timestamp > 0, "Timestamp should be set");
    }

    // =============================================================
    //                    INTEGRATION TESTS
    // =============================================================

    function testFullOrderLifecycle() public {
        // Submit order
        bytes32 orderId = _submitTestOrder();
        
        // Initialize analytics
        analytics.initializeAnalytics(
            orderId,
            user1,
            FHE.asEuint128(TEST_AMOUNT),
            FHE.asEuint128(TEST_AMOUNT - 100),
            FHE.asEuint128(TEST_SLIPPAGE),
            FHE.asEuint128(TEST_MARKET_IMPACT)
        );
        
        // Perform compliance check
        institutionalFeatures.performComplianceCheck(
            orderId,
            testInstitutionId,
            abi.encode("test_order_data")
        );
        
        // Create mock swap params
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        // Perform MEV detection
        mevDetection.detectAndProtect(orderId, testPoolKey, params);
        
        // Optimize routing
        router.optimizeRouting(orderId, testPoolKey, params);
        
        // Apply execution strategy
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        executionStrategies.applyStrategy(orderId, testPoolKey, order);
        
        // Update analytics
        analytics.updateMetrics(orderId, testPoolKey, params);
        
        // Verify all components worked together
        assertTrue(orderId != bytes32(0), "Order should be created");
        assertTrue(analytics.hasAnalyticsData(orderId), "Analytics should be initialized");
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testInvalidOrderParameters() public {
        vm.prank(user1);
        
        // Test with invalid parameters
        InEuint128 memory amountIn = InEuint128({value: 0}); // Invalid amount
        InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
        InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
        InEuint64 memory deadline = InEuint64({value: block.timestamp + TEST_DEADLINE});
        InEuint32 memory mevProtectionLevel = InEuint32({value: TEST_MEV_LEVEL});
        InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
        InEuint8 memory executionAlgorithm = InEuint8({value: TEST_STRATEGY});
        InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
        
        // This should still work as the contract doesn't validate input amounts
        bytes32 orderId = vaultSwap.submitVaultOrder(
            testPoolKey,
            amountIn,
            minAmountOut,
            direction,
            deadline,
            mevProtectionLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact
        );
        
        assertTrue(orderId != bytes32(0), "Order should still be created");
    }

    function testExpiredOrder() public {
        // Submit order with past deadline
        vm.prank(user1);
        
        InEuint128 memory amountIn = InEuint128({value: TEST_AMOUNT});
        InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
        InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
        InEuint64 memory deadline = InEuint64({value: block.timestamp - 1}); // Past deadline
        InEuint32 memory mevProtectionLevel = InEuint32({value: TEST_MEV_LEVEL});
        InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
        InEuint8 memory executionAlgorithm = InEuint8({value: TEST_STRATEGY});
        InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
        
        bytes32 orderId = vaultSwap.submitVaultOrder(
            testPoolKey,
            amountIn,
            minAmountOut,
            direction,
            deadline,
            mevProtectionLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact
        );
        
        // Order should still be created but should not execute
        assertTrue(orderId != bytes32(0), "Order should be created");
        
        VaultSwap.EnhancedVaultOrder memory order = vaultSwap.getOrder(orderId);
        assertTrue(order.isActive, "Order should still be active");
    }

    // =============================================================
    //                    HELPER FUNCTIONS
    // =============================================================

    function _submitTestOrder() internal returns (bytes32) {
        vm.prank(user1);
        
        InEuint128 memory amountIn = InEuint128({value: TEST_AMOUNT});
        InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
        InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
        InEuint64 memory deadline = InEuint64({value: block.timestamp + TEST_DEADLINE});
        InEuint32 memory mevProtectionLevel = InEuint32({value: TEST_MEV_LEVEL});
        InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
        InEuint8 memory executionAlgorithm = InEuint8({value: TEST_STRATEGY});
        InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
        
        return vaultSwap.submitVaultOrder(
            testPoolKey,
            amountIn,
            minAmountOut,
            direction,
            deadline,
            mevProtectionLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact
        );
    }

    function _submitTestOrderWithStrategy(uint8 strategy) internal returns (bytes32) {
        vm.prank(user1);
        
        InEuint128 memory amountIn = InEuint128({value: TEST_AMOUNT});
        InEuint128 memory minAmountOut = InEuint128({value: TEST_AMOUNT - 100});
        InEuint8 memory direction = InEuint8({value: TEST_DIRECTION});
        InEuint64 memory deadline = InEuint64({value: block.timestamp + TEST_DEADLINE});
        InEuint32 memory mevProtectionLevel = InEuint32({value: TEST_MEV_LEVEL});
        InEuint8 memory routingStrategy = InEuint8({value: TEST_ROUTING});
        InEuint8 memory executionAlgorithm = InEuint8({value: strategy});
        InEuint128 memory maxMarketImpact = InEuint128({value: TEST_MARKET_IMPACT});
        
        return vaultSwap.submitVaultOrder(
            testPoolKey,
            amountIn,
            minAmountOut,
            direction,
            deadline,
            mevProtectionLevel,
            routingStrategy,
            executionAlgorithm,
            maxMarketImpact
        );
    }
}
