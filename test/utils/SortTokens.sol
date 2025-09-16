// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

library SortTokens {
    function sort(address tokenA, address tokenB) internal pure returns (Currency, Currency) {
        return tokenA < tokenB ? (Currency.wrap(tokenA), Currency.wrap(tokenB)) : (Currency.wrap(tokenB), Currency.wrap(tokenA));
    }
}
