// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {Deployers} from "@uniswap/v4-core/test/utils/Deployers.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";

abstract contract Fixtures is Test, Deployers {
    // Re-export constants for convenience with unique names
    uint160 constant FIXTURES_SQRT_PRICE_1_1 = Constants.SQRT_PRICE_1_1;
    bytes constant FIXTURES_ZERO_BYTES = Constants.ZERO_BYTES;
    uint256 constant FIXTURES_MAX_SLIPPAGE_REMOVE_LIQUIDITY = 100; // 1% max slippage
}
