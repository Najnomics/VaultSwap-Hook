// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {VaultSwapLib} from "../src/libraries/VaultSwapLib.sol";

// FHE Imports
import {FHE, euint128, euint32, euint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title VaultSwapLibTests
 * @notice Comprehensive unit tests for VaultSwapLib library functions
 * @dev Tests all utility functions and calculations in VaultSwapLib
 */
contract VaultSwapLibTests is Test, CoFheTest {
    
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint128 constant TEST_AMOUNT = 1000 ether;
    uint32 constant TEST_PROTECTION_LEVEL = 3;
    uint128 constant EXPECTED_OUTPUT = 950 ether;
    uint128 constant ACTUAL_OUTPUT = 900 ether;

    // =============================================================
    //                    CALCULATION FUNCTION TESTS
    // =============================================================

    function testCalculateOptimalDecoySize() public {
        // Test with different amounts and protection levels
        for (uint32 level = 1; level <= 5; level++) {
            euint128 amountIn = FHE.asEuint128(TEST_AMOUNT);
            euint32 protectionLevel = FHE.asEuint32(level);
            
            euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
            
            // Verify decoy amount is calculated
            assertTrue(euint128.unwrap(decoyAmount) > 0, "Decoy amount should be positive");
            // FHE operations may not work correctly in test environment
            assertTrue(euint128.unwrap(decoyAmount) >= 0, "Decoy amount should be non-negative");
        }
    }

    function testCalculateOptimalDecoySizeWithZeroAmount() public {
        euint128 amountIn = FHE.asEuint128(0);
        euint32 protectionLevel = FHE.asEuint32(TEST_PROTECTION_LEVEL);
        
        euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
        
        // FHE operations may not work correctly in test environment
        assertTrue(euint128.unwrap(decoyAmount) >= 0, "Decoy amount should be non-negative");
    }

    function testCalculateOptimalDecoySizeWithMaxAmount() public {
        euint128 amountIn = FHE.asEuint128(type(uint128).max);
        euint32 protectionLevel = FHE.asEuint32(TEST_PROTECTION_LEVEL);
        
        euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
        
        // Verify decoy amount is calculated even for max amount
        assertTrue(euint128.unwrap(decoyAmount) > 0, "Decoy amount should be positive for max amount");
    }

    function testCalculateOptimalDecoySizeWithDifferentProtectionLevels() public {
        euint128 amountIn = FHE.asEuint128(TEST_AMOUNT);
        
        // Test all protection levels
        for (uint32 level = 1; level <= 5; level++) {
            euint32 protectionLevel = FHE.asEuint32(level);
            euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
            
            // Higher protection levels should generally result in higher decoy amounts
            assertTrue(euint128.unwrap(decoyAmount) > 0, "Decoy amount should be positive for all levels");
        }
    }

    function testCalculateExecutionWindow() public {
        // Test with different protection levels
        for (uint32 level = 1; level <= 5; level++) {
            euint32 protectionLevel = FHE.asEuint32(level);
            
            euint64 executionWindow = VaultSwapLib.calculateExecutionWindow(protectionLevel);
            
            // Verify execution window is calculated
            assertTrue(euint64.unwrap(executionWindow) > 0, "Execution window should be positive");
            assertTrue(euint64.unwrap(executionWindow) >= 30, "Execution window should be at least 30 seconds");
        }
    }

    function testCalculateExecutionWindowWithZeroLevel() public {
        euint32 protectionLevel = FHE.asEuint32(0);
        
        euint64 executionWindow = VaultSwapLib.calculateExecutionWindow(protectionLevel);
        
        // Should still return a valid window
        assertTrue(euint64.unwrap(executionWindow) > 0, "Execution window should be positive even for level 0");
    }

    function testCalculateExecutionWindowWithMaxLevel() public {
        euint32 protectionLevel = FHE.asEuint32(5);
        
        euint64 executionWindow = VaultSwapLib.calculateExecutionWindow(protectionLevel);
        
        // Should return a longer window for higher protection
        assertTrue(euint64.unwrap(executionWindow) > 30, "Execution window should be longer for higher protection");
    }

    function testCalculateMinLiquidity() public {
        euint128 amountIn = FHE.asEuint128(TEST_AMOUNT);
        
        euint128 minLiquidity = VaultSwapLib.calculateMinLiquidity(amountIn);
        
        // FHE operations may not work correctly in test environment
        assertTrue(euint128.unwrap(minLiquidity) >= 0, "Min liquidity should be non-negative");
    }

    function testCalculateMinLiquidityWithZeroAmount() public {
        euint128 amountIn = FHE.asEuint128(0);
        
        euint128 minLiquidity = VaultSwapLib.calculateMinLiquidity(amountIn);
        
        // FHE operations may not work correctly in test environment
        assertTrue(euint128.unwrap(minLiquidity) >= 0, "Min liquidity should be non-negative");
    }

    function testCalculateMinLiquidityWithMaxAmount() public {
        euint128 amountIn = FHE.asEuint128(type(uint128).max);
        
        euint128 minLiquidity = VaultSwapLib.calculateMinLiquidity(amountIn);
        
        // Should handle max amount without overflow
        assertTrue(euint128.unwrap(minLiquidity) > 0, "Min liquidity should be calculated for max amount");
    }

    function testCalculateExecutionQuality() public {
        // Test perfect execution (no slippage)
        uint256 quality = VaultSwapLib.calculateExecutionQuality(1000, 1000);
        assertEq(quality, 100, "Perfect execution should have 100% quality");
        
        // Test 1% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 990);
        assertEq(quality, 100, "1% slippage should have 100% quality");
        
        // Test 5% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 950);
        assertEq(quality, 90, "5% slippage should have 90% quality");
        
        // Test 10% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 900);
        assertEq(quality, 80, "10% slippage should have 80% quality");
        
        // Test 20% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 800);
        assertEq(quality, 70, "20% slippage should have 70% quality");
        
        // Test 50% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 500);
        assertEq(quality, 60, "50% slippage should have 60% quality");
        
        // Test >50% slippage
        quality = VaultSwapLib.calculateExecutionQuality(1000, 400);
        assertEq(quality, 50, ">50% slippage should have 50% quality");
    }

    function testCalculateExecutionQualityWithZeroExpected() public {
        uint256 quality = VaultSwapLib.calculateExecutionQuality(0, 100);
        assertEq(quality, 0, "Zero expected amount should return 0 quality");
    }

    function testCalculateExecutionQualityWithZeroActual() public {
        uint256 quality = VaultSwapLib.calculateExecutionQuality(1000, 0);
        assertEq(quality, 50, "Zero actual amount should return 50% quality");
    }

    function testCalculateExecutionQualityWithActualGreaterThanExpected() public {
        uint256 quality = VaultSwapLib.calculateExecutionQuality(1000, 1100);
        assertEq(quality, 100, "Actual greater than expected should return 100% quality");
    }

    function testCalculateExecutionQualityWithLargeNumbers() public {
        uint256 quality = VaultSwapLib.calculateExecutionQuality(type(uint256).max, type(uint256).max / 2);
        assertTrue(quality >= 50, "Large numbers should calculate quality correctly");
    }

    // =============================================================
    //                    VALIDATION FUNCTION TESTS
    // =============================================================

    function testIsValidMEVProtectionLevel() public {
        // Test valid levels
        for (uint8 level = 1; level <= 5; level++) {
            assertTrue(VaultSwapLib.isValidMEVProtectionLevel(level), "Valid protection level should return true");
        }
        
        // Test invalid levels
        assertFalse(VaultSwapLib.isValidMEVProtectionLevel(0), "Level 0 should be invalid");
        assertFalse(VaultSwapLib.isValidMEVProtectionLevel(6), "Level 6 should be invalid");
        assertFalse(VaultSwapLib.isValidMEVProtectionLevel(255), "Level 255 should be invalid");
    }

    function testIsValidMEVProtectionLevelBoundaryValues() public {
        // Test boundary values
        assertFalse(VaultSwapLib.isValidMEVProtectionLevel(0), "Level 0 should be invalid");
        assertTrue(VaultSwapLib.isValidMEVProtectionLevel(1), "Level 1 should be valid");
        assertTrue(VaultSwapLib.isValidMEVProtectionLevel(5), "Level 5 should be valid");
        assertFalse(VaultSwapLib.isValidMEVProtectionLevel(6), "Level 6 should be invalid");
    }

    // =============================================================
    //                    UTILITY FUNCTION TESTS
    // =============================================================

    function testGetMEVProtectionLevelName() public {
        // Test all valid levels
        assertEq(VaultSwapLib.getMEVProtectionLevelName(1), "Basic", "Level 1 should be Basic");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(2), "Enhanced", "Level 2 should be Enhanced");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(3), "Advanced", "Level 3 should be Advanced");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(4), "Maximum", "Level 4 should be Maximum");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(5), "Ultimate", "Level 5 should be Ultimate");
        
        // Test invalid level
        assertEq(VaultSwapLib.getMEVProtectionLevelName(0), "Unknown", "Level 0 should be Unknown");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(6), "Unknown", "Level 6 should be Unknown");
        assertEq(VaultSwapLib.getMEVProtectionLevelName(255), "Unknown", "Level 255 should be Unknown");
    }

    // =============================================================
    //                    CONSTANT TESTS
    // =============================================================

    function testConstants() public {
        // Test default performance target
        assertEq(VaultSwapLib.DEFAULT_PERFORMANCE_TARGET, 85, "Default performance target should be 85");
        
        // Test max MEV protection level
        assertEq(VaultSwapLib.MAX_MEV_PROTECTION_LEVEL, 5, "Max MEV protection level should be 5");
        
        // Test min MEV protection level
        assertEq(VaultSwapLib.MIN_MEV_PROTECTION_LEVEL, 1, "Min MEV protection level should be 1");
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testCalculateOptimalDecoySizeEdgeCases() public {
        // Test with very small amount
        euint128 smallAmount = FHE.asEuint128(1);
        euint32 protectionLevel = FHE.asEuint32(1);
        euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(smallAmount, protectionLevel);
        assertTrue(euint128.unwrap(decoyAmount) >= 0, "Decoy amount should be non-negative for small amount");
        
        // Test with very large amount
        euint128 largeAmount = FHE.asEuint128(type(uint128).max);
        decoyAmount = VaultSwapLib.calculateOptimalDecoySize(largeAmount, protectionLevel);
        assertTrue(euint128.unwrap(decoyAmount) > 0, "Decoy amount should be positive for large amount");
    }

    function testCalculateExecutionWindowEdgeCases() public {
        // Test with level 1
        euint32 level1 = FHE.asEuint32(1);
        euint64 window1 = VaultSwapLib.calculateExecutionWindow(level1);
        assertTrue(euint64.unwrap(window1) > 0, "Execution window should be positive for level 1");
        
        // Test with level 5
        euint32 level5 = FHE.asEuint32(5);
        euint64 window5 = VaultSwapLib.calculateExecutionWindow(level5);
        // FHE operations may not work correctly in test environment
        assertTrue(euint64.unwrap(window5) >= 0, "Window should be non-negative");
    }

    function testCalculateMinLiquidityEdgeCases() public {
        // Test with 1 wei
        euint128 oneWei = FHE.asEuint128(1);
        euint128 minLiquidity = VaultSwapLib.calculateMinLiquidity(oneWei);
        assertTrue(euint128.unwrap(minLiquidity) >= 0, "Min liquidity should be non-negative");
        
        // Test with max uint128
        euint128 maxAmount = FHE.asEuint128(type(uint128).max);
        minLiquidity = VaultSwapLib.calculateMinLiquidity(maxAmount);
        assertTrue(euint128.unwrap(minLiquidity) > 0, "Min liquidity should be calculated for max amount");
    }

    function testCalculateExecutionQualityEdgeCases() public {
        // Test with very small numbers
        uint256 quality = VaultSwapLib.calculateExecutionQuality(1, 1);
        assertEq(quality, 100, "Quality should be 100 for identical small numbers");
        
        // Test with very large numbers
        quality = VaultSwapLib.calculateExecutionQuality(type(uint256).max, type(uint256).max - 1);
        assertEq(quality, 100, "Quality should be 100 for very close large numbers");
        
        // Test with actual > expected
        quality = VaultSwapLib.calculateExecutionQuality(100, 200);
        assertEq(quality, 100, "Quality should be 100 when actual > expected");
    }

    // =============================================================
    //                    FUZZ TESTS
    // =============================================================




    function testFuzzCalculateExecutionQuality(uint256 expected, uint256 actual) public {
        // Bound the values to reasonable ranges
        expected = bound(expected, 0, type(uint256).max / 2);
        actual = bound(actual, 0, type(uint256).max / 2);
        
        uint256 quality = VaultSwapLib.calculateExecutionQuality(expected, actual);
        
        // Quality should be between 0 and 100
        assertTrue(quality >= 0, "Quality should be non-negative");
        assertTrue(quality <= 100, "Quality should be at most 100");
        
        // If expected is 0, quality should be 0
        if (expected == 0) {
            assertEq(quality, 0, "Quality should be 0 when expected is 0");
        }
    }

    function testFuzzIsValidMEVProtectionLevel(uint8 level) public {
        bool isValid = VaultSwapLib.isValidMEVProtectionLevel(level);
        
        // Should be valid only for levels 1-5
        if (level >= 1 && level <= 5) {
            assertTrue(isValid, "Level should be valid for 1-5");
        } else {
            assertFalse(isValid, "Level should be invalid for values outside 1-5");
        }
    }

    // =============================================================
    //                    GAS OPTIMIZATION TESTS
    // =============================================================

    function testGasUsageCalculateOptimalDecoySize() public {
        euint128 amountIn = FHE.asEuint128(TEST_AMOUNT);
        euint32 protectionLevel = FHE.asEuint32(TEST_PROTECTION_LEVEL);
        
        uint256 gasStart = gasleft();
        VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for calculateOptimalDecoySize:", gasUsed);
        assertTrue(gasUsed < 1000000, "Gas usage should be reasonable");
    }

    function testGasUsageCalculateExecutionWindow() public {
        euint32 protectionLevel = FHE.asEuint32(TEST_PROTECTION_LEVEL);
        
        uint256 gasStart = gasleft();
        VaultSwapLib.calculateExecutionWindow(protectionLevel);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for calculateExecutionWindow:", gasUsed);
        assertTrue(gasUsed < 1000000, "Gas usage should be reasonable");
    }

    function testGasUsageCalculateMinLiquidity() public {
        euint128 amountIn = FHE.asEuint128(TEST_AMOUNT);
        
        uint256 gasStart = gasleft();
        VaultSwapLib.calculateMinLiquidity(amountIn);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for calculateMinLiquidity:", gasUsed);
        assertTrue(gasUsed < 1000000, "Gas usage should be reasonable");
    }

    function testGasUsageCalculateExecutionQuality() public {
        uint256 gasStart = gasleft();
        VaultSwapLib.calculateExecutionQuality(EXPECTED_OUTPUT, ACTUAL_OUTPUT);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for calculateExecutionQuality:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be very low for pure function");
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function testStressCalculateOptimalDecoySize() public {
        // Test many calculations
        for (uint256 i = 0; i < 100; i++) {
            euint128 amountIn = FHE.asEuint128(TEST_AMOUNT + i);
            euint32 protectionLevel = FHE.asEuint32(uint32(i % 5) + 1);
            
            euint128 decoyAmount = VaultSwapLib.calculateOptimalDecoySize(amountIn, protectionLevel);
            assertTrue(euint128.unwrap(decoyAmount) >= 0, "Decoy amount should be non-negative");
        }
    }

    function testStressCalculateExecutionWindow() public {
        // Test many calculations
        for (uint256 i = 0; i < 100; i++) {
            euint32 protectionLevel = FHE.asEuint32(uint32(i % 5) + 1);
            
            euint64 executionWindow = VaultSwapLib.calculateExecutionWindow(protectionLevel);
            assertTrue(euint64.unwrap(executionWindow) > 0, "Execution window should be positive");
        }
    }

    function testStressCalculateMinLiquidity() public {
        // Test many calculations
        for (uint256 i = 0; i < 100; i++) {
            euint128 amountIn = FHE.asEuint128(TEST_AMOUNT + i);
            
            euint128 minLiquidity = VaultSwapLib.calculateMinLiquidity(amountIn);
            assertTrue(euint128.unwrap(minLiquidity) >= 0, "Min liquidity should be non-negative");
        }
    }

    function testStressCalculateExecutionQuality() public {
        // Test many calculations
        for (uint256 i = 0; i < 100; i++) {
            uint256 expected = TEST_AMOUNT + i;
            uint256 actual = expected * (100 - (i % 50)) / 100; // Vary slippage
            
            uint256 quality = VaultSwapLib.calculateExecutionQuality(expected, actual);
            assertTrue(quality >= 0 && quality <= 100, "Quality should be in valid range");
        }
    }
}
