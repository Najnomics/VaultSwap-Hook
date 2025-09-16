// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {VaultSwapHook} from "./VaultSwapHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

/**
 * @title VaultSwap
 * @notice Main VaultSwap contract that acts as a factory for VaultSwapHook
 * @dev This is a simplified version for script compatibility
 */
contract VaultSwap {
    VaultSwapHook public immutable hook;
    
    constructor(IPoolManager _poolManager) {
        hook = new VaultSwapHook(_poolManager);
    }
    
    function getHook() external view returns (VaultSwapHook) {
        return hook;
    }
}