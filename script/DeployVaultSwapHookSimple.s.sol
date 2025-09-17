// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {VaultSwapHook} from "../src/hooks/VaultSwapHook.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";
import {HybridFHERC20} from "../src/tokens/HybridFHERC20.sol";

/// @notice Simple forge script for deploying VaultSwapHook to **anvil**
contract VaultSwapHookSimpleScript is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
    
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        
        // Deploy the pool manager first
        IPoolManager manager = IPoolManager(address(new PoolManager(address(0))));
        console.log("PoolManager deployed at:", address(manager));

        // hook contracts must have specific flags encoded in the address
        uint160 permissions = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with the correct permissions
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, permissions, type(VaultSwapHook).creationCode, abi.encode(address(manager)));

        // Deploy the hook using CREATE2
        VaultSwapHook vaultSwapHook = new VaultSwapHook{salt: salt}(manager);
        require(address(vaultSwapHook) == hookAddress, "VaultSwapHookScript: hook address mismatch");
        
        console.log("VaultSwapHook deployed at:", address(vaultSwapHook));
        
        // Deploy test HybridFHERC20 tokens
        HybridFHERC20 token0 = new HybridFHERC20("Test Token A", "TTA");
        HybridFHERC20 token1 = new HybridFHERC20("Test Token B", "TTB");
        
        console.log("Token0 deployed at:", address(token0));
        console.log("Token1 deployed at:", address(token1));
        
        // Mint some tokens for testing
        token0.mint(msg.sender, 1000000 ether);
        token1.mint(msg.sender, 1000000 ether);
        
        console.log("Deployment completed successfully!");
        console.log("Hook Address:", address(vaultSwapHook));
        console.log("PoolManager Address:", address(manager));
        
        vm.stopBroadcast();
    }
}