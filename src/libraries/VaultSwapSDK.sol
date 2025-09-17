// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VaultSwapHook} from "../hooks/VaultSwapHook.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {InEuint128, InEuint8, InEuint32, InEuint64} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title VaultSwapSDK
 * @notice SDK interface for easier interaction with VaultSwap
 * @dev Provides simplified functions for common operations
 */
contract VaultSwapSDK {
    VaultSwapHook public immutable hook;
    
    constructor(VaultSwapHook _hook) {
        hook = _hook;
    }
    
    function createSimpleOrder(
        PoolKey calldata key,
        InEuint128 calldata amount,
        bool zeroForOne
    ) external {
        hook.placeVaultOrder(key, zeroForOne, amount);
    }
    
    function createAdvancedOrder(
        PoolKey calldata key,
        InEuint128 calldata amountIn,
        InEuint128 calldata minAmountOut,
        InEuint8 calldata direction,
        InEuint64 calldata deadline,
        InEuint32 calldata mevProtectionLevel,
        InEuint8 calldata routingStrategy,
        InEuint8 calldata executionAlgorithm,
        InEuint128 calldata maxMarketImpact
    ) external returns (bytes32 orderId) {
        return hook.submitVaultOrder(
            key,
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