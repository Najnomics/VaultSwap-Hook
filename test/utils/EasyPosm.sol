// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";

library EasyPosm {
    function decreaseLiquidity(
        IPositionManager posm,
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0Min,
        uint256 amount1Min,
        address recipient,
        uint256 deadline,
        bytes calldata hookData
    ) internal returns (uint256 amount0, uint256 amount1) {
        return posm.decreaseLiquidity(
            IPositionManager.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: amount0Min,
                amount1Min: amount1Min,
                recipient: recipient,
                deadline: deadline,
                hookData: hookData
            })
        );
    }
}
