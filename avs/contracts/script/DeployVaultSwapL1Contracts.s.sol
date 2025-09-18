// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {VaultSwapServiceManager} from "../src/l1-contracts/VaultSwapServiceManager.sol";
import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";

/**
 * @title DeployVaultSwapL1Contracts
 * @notice Deployment script for VaultSwap L1 contracts
 * @dev Deploys the VaultSwap service manager and related L1 infrastructure
 */
contract DeployVaultSwapL1Contracts is Script {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    VaultSwapServiceManager public vaultSwapServiceManager;
    
    // Deployment addresses (set these based on your EigenLayer deployment)
    address constant ALLOCATION_MANAGER = address(0x1234567890123456789012345678901234567890);
    address constant KEY_REGISTRAR = address(0x1234567890123456789012345678901234567890);
    address constant PERMISSION_CONTROLLER = address(0x1234567890123456789012345678901234567890);
    
    // L2 VaultSwap Hook address (update with actual L2 deployment)
    address constant VAULTSWAP_HOOK_L2 = address(0x1234567890123456789012345678901234567890);
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultSwapL1ContractsDeployed(
        address indexed serviceManager,
        address indexed allocationManager,
        address indexed keyRegistrar,
        address permissionController,
        address vaultSwapHookL2
    );
    
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("Deploying VaultSwap L1 contracts...");
        console2.log("Deployer:", deployer);
        console2.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy VaultSwap Service Manager
        vaultSwapServiceManager = new VaultSwapServiceManager(
            IAllocationManager(ALLOCATION_MANAGER),
            IKeyRegistrar(KEY_REGISTRAR),
            IPermissionController(PERMISSION_CONTROLLER),
            VAULTSWAP_HOOK_L2
        );
        
        console2.log("VaultSwap Service Manager deployed at:", address(vaultSwapServiceManager));
        
        // Initialize the service manager
        // Note: You'll need to provide actual AVS address and owner
        address avsAddress = address(0x1234567890123456789012345678901234567890);
        address owner = deployer;
        
        // Create initial AVS configuration
        VaultSwapServiceManager.AvsConfig memory initialConfig = VaultSwapServiceManager.AvsConfig({
            // Add your initial configuration here
        });
        
        // Initialize the service manager
        vaultSwapServiceManager.initialize(avsAddress, owner, initialConfig);
        
        console2.log("VaultSwap Service Manager initialized");
        
        vm.stopBroadcast();
        
        // Emit deployment event
        emit VaultSwapL1ContractsDeployed(
            address(vaultSwapServiceManager),
            ALLOCATION_MANAGER,
            KEY_REGISTRAR,
            PERMISSION_CONTROLLER,
            VAULTSWAP_HOOK_L2
        );
        
        // Log deployment summary
        _logDeploymentSummary();
    }
    
    /**
     * @notice Log deployment summary
     */
    function _logDeploymentSummary() internal view {
        console2.log("\n=== VaultSwap L1 Deployment Summary ===");
        console2.log("VaultSwap Service Manager:", address(vaultSwapServiceManager));
        console2.log("Allocation Manager:", ALLOCATION_MANAGER);
        console2.log("Key Registrar:", KEY_REGISTRAR);
        console2.log("Permission Controller:", PERMISSION_CONTROLLER);
        console2.log("VaultSwap Hook L2:", VAULTSWAP_HOOK_L2);
        console2.log("=====================================\n");
    }
    
    /**
     * @notice Verify deployment
     * @param serviceManagerAddress The deployed service manager address
     */
    function verifyDeployment(address serviceManagerAddress) external view {
        VaultSwapServiceManager manager = VaultSwapServiceManager(serviceManagerAddress);
        
        console2.log("Verifying VaultSwap L1 deployment...");
        console2.log("Service Manager Address:", serviceManagerAddress);
        console2.log("VaultSwap Hook L2:", manager.getVaultSwapHook());
        console2.log("Minimum Stake:", manager.MINIMUM_VAULTSWAP_STAKE());
        
        // Verify supported chains
        uint256[] memory supportedChains = manager.getSupportedChains();
        console2.log("Supported Chains Count:", supportedChains.length);
        for (uint256 i = 0; i < supportedChains.length; i++) {
            console2.log("Chain", i, ":", supportedChains[i]);
        }
        
        console2.log("Deployment verification complete!");
    }
}
