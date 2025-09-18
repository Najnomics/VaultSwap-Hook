// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {VaultSwapTaskHook} from "../src/l2-contracts/VaultSwapTaskHook.sol";

/**
 * @title DeployVaultSwapL2Contracts
 * @notice Deployment script for VaultSwap L2 contracts
 * @dev Deploys the VaultSwap task hook and related L2 infrastructure
 */
contract DeployVaultSwapL2Contracts is Script {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    VaultSwapTaskHook public vaultSwapTaskHook;
    
    // Deployment addresses (update with actual addresses)
    address constant VAULTSWAP_HOOK = address(0x1234567890123456789012345678901234567890);
    address constant CROSS_CHAIN_DETECTOR = address(0x1234567890123456789012345678901234567890);
    address constant SERVICE_MANAGER = address(0x1234567890123456789012345678901234567890);
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultSwapL2ContractsDeployed(
        address indexed taskHook,
        address indexed vaultSwapHook,
        address indexed crossChainDetector,
        address serviceManager
    );
    
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Deploying VaultSwap L2 contracts...");
        console2.log("Deployer:", deployer);
        console2.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VaultSwap Task Hook
        vaultSwapTaskHook = new VaultSwapTaskHook(
            VAULTSWAP_HOOK,
            CROSS_CHAIN_DETECTOR,
            SERVICE_MANAGER
        );
        
        console2.log("VaultSwap Task Hook deployed at:", address(vaultSwapTaskHook));
        
        vm.stopBroadcast();
        
        // Emit deployment event
        emit VaultSwapL2ContractsDeployed(
            address(vaultSwapTaskHook),
            VAULTSWAP_HOOK,
            CROSS_CHAIN_DETECTOR,
            SERVICE_MANAGER
        );
        
        // Log deployment summary
        _logDeploymentSummary();
    }
    
    /**
     * @notice Log deployment summary
     */
    function _logDeploymentSummary() internal view {
        console2.log("\n=== VaultSwap L2 Deployment Summary ===");
        console2.log("VaultSwap Task Hook:", address(vaultSwapTaskHook));
        console2.log("VaultSwap Hook:", VAULTSWAP_HOOK);
        console2.log("Cross-Chain Detector:", CROSS_CHAIN_DETECTOR);
        console2.log("Service Manager:", SERVICE_MANAGER);
        console2.log("=====================================\n");
    }
    
    /**
     * @notice Verify deployment
     * @param taskHookAddress The deployed task hook address
     */
    function verifyDeployment(address taskHookAddress) external view {
        VaultSwapTaskHook hook = VaultSwapTaskHook(taskHookAddress);
        
        console2.log("Verifying VaultSwap L2 deployment...");
        console2.log("Task Hook Address:", taskHookAddress);
        console2.log("VaultSwap Hook:", hook.getVaultSwapHook());
        console2.log("Cross-Chain Detector:", hook.getCrossChainDetector());
        
        // Verify supported task types
        bytes32[] memory taskTypes = hook.getSupportedTaskTypes();
        console2.log("Supported Task Types Count:", taskTypes.length);
        for (uint256 i = 0; i < taskTypes.length; i++) {
            console2.log("Task Type", i, ":", vm.toString(taskTypes[i]));
        }
        
        // Verify task fees
        console2.log("\nTask Type Fees:");
        for (uint256 i = 0; i < taskTypes.length; i++) {
            uint96 fee = hook.getTaskTypeFee(taskTypes[i]);
            console2.log("Task Type", i, "Fee:", fee);
        }
        
        // Verify chain fee multipliers
        console2.log("\nChain Fee Multipliers:");
        uint256[] memory chains = new uint256[](5);
        chains[0] = 1;     // Ethereum
        chains[1] = 42161; // Arbitrum
        chains[2] = 10;    // Optimism
        chains[3] = 137;   // Polygon
        chains[4] = 8453;  // Base
        
        for (uint256 i = 0; i < chains.length; i++) {
            uint256 multiplier = hook.getChainFeeMultiplier(chains[i]);
            console2.log("Chain", chains[i], "Multiplier:", multiplier);
        }
        
        console2.log("Deployment verification complete!");
    }
    
    /**
     * @notice Test task fee calculation
     * @param taskHookAddress The deployed task hook address
     * @param taskType The task type to test
     */
    function testTaskFeeCalculation(
        address taskHookAddress,
        bytes32 taskType
    ) external view {
        VaultSwapTaskHook hook = VaultSwapTaskHook(taskHookAddress);
        
        console2.log("Testing task fee calculation...");
        console2.log("Task Type:", vm.toString(taskType));
        
        // Create a test task params
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: abi.encode(taskType, block.chainid),
            // Add other required fields as needed
        });
        
        try hook.calculateTaskFee(taskParams) returns (uint96 fee) {
            console2.log("Calculated Fee:", fee);
        } catch Error(string memory reason) {
            console2.log("Error calculating fee:", reason);
        }
    }
}
