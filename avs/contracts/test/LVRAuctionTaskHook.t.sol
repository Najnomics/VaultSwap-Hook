// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {LVRAuctionTaskHook} from "../src/l2-contracts/LVRAuctionTaskHook.sol";
import {ITaskMailboxTypes} from "@eigenlayer-contracts/src/contracts/interfaces/ITaskMailbox.sol";

contract LVRAuctionTaskHookTest is Test {
    LVRAuctionTaskHook public taskHook;
    
    // Mock addresses
    address public constant MOCK_LVR_HOOK = address(0x1);
    address public constant MOCK_SERVICE_MANAGER = address(0x2);
    address public constant MOCK_CALLER = address(0x3);
    
    function setUp() public {
        taskHook = new LVRAuctionTaskHook(MOCK_LVR_HOOK, MOCK_SERVICE_MANAGER);
        
        vm.label(MOCK_LVR_HOOK, "MainLVRHook");
        vm.label(MOCK_SERVICE_MANAGER, "ServiceManager");
        vm.label(MOCK_CALLER, "TaskCaller");
    }
    
    function testTaskHookDeployment() public {
        assertEq(taskHook.getLVRAuctionHook(), MOCK_LVR_HOOK);
        console.log("Task hook correctly references main LVR hook");
    }
    
    function testTaskTypeConstants() public {
        bytes32[] memory supportedTypes = taskHook.getSupportedTaskTypes();
        
        assertEq(supportedTypes.length, 4);
        console.log("Supports 4 LVR auction task types");
        
        // Test that task types are properly defined
        assertTrue(supportedTypes[0] != bytes32(0), "LVR_MONITORING type defined");
        assertTrue(supportedTypes[1] != bytes32(0), "AUCTION_CREATION type defined");
        assertTrue(supportedTypes[2] != bytes32(0), "BID_VALIDATION type defined");
        assertTrue(supportedTypes[3] != bytes32(0), "SETTLEMENT type defined");
    }
    
    function testTaskFeeStructure() public {
        bytes32 monitoringType = keccak256("LVR_MONITORING");
        uint96 fee = taskHook.getTaskTypeFee(monitoringType);
        
        assertGt(fee, 0, "Monitoring task should have non-zero fee");
        console.log("LVR monitoring task fee:", fee);
        
        bytes32 settlementType = keccak256("SETTLEMENT");
        uint96 settlementFee = taskHook.getTaskTypeFee(settlementType);
        
        assertGt(settlementFee, fee, "Settlement should cost more than monitoring");
        console.log("Settlement task fee:", settlementFee);
    }
    
    function testTaskValidationBasic() public {
        // Create a minimal task params structure
        bytes memory payload = abi.encodePacked(keccak256("LVR_MONITORING"));
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        // This should not revert for valid task type
        try taskHook.validatePreTaskCreation(MOCK_CALLER, taskParams) {
            console.log("Basic task validation passed");
        } catch {
            fail("Basic task validation should not revert");
        }
    }
    
    function testConnectorPattern() public {
        // Test that this is a connector, not business logic
        console.log("Testing L2 connector pattern");
        
        // The task hook should:
        // 1. Interface with EigenLayer task system
        // 2. Reference the main LVR hook (business logic)
        // 3. NOT implement auction logic itself
        
        assertEq(taskHook.getLVRAuctionHook(), MOCK_LVR_HOOK, "Should reference main hook");
        
        // Test that it calculates fees (coordination function)
        bytes memory payload = abi.encodePacked(keccak256("LVR_MONITORING"));
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint96 fee = taskHook.calculateTaskFee(taskParams);
        assertGt(fee, 0, "Should calculate task fees");
        
        console.log("L2 connector pattern test passed");
    }
    
    function testInvalidTaskType() public {
        bytes memory invalidPayload = abi.encodePacked(keccak256("INVALID_TYPE"));
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: invalidPayload
        });
        
        // Should revert for unsupported task type
        vm.expectRevert("Unsupported task type");
        taskHook.validatePreTaskCreation(MOCK_CALLER, taskParams);
        
        console.log("Invalid task type properly rejected");
    }
}