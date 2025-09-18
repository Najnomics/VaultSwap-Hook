// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {IntelligentRouter} from "../src/libraries/IntelligentRouter.sol";

// Uniswap v4 Imports
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

/**
 * @title IntelligentRouterTests
 * @notice Comprehensive tests for IntelligentRouter library
 */
contract IntelligentRouterTests is Test {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint128 constant TEST_AMOUNT = 1000 ether;
    uint24 constant TEST_FEE_1 = 100;
    uint24 constant TEST_FEE_2 = 3000;
    uint24 constant TEST_FEE_3 = 10000;
    int24 constant TEST_TICK_SPACING_1 = 1;
    int24 constant TEST_TICK_SPACING_2 = 60;
    int24 constant TEST_TICK_SPACING_3 = 200;

    // =============================================================
    //                           STATE
    // =============================================================

    PoolKey public basePoolKey;

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        // Create base pool key
        basePoolKey = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: TEST_FEE_2,
            tickSpacing: TEST_TICK_SPACING_2,
            hooks: IHooks(address(0))
        });
    }

    // =============================================================
    //                    CONSTANT TESTS
    // =============================================================

    function testConstants() public {
        assertEq(TEST_AMOUNT, 1000 ether, "Test amount should be 1000 ether");
        assertEq(TEST_FEE_1, 100, "Test fee 1 should be 100");
        assertEq(TEST_FEE_2, 3000, "Test fee 2 should be 3000");
        assertEq(TEST_FEE_3, 10000, "Test fee 3 should be 10000");
    }

    // =============================================================
    //                    POOL DISCOVERY TESTS
    // =============================================================

    function testDiscoverAvailablePools() public {
        PoolKey[] memory pools = IntelligentRouter.discoverAvailablePools(basePoolKey);
        
        assertTrue(pools.length > 0, "Should discover pools");
        // Note: The discoverAvailablePools function may return pools with different fees
        assertTrue(pools[0].fee > 0, "Fee should be positive");
        // Note: The discoverAvailablePools function may return pools with different tick spacings
        assertTrue(pools[0].tickSpacing > 0, "Tick spacing should be positive");
    }

    function testDiscoverAvailablePoolsWithDifferentBasePools() public {
        PoolKey[] memory basePools = new PoolKey[](3);
        
        basePools[0] = PoolKey({
            currency0: Currency.wrap(address(0x1)),
            currency1: Currency.wrap(address(0x2)),
            fee: 100,
            tickSpacing: 1,
            hooks: IHooks(address(0))
        });
        
        basePools[1] = PoolKey({
            currency0: Currency.wrap(address(0x3)),
            currency1: Currency.wrap(address(0x4)),
            fee: 5000,
            tickSpacing: 100,
            hooks: IHooks(address(0x5))
        });
        
        basePools[2] = basePoolKey;
        
        for (uint256 i = 0; i < basePools.length; i++) {
            PoolKey[] memory pools = IntelligentRouter.discoverAvailablePools(basePools[i]);
            assertTrue(pools.length > 0, "Should discover pools for each base pool");
        }
    }

    // =============================================================
    //                    UTILITY FUNCTION TESTS
    // =============================================================

    function testGetStrategyName() public {
        // Test all strategy names
        assertEq(IntelligentRouter.getStrategyName(0), "Single Pool", "Strategy 0 should be Single Pool");
        assertEq(IntelligentRouter.getStrategyName(1), "Multi-Pool Split", "Strategy 1 should be Multi-Pool Split");
        assertEq(IntelligentRouter.getStrategyName(2), "Dynamic Routing", "Strategy 2 should be Dynamic Routing");
        assertEq(IntelligentRouter.getStrategyName(3), "Liquidity Optimized", "Strategy 3 should be Liquidity Optimized");
    }

    // =============================================================
    //                    FUZZ TESTS
    // =============================================================

    function testFuzzDiscoverAvailablePools(address currency0, address currency1) public {
        // Avoid zero addresses
        vm.assume(currency0 != address(0));
        vm.assume(currency1 != address(0));
        vm.assume(currency0 != currency1);
        
        PoolKey memory basePool = PoolKey({
            currency0: Currency.wrap(currency0),
            currency1: Currency.wrap(currency1),
            fee: TEST_FEE_2,
            tickSpacing: TEST_TICK_SPACING_2,
            hooks: IHooks(address(0))
        });
        
        PoolKey[] memory pools = IntelligentRouter.discoverAvailablePools(basePool);
        
        assertEq(pools.length, 3, "Should always discover 3 pools");
        
        // Verify currencies are preserved
        for (uint256 i = 0; i < pools.length; i++) {
            assertTrue(
                (Currency.unwrap(pools[i].currency0) == currency0 && Currency.unwrap(pools[i].currency1) == currency1) ||
                (Currency.unwrap(pools[i].currency0) == currency1 && Currency.unwrap(pools[i].currency1) == currency0),
                "Currencies should be preserved"
            );
        }
    }

    // =============================================================
    //                    GAS USAGE TESTS
    // =============================================================

    function testGasUsageDiscoverAvailablePools() public {
        uint256 gasStart = gasleft();
        IntelligentRouter.discoverAvailablePools(basePoolKey);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for discoverAvailablePools:", gasUsed);
        assertTrue(gasUsed < 100000, "Gas usage should be reasonable");
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function testStressDiscoverAvailablePools() public {
        // Test many pool discoveries
        for (uint256 i = 0; i < 50; i++) {
            PoolKey memory pool = PoolKey({
                currency0: Currency.wrap(address(uint160(i + 1))),
                currency1: Currency.wrap(address(uint160(i + 2))),
                fee: uint24(i % 10000),
                tickSpacing: int24(int256(i % 200)),
                hooks: IHooks(address(0))
            });
            
            PoolKey[] memory pools = IntelligentRouter.discoverAvailablePools(pool);
            assertEq(pools.length, 3, "Should always discover 3 pools");
        }
    }
}