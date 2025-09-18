// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {VaultSwapServiceManager} from "../src/l1-contracts/VaultSwapServiceManager.sol";
import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";

/**
 * @title VaultSwapServiceManagerTest
 * @notice Comprehensive tests for VaultSwapServiceManager
 * @dev Tests the L1 service manager functionality for VaultSwap AVS
 */
contract VaultSwapServiceManagerTest is Test {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    VaultSwapServiceManager public serviceManager;
    
    // Mock contracts
    IAllocationManager public allocationManager;
    IKeyRegistrar public keyRegistrar;
    IPermissionController public permissionController;
    
    // Test addresses
    address public vaultSwapHookL2 = address(0x1234567890123456789012345678901234567890);
    address public operator = address(0x2345678901234567890123456789012345678901);
    address public owner = address(0x3456789012345678901234567890123456789012);
    address public avs = address(0x4567890123456789012345678901234567890123);
    
    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    
    function setUp() public {
        // Deploy mock contracts
        allocationManager = IAllocationManager(address(0x1001));
        keyRegistrar = IKeyRegistrar(address(0x1002));
        permissionController = IPermissionController(address(0x1003));
        
        // Deploy VaultSwapServiceManager
        serviceManager = new VaultSwapServiceManager(
            allocationManager,
            keyRegistrar,
            permissionController,
            vaultSwapHookL2
        );
        
        // Initialize the service manager
        VaultSwapServiceManager.AvsConfig memory initialConfig = VaultSwapServiceManager.AvsConfig({
            // Add initial configuration here
        });
        
        serviceManager.initialize(avs, owner, initialConfig);
    }
    
    /*//////////////////////////////////////////////////////////////
                            BASIC FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testServiceManagerDeployment() public {
        assertTrue(address(serviceManager) != address(0), "Service manager should be deployed");
        assertEq(serviceManager.getVaultSwapHook(), vaultSwapHookL2, "L2 hook address should match");
        assertEq(serviceManager.MINIMUM_VAULTSWAP_STAKE(), 10 ether, "Minimum stake should be 10 ether");
    }
    
    function testSupportedChains() public {
        uint256[] memory supportedChains = serviceManager.getSupportedChains();
        assertEq(supportedChains.length, 5, "Should support 5 chains");
        
        // Check specific chains
        assertTrue(serviceManager.isChainSupported(1), "Ethereum should be supported");
        assertTrue(serviceManager.isChainSupported(42161), "Arbitrum should be supported");
        assertTrue(serviceManager.isChainSupported(10), "Optimism should be supported");
        assertTrue(serviceManager.isChainSupported(137), "Polygon should be supported");
        assertTrue(serviceManager.isChainSupported(8453), "Base should be supported");
    }
    
    function testOperatorRegistration() public {
        // Test operator registration with sufficient stake
        uint256 stakeAmount = 15 ether; // More than minimum required
        
        vm.deal(operator, stakeAmount);
        vm.startPrank(operator);
        
        bytes memory operatorSignature = abi.encodePacked("test_signature");
        
        // Expect event emission
        vm.expectEmit(true, true, false, false);
        emit VaultSwapServiceManager.VaultSwapOperatorRegistered(operator, bytes32(0));
        
        serviceManager.registerVaultSwapOperator{value: stakeAmount}(
            operator,
            operatorSignature
        );
        
        vm.stopPrank();
        
        // Verify operator is qualified
        assertTrue(serviceManager.isVaultSwapOperatorQualified(operator), "Operator should be qualified");
    }
    
    function testOperatorRegistrationInsufficientStake() public {
        uint256 stakeAmount = 5 ether; // Less than minimum required
        
        vm.deal(operator, stakeAmount);
        vm.startPrank(operator);
        
        bytes memory operatorSignature = abi.encodePacked("test_signature");
        
        vm.expectRevert("Insufficient stake for VaultSwap operations");
        serviceManager.registerVaultSwapOperator{value: stakeAmount}(
            operator,
            operatorSignature
        );
        
        vm.stopPrank();
    }
    
    function testOperatorDeregistration() public {
        // First register an operator
        uint256 stakeAmount = 15 ether;
        vm.deal(operator, stakeAmount);
        vm.startPrank(operator);
        
        bytes memory operatorSignature = abi.encodePacked("test_signature");
        serviceManager.registerVaultSwapOperator{value: stakeAmount}(
            operator,
            operatorSignature
        );
        
        vm.stopPrank();
        
        // Now deregister
        vm.expectEmit(true, true, false, false);
        emit VaultSwapServiceManager.VaultSwapOperatorDeregistered(operator, bytes32(0));
        
        serviceManager.deregisterVaultSwapOperator(operator);
    }
    
    /*//////////////////////////////////////////////////////////////
                            CHAIN MANAGEMENT TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testUpdateChainSupport() public {
        uint256 newChainId = 9999;
        
        // Initially not supported
        assertFalse(serviceManager.isChainSupported(newChainId), "New chain should not be supported initially");
        
        // Update chain support (only owner can do this)
        vm.startPrank(owner);
        
        vm.expectEmit(true, false, false, false);
        emit VaultSwapServiceManager.ChainSupportUpdated(newChainId, true);
        
        serviceManager.updateChainSupport(newChainId, true);
        
        vm.stopPrank();
        
        // Now should be supported
        assertTrue(serviceManager.isChainSupported(newChainId), "New chain should be supported after update");
    }
    
    function testUpdateChainSupportNonOwner() public {
        uint256 newChainId = 9999;
        
        vm.startPrank(operator);
        
        vm.expectRevert();
        serviceManager.updateChainSupport(newChainId, true);
        
        vm.stopPrank();
    }
    
    /*//////////////////////////////////////////////////////////////
                            GAS USAGE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testGasUsageOperatorRegistration() public {
        uint256 stakeAmount = 15 ether;
        vm.deal(operator, stakeAmount);
        
        uint256 gasStart = gasleft();
        
        vm.startPrank(operator);
        bytes memory operatorSignature = abi.encodePacked("test_signature");
        serviceManager.registerVaultSwapOperator{value: stakeAmount}(
            operator,
            operatorSignature
        );
        vm.stopPrank();
        
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for operator registration:", gasUsed);
        assertTrue(gasUsed < 200000, "Gas usage should be reasonable");
    }
    
    function testGasUsageChainSupportCheck() public {
        uint256 gasStart = gasleft();
        serviceManager.isChainSupported(1);
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for chain support check:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be reasonable");
    }
    
    /*//////////////////////////////////////////////////////////////
                            STRESS TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testMultipleOperatorRegistration() public {
        address[] memory operators = new address[](5);
        for (uint256 i = 0; i < 5; i++) {
            operators[i] = address(uint160(0x1000 + i));
        }
        
        uint256 stakeAmount = 15 ether;
        
        for (uint256 i = 0; i < operators.length; i++) {
            vm.deal(operators[i], stakeAmount);
            vm.startPrank(operators[i]);
            
            bytes memory operatorSignature = abi.encodePacked("test_signature_", i);
            serviceManager.registerVaultSwapOperator{value: stakeAmount}(
                operators[i],
                operatorSignature
            );
            
            vm.stopPrank();
            
            // Verify operator is qualified
            assertTrue(serviceManager.isVaultSwapOperatorQualified(operators[i]), "Operator should be qualified");
        }
    }
    
    function testMultipleChainSupport() public {
        uint256[] memory newChains = new uint256[](10);
        for (uint256 i = 0; i < 10; i++) {
            newChains[i] = 10000 + i;
        }
        
        vm.startPrank(owner);
        
        for (uint256 i = 0; i < newChains.length; i++) {
            serviceManager.updateChainSupport(newChains[i], true);
            assertTrue(serviceManager.isChainSupported(newChains[i]), "Chain should be supported");
        }
        
        vm.stopPrank();
    }
    
    /*//////////////////////////////////////////////////////////////
                            EDGE CASE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testZeroAddressL2Hook() public {
        vm.expectRevert("Invalid L2 hook address");
        new VaultSwapServiceManager(
            allocationManager,
            keyRegistrar,
            permissionController,
            address(0)
        );
    }
    
    function testZeroStakeAmount() public {
        vm.startPrank(operator);
        
        bytes memory operatorSignature = abi.encodePacked("test_signature");
        
        vm.expectRevert("Insufficient stake for VaultSwap operations");
        serviceManager.registerVaultSwapOperator{value: 0}(
            operator,
            operatorSignature
        );
        
        vm.stopPrank();
    }
    
    function testEmptyOperatorSignature() public {
        uint256 stakeAmount = 15 ether;
        vm.deal(operator, stakeAmount);
        
        vm.startPrank(operator);
        
        // This should still work as signature validation is not implemented in the mock
        serviceManager.registerVaultSwapOperator{value: stakeAmount}(
            operator,
            ""
        );
        
        vm.stopPrank();
        
        assertTrue(serviceManager.isVaultSwapOperatorQualified(operator), "Operator should be qualified");
    }
}
