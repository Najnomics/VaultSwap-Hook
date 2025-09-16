// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

//Foundry Imports
import "forge-std/Test.sol";

//Uniswap Imports
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {VaultSwapHook} from "../src/VaultSwapHook.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {Constants} from "@uniswap/v4-core/test/utils/Constants.sol";
import {SortTokens} from "./utils/SortTokens.sol";

import {LiquidityAmounts} from "@uniswap/v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {Fixtures} from "./utils/Fixtures.sol";

//FHE Imports
import {FHE, InEuint128, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-foundry-mocks/CoFheTest.sol";
import {HybridFHERC20} from "../src/HybridFHERC20.sol";
import {IFHERC20} from "../src/interface/IFHERC20.sol";

contract VaultSwapHookSimpleTest is Test, Fixtures {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    //test instance with useful utilities for testing FHE contracts locally
    CoFheTest CFT;

    VaultSwapHook hook;
    PoolId poolId;

    HybridFHERC20 fheToken0;
    HybridFHERC20 fheToken1;

    Currency fheCurrency0;
    Currency fheCurrency1;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    address private user = makeAddr("user");
    
    // Test users
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");
    
    // Test amounts
    uint256 constant INITIAL_LIQUIDITY = 100 ether;
    uint256 constant TEST_AMOUNT = 1 ether;

    function setUp() public {
        //initialise new CoFheTest instance with logging turned off
        CFT = new CoFheTest(false);

        bytes memory token0Args = abi.encode("TOKEN0", "TOK0");
        deployCodeTo("HybridFHERC20.sol:HybridFHERC20", token0Args, address(123));

        bytes memory token1Args = abi.encode("TOKEN1", "TOK1");
        deployCodeTo("HybridFHERC20.sol:HybridFHERC20", token1Args, address(456));

        fheToken0 = HybridFHERC20(address(123));
        fheToken1 = HybridFHERC20(address(456));    //ensure address token1 always > address token0

        vm.label(user, "user");
        vm.label(address(this), "test");
        vm.label(address(fheToken0), "token0");
        vm.label(address(fheToken1), "token1");

        // creates the pool manager, utility routers, and test tokens
        deployFreshManagerAndRouters();

        vm.startPrank(user);
        (fheCurrency0, fheCurrency1) = mintAndApprove2Currencies(address(fheToken0), address(fheToken1));

        deployAndApprovePosm(manager);

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                    | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager); //Add all the necessary constructor arguments from the hook
        deployCodeTo("VaultSwapHook.sol:VaultSwapHook", constructorArgs, flags);
        hook = VaultSwapHook(flags);

        vm.label(address(hook), "hook");
        vm.label(address(this), "test");

        // Create the pool
        PoolKey memory key = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1);

        // Provide full-range liquidity to the pool
        tickLower = TickMath.minUsableTick(key.tickSpacing);
        tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        (tokenId,) = posm.mint(
            key,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            ZERO_BYTES
        );

        vm.stopPrank();
    }

    //
    //      ... Helper Functions ...
    //
    function mintAndApprove2Currencies(address tokenA, address tokenB) internal returns (Currency, Currency) {
        Currency _currencyA = mintAndApproveCurrency(tokenA);
        Currency _currencyB = mintAndApproveCurrency(tokenB);

        (currency0, currency1) =
            SortTokens.sort(Currency.unwrap(_currencyA),Currency.unwrap(_currencyB));
        return (currency0, currency1);
    }

    function mintAndApproveCurrency(address token) internal returns (Currency currency) {
        IFHERC20(token).mint(user, 2 ** 250);
        IFHERC20(token).mint(address(this), 2 ** 250);

        //InEuint128 memory amount = CFT.createInEuint128(2 ** 120, address(this));
        InEuint128 memory amountUser = CFT.createInEuint128(2 ** 120, user);

        //IFHERC20(token).mintEncrypted(address(this), amount);
        IFHERC20(token).mintEncrypted(user, amountUser);

        address[9] memory toApprove = [
            address(swapRouter),
            address(swapRouterNoChecks),
            address(modifyLiquidityRouter),
            address(modifyLiquidityNoChecks),
            address(donateRouter),
            address(takeRouter),
            address(claimsRouter),
            address(nestedActionRouter.executor()),
            address(actionsRouter)
        ];

        for (uint256 i = 0; i < toApprove.length; i++) {
            IFHERC20(token).approve(toApprove[i], Constants.MAX_UINT256);
        }

        return Currency.wrap(token);
    }

    // =============================================================
    //                    CORE FHE FUNCTIONALITY TESTS
    // =============================================================

    function test_SubmitVaultOrder_WithFHE() public {
        vm.startPrank(alice);
        
        // Approve tokens
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Create FHE encrypted values using CoFHE test patterns
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice); // Token0 to Token1
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice); // Enhanced protection
        
        // Submit vault order
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Verify order was created
        assertTrue(orderId != bytes32(0));
        assertTrue(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_InvalidAmount_FHE() public {
        vm.startPrank(alice);
        
        // Create encrypted zero amount
        InEuint128 memory zeroAmount = createInEuint128(0, alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
        vm.expectRevert("Invalid amount");
        hook.submitVaultOrder(
            poolKey,
            zeroAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_SubmitVaultOrder_ExpiredDeadline_FHE() public {
        vm.startPrank(alice);
        
        // Create encrypted values with past deadline
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory pastDeadline = createInEuint64(uint64(block.timestamp - 1), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
        vm.expectRevert("Expired deadline");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            pastDeadline,
            encryptedMevLevel
        );
        
        vm.stopPrank();
    }

    function test_CancelVaultOrder_FHE() public {
        vm.startPrank(alice);
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        // Create and submit order
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory encryptedMevLevel = createInEuint32(2, alice);
        
        bytes32 orderId = hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            encryptedMevLevel
        );
        
        // Cancel order
        assertTrue(hook.cancelVaultOrder(orderId));
        assertFalse(hook.hasActiveOrder(alice));
        
        vm.stopPrank();
    }

    // =============================================================
    //                    MEV PROTECTION TESTS
    // =============================================================

    function test_MEVProtection_Levels_FHE() public {
        vm.startPrank(alice);
        token0.approve(address(hook), TEST_AMOUNT * 5);
        
        // Test all MEV protection levels
        for (uint32 level = 1; level <= 5; level++) {
            InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
            InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
            InEuint8 memory encryptedDirection = createInEuint8(0, alice);
            InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
            InEuint32 memory encryptedMevLevel = createInEuint32(level, alice);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            
            // Cancel order for next iteration
            hook.cancelVaultOrder(orderId);
        }
        
        vm.stopPrank();
    }

    function test_MEVProtection_InvalidLevel_FHE() public {
        vm.startPrank(alice);
        
        InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), alice);
        InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), alice);
        InEuint8 memory encryptedDirection = createInEuint8(0, alice);
        InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), alice);
        InEuint32 memory invalidMevLevel = createInEuint32(6, alice); // Beyond ultimate
        
        token0.approve(address(hook), TEST_AMOUNT);
        
        vm.expectRevert("Invalid MEV protection level");
        hook.submitVaultOrder(
            poolKey,
            encryptedAmount,
            encryptedMinOut,
            encryptedDirection,
            encryptedDeadline,
            invalidMevLevel
        );
        
        vm.stopPrank();
    }

    // =============================================================
    //                    MULTIPLE USERS TESTS
    // =============================================================

    function test_MultipleUsers_FHE() public {
        address[2] memory users = [alice, bob];
        
        for (uint i = 0; i < users.length; i++) {
            vm.startPrank(users[i]);
            token0.approve(address(hook), TEST_AMOUNT);
            
            // Each user creates their own encrypted values
            InEuint128 memory encryptedAmount = createInEuint128(uint128(TEST_AMOUNT), users[i]);
            InEuint128 memory encryptedMinOut = createInEuint128(uint128(TEST_AMOUNT * 95 / 100), users[i]);
            InEuint8 memory encryptedDirection = createInEuint8(0, users[i]);
            InEuint64 memory encryptedDeadline = createInEuint64(uint64(block.timestamp + 1 hours), users[i]);
            InEuint32 memory encryptedMevLevel = createInEuint32(2, users[i]);
            
            bytes32 orderId = hook.submitVaultOrder(
                poolKey,
                encryptedAmount,
                encryptedMinOut,
                encryptedDirection,
                encryptedDeadline,
                encryptedMevLevel
            );
            
            assertTrue(orderId != bytes32(0));
            assertTrue(hook.hasActiveOrder(users[i]));
            vm.stopPrank();
        }
    }

    // =============================================================
    //                    LIBRARY FUNCTION TESTS
    // =============================================================

    function test_MEVProtection_Constants() public {
        assertEq(MEVProtection.BASIC_PROTECTION, 1);
        assertEq(MEVProtection.ENHANCED_PROTECTION, 2);
        assertEq(MEVProtection.ADVANCED_PROTECTION, 3);
        assertEq(MEVProtection.MAXIMUM_PROTECTION, 4);
        assertEq(MEVProtection.ULTIMATE_PROTECTION, 5);
    }

    function test_MEVProtection_UtilityFunctions() public {
        assertTrue(MEVProtection.isValidProtectionLevel(1));
        assertTrue(MEVProtection.isValidProtectionLevel(5));
        assertFalse(MEVProtection.isValidProtectionLevel(0));
        assertFalse(MEVProtection.isValidProtectionLevel(6));
        
        assertEq(MEVProtection.getProtectionLevelName(1), "Basic");
        assertEq(MEVProtection.getProtectionLevelName(5), "Ultimate");
        assertEq(MEVProtection.getProtectionLevelName(0), "Unknown");
    }

    function test_ExecutionStrategies_Constants() public {
        assertEq(ExecutionStrategies.TWAP_EXECUTION, 1);
        assertEq(ExecutionStrategies.VWAP_EXECUTION, 2);
        assertEq(ExecutionStrategies.OPPORTUNISTIC_EXECUTION, 3);
        assertEq(ExecutionStrategies.IMMEDIATE_EXECUTION, 4);
    }

    function test_ExecutionStrategies_UtilityFunctions() public {
        assertTrue(ExecutionStrategies.isValidStrategy(1));
        assertTrue(ExecutionStrategies.isValidStrategy(4));
        assertFalse(ExecutionStrategies.isValidStrategy(0));
        assertFalse(ExecutionStrategies.isValidStrategy(5));
        
        assertEq(ExecutionStrategies.getStrategyName(1), "TWAP");
        assertEq(ExecutionStrategies.getStrategyName(4), "Immediate");
        assertEq(ExecutionStrategies.getStrategyName(0), "Unknown");
    }

    // =============================================================
    //                    HOOK INTEGRATION TESTS
    // =============================================================

    function test_BeforeSwap_Hook() public {
        vm.startPrank(address(manager));
        
        PoolKey memory key = poolKey;
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        // Should not revert
        hook.beforeSwap(address(this), key, params, ZERO_BYTES);
        
        vm.stopPrank();
    }

    function test_AfterSwap_Hook() public {
        vm.startPrank(address(manager));
        
        PoolKey memory key = poolKey;
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: int256(TEST_AMOUNT),
            sqrtPriceLimitX96: TickMath.MIN_SQRT_RATIO + 1
        });
        
        BalanceDelta delta = BalanceDelta.wrap(0);
        
        // Should not revert
        hook.afterSwap(address(this), key, params, delta, ZERO_BYTES);
        
        vm.stopPrank();
    }
}