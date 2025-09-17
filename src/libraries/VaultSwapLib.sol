// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {euint128, euint8, euint32, euint64, FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title VaultSwapLib
 * @notice Library for VaultSwap common utilities and calculations
 * @dev Provides utility functions for order processing and calculations
 */
library VaultSwapLib {
    using PoolIdLibrary for PoolKey;
    using FHE for uint256;

    // =============================================================
    //                    CONSTANTS
    // =============================================================

    /// @notice Default performance target (85%)
    uint32 public constant DEFAULT_PERFORMANCE_TARGET = 85;
    
    /// @notice Maximum MEV protection level
    uint8 public constant MAX_MEV_PROTECTION_LEVEL = 5;
    
    /// @notice Minimum MEV protection level
    uint8 public constant MIN_MEV_PROTECTION_LEVEL = 1;

    // =============================================================
    //                    CALCULATION FUNCTIONS
    // =============================================================

    /**
     * @notice Calculate optimal decoy size based on order amount and protection level
     * @param amountIn Encrypted input amount
     * @param protectionLevel MEV protection level
     * @return decoyAmount Optimal decoy amount
     */
    function calculateOptimalDecoySize(
        euint128 amountIn,
        euint32 protectionLevel
    ) internal returns (euint128 decoyAmount) {
        // Simplified decoy size calculation - avoid division for now
        // Use a fixed percentage based on protection level
        euint32 level = FHE.sub(protectionLevel, FHE.asEuint32(1));
        euint128 multiplier = FHE.add(FHE.asEuint128(5), FHE.asEuint128(euint32.unwrap(level))); // 5-9%
        
        // Calculate decoy amount as percentage of input
        decoyAmount = FHE.mul(amountIn, multiplier);
        decoyAmount = FHE.div(decoyAmount, FHE.asEuint128(100)); // Divide by 100 to get percentage
    }

    /**
     * @notice Calculate execution window based on MEV protection level
     * @param protectionLevel MEV protection level
     * @return executionWindow Execution window in seconds
     */
    function calculateExecutionWindow(
        euint32 protectionLevel
    ) internal returns (euint64 executionWindow) {
        // Base execution window (30 seconds)
        euint64 baseWindow = FHE.asEuint64(30);
        
        // Scale by protection level
        euint32 scaledLevel = FHE.sub(protectionLevel, FHE.asEuint32(1));
        euint64 multiplier = FHE.add(FHE.asEuint64(1), FHE.asEuint64(euint32.unwrap(scaledLevel)));
        
        executionWindow = FHE.mul(baseWindow, multiplier);
    }

    /**
     * @notice Calculate minimum pool liquidity requirement
     * @param amountIn Encrypted input amount
     * @return minLiquidity Minimum required liquidity
     */
    function calculateMinLiquidity(
        euint128 amountIn
    ) internal returns (euint128 minLiquidity) {
        // Require at least 10x the order size in liquidity
        minLiquidity = FHE.mul(amountIn, FHE.asEuint128(10));
    }

    /**
     * @notice Calculate execution quality score
     * @param expectedAmount Expected output amount
     * @param actualAmount Actual output amount
     * @return quality Execution quality score (0-100)
     */
    function calculateExecutionQuality(
        uint256 expectedAmount,
        uint256 actualAmount
    ) internal pure returns (uint256 quality) {
        if (expectedAmount == 0) return 0;
        
        uint256 slippage = (expectedAmount - actualAmount) * 10000 / expectedAmount;
        
        if (slippage <= 100) return 100; // 1% or less slippage = perfect
        if (slippage <= 500) return 90;  // 5% slippage = excellent
        if (slippage <= 1000) return 80; // 10% slippage = good
        if (slippage <= 2000) return 70; // 20% slippage = fair
        if (slippage <= 5000) return 60; // 50% slippage = poor
        return 50; // >50% slippage = very poor
    }

    /**
     * @notice Validate MEV protection level
     * @param level Protection level to validate
     * @return valid Whether the level is valid
     */
    function isValidMEVProtectionLevel(uint8 level) internal pure returns (bool valid) {
        return level >= MIN_MEV_PROTECTION_LEVEL && level <= MAX_MEV_PROTECTION_LEVEL;
    }

    /**
     * @notice Get MEV protection level name
     * @param level Protection level
     * @return name Level name
     */
    function getMEVProtectionLevelName(uint8 level) internal pure returns (string memory name) {
        if (level == 1) return "Basic";
        if (level == 2) return "Enhanced";
        if (level == 3) return "Advanced";
        if (level == 4) return "Maximum";
        if (level == 5) return "Ultimate";
        return "Unknown";
    }
}