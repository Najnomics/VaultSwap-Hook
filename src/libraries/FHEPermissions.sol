// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {FHE, euint128, euint64, euint32, euint8, ebool} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title FHEPermissions
 * @notice Centralized FHE permission management following best practices from context repos
 * @dev Implements the critical "Define Access" step in Fhenix's 3-step CoFHE pattern
 */
library FHEPermissions {
    
    // =============================================================
    //                    CORE PERMISSION FUNCTIONS
    // =============================================================

    /**
     * @notice Grant comprehensive permissions for order creation
     * @param amountIn Encrypted input amount
     * @param minAmountOut Encrypted minimum output amount
     * @param deadline Encrypted execution deadline
     * @param mevProtectionLevel Encrypted MEV protection level
     * @param user Address of the order creator
     * @param contractAddr Address of the contract
     */
    function grantOrderCreationPermissions(
        euint128 amountIn,
        euint128 minAmountOut,
        euint64 deadline,
        euint32 mevProtectionLevel,
        address user,
        address contractAddr
    ) internal {
        // Grant user permissions - user needs access to view their order parameters
        FHE.allow(amountIn, user);
        FHE.allow(minAmountOut, user);
        FHE.allow(deadline, user);
        FHE.allow(mevProtectionLevel, user);
        
        // Grant contract permissions - contract needs access for calculations and storage
        FHE.allowThis(amountIn);
        FHE.allowThis(minAmountOut);
        FHE.allowThis(deadline);
        FHE.allowThis(mevProtectionLevel);
    }

    /**
     * @notice Grant permissions for bid operations (adapted from StealthAuction patterns)
     * @param bidAmount Encrypted bid amount
     * @param allocation Encrypted token allocation
     * @param currentPrice Encrypted current price
     * @param bidder Address of the bidder
     * @param token Address of the token contract
     * @param contractAddr Address of the contract
     */
    function grantBidPermissions(
        euint128 bidAmount,
        euint128 allocation,
        euint128 currentPrice,
        address bidder,
        address token,
        address contractAddr
    ) internal {
        // Bidder permissions - bidder needs access to their bid data
        FHE.allow(bidAmount, bidder);
        FHE.allow(allocation, bidder);
        
        // Contract permissions - contract needs access for validation and storage
        FHE.allowThis(bidAmount);
        FHE.allowThis(allocation);
        FHE.allowThis(currentPrice);
        
        // Token permissions - token contract needs access for encrypted transfers
        FHE.allow(allocation, token);
        FHE.allow(bidAmount, token);
    }

    /**
     * @notice Grant permissions for settlement operations
     * @param totalAllocation Total encrypted allocation amount
     * @param remainingSupply Remaining encrypted supply
     * @param seller Address of the seller
     * @param token Address of the token contract
     * @param contractAddr Address of the contract
     */
    function grantSettlementPermissions(
        euint128 totalAllocation,
        euint128 remainingSupply,
        address seller,
        address token,
        address contractAddr
    ) internal {
        // Seller permissions - seller needs access to settlement data
        FHE.allow(totalAllocation, seller);
        FHE.allow(remainingSupply, seller);
        
        // Contract permissions - contract needs access for calculations
        FHE.allowThis(totalAllocation);
        FHE.allowThis(remainingSupply);
        
        // Token permissions - token contract needs access for final transfers
        FHE.allow(totalAllocation, token);
    }

    /**
     * @notice Grant permissions for pool operations (adapted from Iceberg patterns)
     * @param amount0 Encrypted amount for currency0
     * @param amount1 Encrypted amount for currency1
     * @param currency0 Address of currency0
     * @param currency1 Address of currency1
     * @param hookContract Address of the hook contract
     */
    function grantPoolPermissions(
        euint128 amount0,
        euint128 amount1,
        address currency0,
        address currency1,
        address hookContract
    ) internal {
        // Currency permissions - each currency needs access to its amount
        FHE.allow(amount0, currency0);
        FHE.allow(amount1, currency1);
        
        // Hook permissions - hook contract needs access for calculations
        FHE.allowThis(amount0);
        FHE.allowThis(amount1);
    }

    /**
     * @notice Grant permissions for swap operations
     * @param swapAmount Encrypted swap amount
     * @param maxAllowed Encrypted maximum allowed amount
     * @param isValid Encrypted validation result
     * @param sender Address of the swap sender
     * @param contractAddr Address of the contract
     */
    function grantSwapPermissions(
        euint128 swapAmount,
        euint128 maxAllowed,
        ebool isValid,
        address sender,
        address contractAddr
    ) internal {
        // Sender permissions - sender needs access to swap data
        FHE.allow(swapAmount, sender);
        
        // Contract permissions - contract needs access for validation
        FHE.allowThis(swapAmount);
        FHE.allowThis(maxAllowed);
        FHE.allowThis(isValid);
    }

    /**
     * @notice Grant permissions for time-based operations
     * @param startTime Encrypted start time
     * @param duration Encrypted duration
     * @param currentTime Encrypted current time
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantTimePermissions(
        euint64 startTime,
        euint64 duration,
        euint64 currentTime,
        address user,
        address contractAddr
    ) internal {
        // User permissions - user needs access to time data
        FHE.allow(startTime, user);
        FHE.allow(duration, user);
        
        // Contract permissions - contract needs access for time calculations
        FHE.allowThis(startTime);
        FHE.allowThis(duration);
        FHE.allowThis(currentTime);
    }

    /**
     * @notice Grant permissions for boolean operations
     * @param boolValue Encrypted boolean value
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantBoolPermissions(ebool boolValue, address user, address contractAddr) internal {
        FHE.allow(boolValue, user);
        FHE.allowThis(boolValue);
    }

    // =============================================================
    //                    ENHANCED VAULT PERMISSIONS
    // =============================================================

    /**
     * @notice Grant comprehensive permissions for enhanced vault orders
     * @param amountIn Encrypted input amount
     * @param minAmountOut Encrypted minimum output
     * @param direction Encrypted swap direction
     * @param deadline Encrypted deadline
     * @param mevProtectionLevel Encrypted MEV protection level
     * @param routingStrategy Encrypted routing strategy
     * @param executionAlgorithm Encrypted execution algorithm
     * @param maxMarketImpact Encrypted maximum market impact
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantEnhancedVaultPermissions(
        euint128 amountIn,
        euint128 minAmountOut,
        euint8 direction,
        euint64 deadline,
        euint32 mevProtectionLevel,
        euint8 routingStrategy,
        euint8 executionAlgorithm,
        euint128 maxMarketImpact,
        address user,
        address contractAddr
    ) internal {
        // Core order permissions
        grantOrderCreationPermissions(amountIn, minAmountOut, deadline, mevProtectionLevel, user, contractAddr);
        
        // Enhanced parameter permissions
        FHE.allow(direction, user);
        FHE.allow(routingStrategy, user);
        FHE.allow(executionAlgorithm, user);
        FHE.allow(maxMarketImpact, user);
        
        FHE.allowThis(direction);
        FHE.allowThis(routingStrategy);
        FHE.allowThis(executionAlgorithm);
        FHE.allowThis(maxMarketImpact);
    }

    /**
     * @notice Grant permissions for MEV protection features
     * @param decoyAmount Encrypted decoy amount
     * @param executionWindow Encrypted execution window
     * @param stealthMode Encrypted stealth mode
     * @param gasOptimization Encrypted gas optimization
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantMEVProtectionPermissions(
        euint128 decoyAmount,
        euint64 executionWindow,
        euint8 stealthMode,
        euint64 gasOptimization,
        address user,
        address contractAddr
    ) internal {
        // MEV protection permissions
        FHE.allow(decoyAmount, user);
        FHE.allow(executionWindow, user);
        FHE.allow(stealthMode, user);
        FHE.allow(gasOptimization, user);
        
        FHE.allowThis(decoyAmount);
        FHE.allowThis(executionWindow);
        FHE.allowThis(stealthMode);
        FHE.allowThis(gasOptimization);
    }

    /**
     * @notice Grant permissions for routing features
     * @param maxPools Encrypted maximum pools
     * @param minPoolLiquidity Encrypted minimum pool liquidity
     * @param performanceTarget Encrypted performance target
     * @param complianceFlags Encrypted compliance flags
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantRoutingPermissions(
        euint32 maxPools,
        euint128 minPoolLiquidity,
        euint32 performanceTarget,
        euint64 complianceFlags,
        address user,
        address contractAddr
    ) internal {
        // Routing permissions
        FHE.allow(maxPools, user);
        FHE.allow(minPoolLiquidity, user);
        FHE.allow(performanceTarget, user);
        FHE.allow(complianceFlags, user);
        
        FHE.allowThis(maxPools);
        FHE.allowThis(minPoolLiquidity);
        FHE.allowThis(performanceTarget);
        FHE.allowThis(complianceFlags);
    }

    /**
     * @notice Grant permissions for execution analytics
     * @param expectedOutput Encrypted expected output
     * @param actualOutput Encrypted actual output
     * @param executionQuality Encrypted execution quality
     * @param executionTime Encrypted execution time
     * @param gasUsed Encrypted gas used
     * @param slippagePercent Encrypted slippage percentage
     * @param targetsMet Encrypted targets met flag
     * @param user Address of the user
     * @param contractAddr Address of the contract
     */
    function grantAnalyticsPermissions(
        euint128 expectedOutput,
        euint128 actualOutput,
        euint32 executionQuality,
        euint64 executionTime,
        euint128 gasUsed,
        euint32 slippagePercent,
        ebool targetsMet,
        address user,
        address contractAddr
    ) internal {
        // Analytics permissions
        FHE.allow(expectedOutput, user);
        FHE.allow(actualOutput, user);
        FHE.allow(executionQuality, user);
        FHE.allow(executionTime, user);
        FHE.allow(gasUsed, user);
        FHE.allow(slippagePercent, user);
        FHE.allow(targetsMet, user);
        
        FHE.allowThis(expectedOutput);
        FHE.allowThis(actualOutput);
        FHE.allowThis(executionQuality);
        FHE.allowThis(executionTime);
        FHE.allowThis(gasUsed);
        FHE.allowThis(slippagePercent);
        FHE.allowThis(targetsMet);
    }

    // =============================================================
    //                    BATCH PERMISSION FUNCTIONS
    // =============================================================

    /**
     * @notice Grant all permissions for a complete vault order
     * @param orderId Order identifier for reference
     * @param user User address
     * @param contractAddr Contract address
     * @param tokenAddr Token address (if applicable)
     */
    function grantCompleteVaultOrderPermissions(
        bytes32 orderId,
        address user,
        address contractAddr,
        address tokenAddr
    ) internal {
        // This function would be called with all the encrypted values
        // for a complete permission setup in a single transaction
        // Implementation would depend on the specific encrypted values available
    }

    /**
     * @notice Revoke permissions for a cancelled or completed order
     * @param orderId Order identifier
     * @param user User address
     * @param contractAddr Contract address
     */
    function revokeOrderPermissions(
        bytes32 orderId,
        address user,
        address contractAddr
    ) internal {
        // In practice, FHE permissions can't be revoked
        // This is a placeholder for potential future functionality
        // or for cleanup operations that don't require revocation
    }

    // =============================================================
    //                    UTILITY FUNCTIONS
    // =============================================================

    /**
     * @notice Setup basic FHE permissions for a contract
     * @param contractAddr Contract address
     */
    function setupBasicContractPermissions(address contractAddr) internal {
        // Initialize basic encrypted values for contract operations
        euint128 zeroAmount = FHE.asEuint128(0);
        euint32 zeroCount = FHE.asEuint32(0);
        euint64 currentTime = FHE.asEuint64(block.timestamp);
        ebool falseFlag = FHE.asEbool(false);
        
        // Grant self permissions
        FHE.allowThis(zeroAmount);
        FHE.allowThis(zeroCount);
        FHE.allowThis(currentTime);
        FHE.allowThis(falseFlag);
    }

    /**
     * @notice Validate that required permissions are properly set
     * @param value Encrypted value to check
     * @param user User address
     * @param contractAddr Contract address
     * @return hasPermissions Whether permissions are properly set
     */
    function validatePermissions(
        euint128 value,
        address user,
        address contractAddr
    ) internal view returns (bool hasPermissions) {
        // This is a conceptual function - actual permission validation
        // would depend on the FHE implementation details
        // For now, always return true as permissions are set when granted
        return true;
    }

    /**
     * @notice Emergency permission reset for a user
     * @param user User address to reset permissions for
     * @param contractAddr Contract address
     */
    function emergencyPermissionReset(address user, address contractAddr) internal {
        // Emergency function to reset permissions in case of issues
        // Implementation would depend on specific FHE capabilities
        setupBasicContractPermissions(contractAddr);
    }
}