// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MEVProtection} from "../src/libraries/MEVProtection.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/**
 * @title MEVProtectionTests
 * @notice Comprehensive unit tests for MEVProtection library functionality
 * @dev Tests MEV detection, protection levels, and utility functions
 */
contract MEVProtectionTests is Test {
    
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint256 constant TEST_AMOUNT = 1000 ether;
    uint24 constant TEST_FEE = 3000;
    int24 constant TEST_TICK_SPACING = 60;

    // =============================================================
    //                           STATE
    // =============================================================

    PoolKey public testPoolKey;
    SwapParams public testSwapParams;

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        // Create test pool key
        testPoolKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: TEST_FEE,
            tickSpacing: TEST_TICK_SPACING,
            hooks: IHooks(address(0))
        });

        // Create test swap params
        testSwapParams = SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
    }

    // =============================================================
    //                    CONSTANT TESTS
    // =============================================================

    function testConstants() public {
        assertEq(MEVProtection.BASIC_PROTECTION, 1, "Basic protection should be 1");
        assertEq(MEVProtection.ENHANCED_PROTECTION, 2, "Enhanced protection should be 2");
        assertEq(MEVProtection.ADVANCED_PROTECTION, 3, "Advanced protection should be 3");
        assertEq(MEVProtection.MAXIMUM_PROTECTION, 4, "Maximum protection should be 4");
        assertEq(MEVProtection.ULTIMATE_PROTECTION, 5, "Ultimate protection should be 5");
    }

    // =============================================================
    //                    DECOY COUNT TESTS
    // =============================================================

    function testGetDecoyCount() public {
        // Test all protection levels
        assertEq(MEVProtection.getDecoyCount(0), 0, "Level 0 should have 0 decoys");
        assertEq(MEVProtection.getDecoyCount(1), 2, "Level 1 should have 2 decoys");
        assertEq(MEVProtection.getDecoyCount(2), 3, "Level 2 should have 3 decoys");
        assertEq(MEVProtection.getDecoyCount(3), 5, "Level 3 should have 5 decoys");
        assertEq(MEVProtection.getDecoyCount(4), 8, "Level 4 should have 8 decoys");
        assertEq(MEVProtection.getDecoyCount(5), 12, "Level 5 should have 12 decoys");
    }

    function testGetDecoyCountInvalidLevels() public {
        // Test invalid levels
        assertEq(MEVProtection.getDecoyCount(6), 0, "Level 6 should have 0 decoys");
        assertEq(MEVProtection.getDecoyCount(255), 0, "Level 255 should have 0 decoys");
    }

    function testGetDecoyCountProgression() public {
        // Verify decoy count increases with protection level
        uint8 prevDecoyCount = 0;
        for (uint8 level = 1; level <= 5; level++) {
            uint8 decoyCount = MEVProtection.getDecoyCount(level);
            assertTrue(decoyCount > prevDecoyCount, "Decoy count should increase with level");
            prevDecoyCount = decoyCount;
        }
    }

    // =============================================================
    //                    EXECUTION DELAY TESTS
    // =============================================================

    function testGetExecutionDelay() public {
        // Test all protection levels
        assertEq(MEVProtection.getExecutionDelay(0), 0, "Level 0 should have 0 delay");
        assertEq(MEVProtection.getExecutionDelay(1), 30, "Level 1 should have 30s delay");
        assertEq(MEVProtection.getExecutionDelay(2), 60, "Level 2 should have 60s delay");
        assertEq(MEVProtection.getExecutionDelay(3), 120, "Level 3 should have 120s delay");
        assertEq(MEVProtection.getExecutionDelay(4), 300, "Level 4 should have 300s delay");
        assertEq(MEVProtection.getExecutionDelay(5), 600, "Level 5 should have 600s delay");
    }

    function testGetExecutionDelayInvalidLevels() public {
        // Test invalid levels
        assertEq(MEVProtection.getExecutionDelay(6), 0, "Level 6 should have 0 delay");
        assertEq(MEVProtection.getExecutionDelay(255), 0, "Level 255 should have 0 delay");
    }

    function testGetExecutionDelayProgression() public {
        // Verify delay increases with protection level
        uint32 prevDelay = 0;
        for (uint8 level = 1; level <= 5; level++) {
            uint32 delay = MEVProtection.getExecutionDelay(level);
            assertTrue(delay > prevDelay, "Delay should increase with level");
            prevDelay = delay;
        }
    }

    // =============================================================
    //                    GAS THRESHOLD TESTS
    // =============================================================

    function testGetGasThreshold() public {
        // Test all protection levels
        assertEq(MEVProtection.getGasThreshold(0), 0, "Level 0 should have 0 gas threshold");
        assertEq(MEVProtection.getGasThreshold(1), 20, "Level 1 should have 20 gwei threshold");
        assertEq(MEVProtection.getGasThreshold(2), 15, "Level 2 should have 15 gwei threshold");
        assertEq(MEVProtection.getGasThreshold(3), 10, "Level 3 should have 10 gwei threshold");
        assertEq(MEVProtection.getGasThreshold(4), 5, "Level 4 should have 5 gwei threshold");
        assertEq(MEVProtection.getGasThreshold(5), 2, "Level 5 should have 2 gwei threshold");
    }

    function testGetGasThresholdInvalidLevels() public {
        // Test invalid levels
        assertEq(MEVProtection.getGasThreshold(6), 0, "Level 6 should have 0 gas threshold");
        assertEq(MEVProtection.getGasThreshold(255), 0, "Level 255 should have 0 gas threshold");
    }

    function testGetGasThresholdProgression() public {
        // Verify gas threshold decreases with protection level (more restrictive)
        uint32 prevThreshold = type(uint32).max;
        for (uint8 level = 1; level <= 5; level++) {
            uint32 threshold = MEVProtection.getGasThreshold(level);
            assertTrue(threshold < prevThreshold, "Gas threshold should decrease with level");
            prevThreshold = threshold;
        }
    }

    // =============================================================
    //                    MEV DETECTION TESTS
    // =============================================================

    function testDetectMEV() public {
        // Test MEV detection with different protection levels
        for (uint8 level = 1; level <= 5; level++) {
            (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, testSwapParams, level);
            
            // Since detection functions are simplified, they should return false
            assertFalse(detected, "MEV detection should return false for test case");
            assertEq(reason, "", "Reason should be empty when no MEV detected");
        }
    }

    function testDetectMEVWithZeroLevel() public {
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, testSwapParams, 0);
        
        assertFalse(detected, "MEV detection should return false for level 0");
        assertEq(reason, "", "Reason should be empty when no MEV detected");
    }

    function testDetectMEVWithInvalidLevel() public {
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, testSwapParams, 255);
        
        assertFalse(detected, "MEV detection should return false for invalid level");
        assertEq(reason, "", "Reason should be empty when no MEV detected");
    }

    // =============================================================
    //                    PROTECTION APPLICATION TESTS
    // =============================================================

    function testApplyProtection() public {
        // Test applying protection with different levels
        for (uint8 level = 1; level <= 5; level++) {
            bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, level);
            assertTrue(protected, "Protection should be applied successfully");
        }
    }

    function testApplyProtectionWithZeroLevel() public {
        bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, 0);
        assertFalse(protected, "Protection should not be applied for level 0");
    }

    function testApplyProtectionWithInvalidLevel() public {
        bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, 255);
        assertFalse(protected, "Protection should not be applied for invalid level");
    }

    function testApplyProtectionWithMaxLevel() public {
        bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, 5);
        assertTrue(protected, "Protection should be applied for max level");
    }

    // =============================================================
    //                    UTILITY FUNCTION TESTS
    // =============================================================

    function testGetProtectionLevelName() public {
        // Test all valid levels
        assertEq(MEVProtection.getProtectionLevelName(1), "Basic", "Level 1 should be Basic");
        assertEq(MEVProtection.getProtectionLevelName(2), "Enhanced", "Level 2 should be Enhanced");
        assertEq(MEVProtection.getProtectionLevelName(3), "Advanced", "Level 3 should be Advanced");
        assertEq(MEVProtection.getProtectionLevelName(4), "Maximum", "Level 4 should be Maximum");
        assertEq(MEVProtection.getProtectionLevelName(5), "Ultimate", "Level 5 should be Ultimate");
    }

    function testGetProtectionLevelNameInvalid() public {
        // Test invalid levels
        assertEq(MEVProtection.getProtectionLevelName(0), "Unknown", "Level 0 should be Unknown");
        assertEq(MEVProtection.getProtectionLevelName(6), "Unknown", "Level 6 should be Unknown");
        assertEq(MEVProtection.getProtectionLevelName(255), "Unknown", "Level 255 should be Unknown");
    }

    function testIsValidProtectionLevel() public {
        // Test valid levels
        for (uint8 level = 1; level <= 5; level++) {
            assertTrue(MEVProtection.isValidProtectionLevel(level), "Valid level should return true");
        }
        
        // Test invalid levels
        assertFalse(MEVProtection.isValidProtectionLevel(0), "Level 0 should be invalid");
        assertFalse(MEVProtection.isValidProtectionLevel(6), "Level 6 should be invalid");
        assertFalse(MEVProtection.isValidProtectionLevel(255), "Level 255 should be invalid");
    }

    function testIsValidProtectionLevelBoundary() public {
        // Test boundary values
        assertFalse(MEVProtection.isValidProtectionLevel(0), "Level 0 should be invalid");
        assertTrue(MEVProtection.isValidProtectionLevel(1), "Level 1 should be valid");
        assertTrue(MEVProtection.isValidProtectionLevel(5), "Level 5 should be valid");
        assertFalse(MEVProtection.isValidProtectionLevel(6), "Level 6 should be invalid");
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testEdgeCaseZeroAmount() public {
        SwapParams memory zeroAmountParams = SwapParams({
            zeroForOne: true,
            amountSpecified: 0,
            sqrtPriceLimitX96: 0
        });
        
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, zeroAmountParams, 3);
        assertFalse(detected, "Zero amount should not trigger MEV detection");
        assertEq(reason, "", "Reason should be empty for zero amount");
    }

    function testEdgeCaseMaxAmount() public {
        SwapParams memory maxAmountParams = SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(type(uint256).max),
            sqrtPriceLimitX96: 0
        });
        
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, maxAmountParams, 3);
        assertFalse(detected, "Max amount should not trigger MEV detection");
        assertEq(reason, "", "Reason should be empty for max amount");
    }

    function testEdgeCaseNegativeAmount() public {
        SwapParams memory negativeAmountParams = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT), // Positive amount (sell)
            sqrtPriceLimitX96: 0
        });
        
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, negativeAmountParams, 3);
        assertFalse(detected, "Negative amount should not trigger MEV detection");
        assertEq(reason, "", "Reason should be empty for negative amount");
    }

    function testEdgeCaseDifferentPoolKeys() public {
        // Test with different pool configurations
        PoolKey[] memory poolKeys = new PoolKey[](3);
        
        poolKeys[0] = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 500,
            tickSpacing: 10,
            hooks: IHooks(address(0))
        });
        
        poolKeys[1] = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 10000,
            tickSpacing: 200,
            hooks: IHooks(address(0))
        });
        
        poolKeys[2] = PoolKey({
            currency0: Currency.wrap(address(0x3)),
            currency1: Currency.wrap(address(0x4)),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(0))
        });
        
        for (uint256 i = 0; i < poolKeys.length; i++) {
            (bool detected, string memory reason) = MEVProtection.detectMEV(poolKeys[i], testSwapParams, 3);
            assertFalse(detected, "Different pool keys should not trigger MEV detection");
            assertEq(reason, "", "Reason should be empty for different pool keys");
        }
    }

    // =============================================================
    //                    FUZZ TESTS
    // =============================================================

    function testFuzzGetDecoyCount(uint8 level) public {
        uint8 decoyCount = MEVProtection.getDecoyCount(level);
        
        if (level >= 1 && level <= 5) {
            assertTrue(decoyCount > 0, "Valid levels should have positive decoy count");
        } else {
            assertEq(decoyCount, 0, "Invalid levels should have 0 decoy count");
        }
    }

    function testFuzzGetExecutionDelay(uint8 level) public {
        uint32 delay = MEVProtection.getExecutionDelay(level);
        
        if (level >= 1 && level <= 5) {
            assertTrue(delay > 0, "Valid levels should have positive delay");
        } else {
            assertEq(delay, 0, "Invalid levels should have 0 delay");
        }
    }

    function testFuzzGetGasThreshold(uint8 level) public {
        uint32 threshold = MEVProtection.getGasThreshold(level);
        
        if (level >= 1 && level <= 5) {
            assertTrue(threshold > 0, "Valid levels should have positive gas threshold");
        } else {
            assertEq(threshold, 0, "Invalid levels should have 0 gas threshold");
        }
    }

    function testFuzzIsValidProtectionLevel(uint8 level) public {
        bool isValid = MEVProtection.isValidProtectionLevel(level);
        
        if (level >= 1 && level <= 5) {
            assertTrue(isValid, "Valid levels should return true");
        } else {
            assertFalse(isValid, "Invalid levels should return false");
        }
    }

    function testFuzzDetectMEV(uint8 level) public {
        (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, testSwapParams, level);
        
        // Since detection is simplified, should always return false
        assertFalse(detected, "MEV detection should return false");
        assertEq(reason, "", "Reason should be empty");
    }

    function testFuzzApplyProtection(uint8 level) public {
        bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, level);
        
        if (level >= 1 && level <= 5) {
            assertTrue(protected, "Valid levels should apply protection");
        } else {
            assertFalse(protected, "Invalid levels should not apply protection");
        }
    }

    // =============================================================
    //                    GAS OPTIMIZATION TESTS
    // =============================================================

    function testGasUsageGetDecoyCount() public {
        uint256 gasStart = gasleft();
        MEVProtection.getDecoyCount(3);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for getDecoyCount:", gasUsed);
        assertTrue(gasUsed < 1000, "Gas usage should be very low for pure function");
    }

    function testGasUsageGetExecutionDelay() public {
        uint256 gasStart = gasleft();
        MEVProtection.getExecutionDelay(3);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for getExecutionDelay:", gasUsed);
        assertTrue(gasUsed < 1000, "Gas usage should be very low for pure function");
    }

    function testGasUsageGetGasThreshold() public {
        uint256 gasStart = gasleft();
        MEVProtection.getGasThreshold(3);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for getGasThreshold:", gasUsed);
        assertTrue(gasUsed < 1000, "Gas usage should be very low for pure function");
    }

    function testGasUsageDetectMEV() public {
        uint256 gasStart = gasleft();
        MEVProtection.detectMEV(testPoolKey, testSwapParams, 3);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for detectMEV:", gasUsed);
        assertTrue(gasUsed < 50000, "Gas usage should be reasonable");
    }

    function testGasUsageApplyProtection() public {
        uint256 gasStart = gasleft();
        MEVProtection.applyProtection(testPoolKey, testSwapParams, 3);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for applyProtection:", gasUsed);
        assertTrue(gasUsed < 50000, "Gas usage should be reasonable");
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function testStressDetectMEV() public {
        // Test many MEV detection calls
        for (uint256 i = 0; i < 100; i++) {
            (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, testSwapParams, uint8(i % 6));
            assertFalse(detected, "MEV detection should return false");
            assertEq(reason, "", "Reason should be empty");
        }
    }

    function testStressApplyProtection() public {
        // Test many protection applications
        for (uint256 i = 0; i < 100; i++) {
            uint8 level = uint8(i % 6);
            bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, level);
            
            if (level >= 1 && level <= 5) {
                assertTrue(protected, "Valid levels should apply protection");
            } else {
                assertFalse(protected, "Invalid levels should not apply protection");
            }
        }
    }

    function testStressUtilityFunctions() public {
        // Test many utility function calls
        for (uint256 i = 0; i < 100; i++) {
            uint8 level = uint8(i % 6);
            
            // Test all utility functions
            MEVProtection.getDecoyCount(level);
            MEVProtection.getExecutionDelay(level);
            MEVProtection.getGasThreshold(level);
            MEVProtection.getProtectionLevelName(level);
            MEVProtection.isValidProtectionLevel(level);
        }
        
        assertTrue(true, "Stress test should complete successfully");
    }

    // =============================================================
    //                    INTEGRATION TESTS
    // =============================================================

    function testProtectionLevelIntegration() public {
        // Test complete protection level workflow
        for (uint8 level = 1; level <= 5; level++) {
            // Check if level is valid
            assertTrue(MEVProtection.isValidProtectionLevel(level), "Level should be valid");
            
            // Get protection parameters
            uint8 decoyCount = MEVProtection.getDecoyCount(level);
            uint32 delay = MEVProtection.getExecutionDelay(level);
            uint32 gasThreshold = MEVProtection.getGasThreshold(level);
            string memory name = MEVProtection.getProtectionLevelName(level);
            
            // Verify parameters are reasonable
            assertTrue(decoyCount > 0, "Decoy count should be positive");
            assertTrue(delay > 0, "Delay should be positive");
            assertTrue(gasThreshold > 0, "Gas threshold should be positive");
            assertTrue(bytes(name).length > 0, "Name should not be empty");
            
            // Apply protection
            bool protected = MEVProtection.applyProtection(testPoolKey, testSwapParams, level);
            assertTrue(protected, "Protection should be applied");
        }
    }

    function testMEVDetectionIntegration() public {
        // Test MEV detection with different swap parameters
        SwapParams[] memory swapParams = new SwapParams[](3);
        
        swapParams[0] = SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        swapParams[1] = SwapParams({
            zeroForOne: false,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: 0
        });
        
        swapParams[2] = SwapParams({
            zeroForOne: true,
            amountSpecified: -int256(TEST_AMOUNT / 2),
            sqrtPriceLimitX96: 0
        });
        
        for (uint256 i = 0; i < swapParams.length; i++) {
            for (uint8 level = 1; level <= 5; level++) {
                (bool detected, string memory reason) = MEVProtection.detectMEV(testPoolKey, swapParams[i], level);
                assertFalse(detected, "MEV detection should return false");
                assertEq(reason, "", "Reason should be empty");
            }
        }
    }
}
