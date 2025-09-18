// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console2} from "forge-std/Test.sol";
import {VaultSwapTaskHook} from "../src/l2-contracts/VaultSwapTaskHook.sol";
import {ITaskMailboxTypes} from "@eigenlayer-contracts/src/contracts/interfaces/ITaskMailbox.sol";

/**
 * @title VaultSwapTaskHookTest
 * @notice Comprehensive tests for VaultSwapTaskHook
 * @dev Tests the L2 task hook functionality for VaultSwap AVS
 */
contract VaultSwapTaskHookTest is Test {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    VaultSwapTaskHook public taskHook;
    
    // Test addresses
    address public vaultSwapHook = address(0x1234567890123456789012345678901234567890);
    address public crossChainDetector = address(0x2345678901234567890123456789012345678901);
    address public serviceManager = address(0x3456789012345678901234567890123456789012);
    address public caller = address(0x4567890123456789012345678901234567890123);
    
    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/
    
    function setUp() public {
        // Deploy VaultSwapTaskHook
        taskHook = new VaultSwapTaskHook(
            vaultSwapHook,
            crossChainDetector,
            serviceManager
        );
    }
    
    /*//////////////////////////////////////////////////////////////
                            BASIC FUNCTIONALITY TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testTaskHookDeployment() public {
        assertTrue(address(taskHook) != address(0), "Task hook should be deployed");
        assertEq(taskHook.getVaultSwapHook(), vaultSwapHook, "VaultSwap hook address should match");
        assertEq(taskHook.getCrossChainDetector(), crossChainDetector, "Cross-chain detector address should match");
    }
    
    function testSupportedTaskTypes() public {
        bytes32[] memory taskTypes = taskHook.getSupportedTaskTypes();
        assertEq(taskTypes.length, 10, "Should support 10 task types");
        
        // Check specific task types
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_MEV_MONITORING()), "MEV monitoring should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_CROSS_CHAIN_PRICE_SYNC()), "Cross-chain price sync should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_MEV_OPPORTUNITY_DETECTION()), "MEV opportunity detection should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_ORDER_CREATION()), "Order creation should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_PRIVATE_ORDER_SETUP()), "Private order setup should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_ORDER_VALIDATION()), "Order validation should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_FHE_ORDER_PROCESSING()), "FHE order processing should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_ORDER_EXECUTION()), "Order execution should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_MEV_DISTRIBUTION()), "MEV distribution should be supported");
        assertTrue(_isTaskTypeSupported(taskTypes, taskHook.TASK_TYPE_CROSS_CHAIN_EXECUTION()), "Cross-chain execution should be supported");
    }
    
    function testTaskTypeFees() public {
        // Test MEV monitoring fee
        uint96 mevMonitoringFee = taskHook.getTaskTypeFee(taskHook.TASK_TYPE_MEV_MONITORING());
        assertEq(mevMonitoringFee, 0.001 ether, "MEV monitoring fee should be 0.001 ether");
        
        // Test private order setup fee (should be higher for FHE)
        uint96 privateOrderSetupFee = taskHook.getTaskTypeFee(taskHook.TASK_TYPE_PRIVATE_ORDER_SETUP());
        assertEq(privateOrderSetupFee, 0.01 ether, "Private order setup fee should be 0.01 ether");
        
        // Test cross-chain execution fee (should be highest)
        uint96 crossChainExecutionFee = taskHook.getTaskTypeFee(taskHook.TASK_TYPE_CROSS_CHAIN_EXECUTION());
        assertEq(crossChainExecutionFee, 0.02 ether, "Cross-chain execution fee should be 0.02 ether");
    }
    
    function testChainFeeMultipliers() public {
        // Test Ethereum (base chain)
        uint256 ethereumMultiplier = taskHook.getChainFeeMultiplier(1);
        assertEq(ethereumMultiplier, 10000, "Ethereum multiplier should be 1.0x");
        
        // Test Arbitrum (cheaper)
        uint256 arbitrumMultiplier = taskHook.getChainFeeMultiplier(42161);
        assertEq(arbitrumMultiplier, 5000, "Arbitrum multiplier should be 0.5x");
        
        // Test Polygon (cheapest)
        uint256 polygonMultiplier = taskHook.getChainFeeMultiplier(137);
        assertEq(polygonMultiplier, 3000, "Polygon multiplier should be 0.3x");
        
        // Test unsupported chain (should default to 1.0x)
        uint256 unsupportedMultiplier = taskHook.getChainFeeMultiplier(9999);
        assertEq(unsupportedMultiplier, 10000, "Unsupported chain should default to 1.0x");
    }
    
    function testTaskComplexityScores() public {
        // Test MEV monitoring (lowest complexity)
        uint256 mevMonitoringScore = taskHook.getTaskComplexityScore(taskHook.TASK_TYPE_MEV_MONITORING());
        assertEq(mevMonitoringScore, 100, "MEV monitoring complexity should be 100");
        
        // Test private order setup (highest complexity)
        uint256 privateOrderSetupScore = taskHook.getTaskComplexityScore(taskHook.TASK_TYPE_PRIVATE_ORDER_SETUP());
        assertEq(privateOrderSetupScore, 500, "Private order setup complexity should be 500");
        
        // Test cross-chain execution (high complexity)
        uint256 crossChainExecutionScore = taskHook.getTaskComplexityScore(taskHook.TASK_TYPE_CROSS_CHAIN_EXECUTION());
        assertEq(crossChainExecutionScore, 450, "Cross-chain execution complexity should be 450");
    }
    
    /*//////////////////////////////////////////////////////////////
                            TASK VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testValidatePreTaskCreationMEVMonitoring() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, block.chainid, "pool_id", "threshold");
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        // Should not revert
        taskHook.validatePreTaskCreation(caller, taskParams);
    }
    
    function testValidatePreTaskCreationOrderCreation() public {
        bytes32 taskType = taskHook.TASK_TYPE_ORDER_CREATION();
        bytes memory payload = abi.encode(taskType, block.chainid, "pool_id", "order_params", "additional_data");
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        // Should not revert
        taskHook.validatePreTaskCreation(caller, taskParams);
    }
    
    function testValidatePreTaskCreationInvalidTaskType() public {
        bytes32 invalidTaskType = keccak256("INVALID_TASK_TYPE");
        bytes memory payload = abi.encode(invalidTaskType, block.chainid);
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        vm.expectRevert("Unsupported task type");
        taskHook.validatePreTaskCreation(caller, taskParams);
    }
    
    function testValidatePreTaskCreationZeroCaller() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, block.chainid);
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        vm.expectRevert("Invalid caller");
        taskHook.validatePreTaskCreation(address(0), taskParams);
    }
    
    function testValidatePreTaskCreationInsufficientPayload() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType); // Too short
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        vm.expectRevert("Invalid monitoring task payload");
        taskHook.validatePreTaskCreation(caller, taskParams);
    }
    
    /*//////////////////////////////////////////////////////////////
                            TASK FEE CALCULATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testCalculateTaskFee() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, uint256(1)); // Ethereum chain
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint96 fee = taskHook.calculateTaskFee(taskParams);
        
        // Should be base fee * chain multiplier * complexity multiplier / 100000000
        // Base fee: 0.001 ether = 1000000000000000 wei
        // Chain multiplier: 10000 (1.0x)
        // Complexity multiplier: 10000 + (100 * 100) = 20000 (2.0x)
        // Final fee: 1000000000000000 * 10000 * 20000 / 100000000 = 2000000000000000 wei = 0.002 ether
        assertEq(fee, 0.002 ether, "Fee calculation should be correct");
    }
    
    function testCalculateTaskFeeArbitrum() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, uint256(42161)); // Arbitrum chain
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint96 fee = taskHook.calculateTaskFee(taskParams);
        
        // Should be base fee * chain multiplier * complexity multiplier / 100000000
        // Base fee: 0.001 ether = 1000000000000000 wei
        // Chain multiplier: 5000 (0.5x)
        // Complexity multiplier: 10000 + (100 * 100) = 20000 (2.0x)
        // Final fee: 1000000000000000 * 5000 * 20000 / 100000000 = 1000000000000000 wei = 0.001 ether
        assertEq(fee, 0.001 ether, "Arbitrum fee should be half of Ethereum");
    }
    
    function testCalculateTaskFeeHighComplexity() public {
        bytes32 taskType = taskHook.TASK_TYPE_PRIVATE_ORDER_SETUP();
        bytes memory payload = abi.encode(taskType, uint256(1)); // Ethereum chain
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint96 fee = taskHook.calculateTaskFee(taskParams);
        
        // Should be higher due to higher complexity score
        assertTrue(fee > 0.01 ether, "High complexity task should have higher fee");
    }
    
    /*//////////////////////////////////////////////////////////////
                            TASK RESULT VALIDATION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testValidatePreTaskResultSubmission() public {
        bytes32 taskHash = keccak256("test_task");
        bytes memory result = abi.encode("test_result");
        
        // Should not revert
        taskHook.validatePreTaskResultSubmission(caller, taskHash, "", result);
    }
    
    function testValidatePreTaskResultSubmissionZeroCaller() public {
        bytes32 taskHash = keccak256("test_task");
        bytes memory result = abi.encode("test_result");
        
        vm.expectRevert("Invalid caller");
        taskHook.validatePreTaskResultSubmission(address(0), taskHash, "", result);
    }
    
    function testValidatePreTaskResultSubmissionEmptyResult() public {
        bytes32 taskHash = keccak256("test_task");
        bytes memory result = "";
        
        vm.expectRevert("Empty result");
        taskHook.validatePreTaskResultSubmission(caller, taskHash, "", result);
    }
    
    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testUpdateTaskTypeFee() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        uint96 newFee = 0.005 ether;
        
        vm.startPrank(serviceManager);
        taskHook.updateTaskTypeFee(taskType, newFee);
        vm.stopPrank();
        
        assertEq(taskHook.getTaskTypeFee(taskType), newFee, "Task type fee should be updated");
    }
    
    function testUpdateTaskTypeFeeNonServiceManager() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        uint96 newFee = 0.005 ether;
        
        vm.startPrank(caller);
        vm.expectRevert("Only service manager can call");
        taskHook.updateTaskTypeFee(taskType, newFee);
        vm.stopPrank();
    }
    
    function testUpdateChainFeeMultiplier() public {
        uint256 chainId = 9999;
        uint256 multiplier = 15000; // 1.5x
        
        vm.startPrank(serviceManager);
        
        vm.expectEmit(true, false, false, false);
        emit VaultSwapTaskHook.ChainFeeMultiplierUpdated(chainId, multiplier);
        
        taskHook.updateChainFeeMultiplier(chainId, multiplier);
        vm.stopPrank();
        
        assertEq(taskHook.getChainFeeMultiplier(chainId), multiplier, "Chain fee multiplier should be updated");
    }
    
    function testUpdateChainFeeMultiplierInvalid() public {
        uint256 chainId = 9999;
        uint256 invalidMultiplier = 60000; // 6x (too high)
        
        vm.startPrank(serviceManager);
        vm.expectRevert("Invalid multiplier");
        taskHook.updateChainFeeMultiplier(chainId, invalidMultiplier);
        vm.stopPrank();
    }
    
    function testUpdateTaskComplexityScore() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        uint256 newScore = 200;
        
        vm.startPrank(serviceManager);
        taskHook.updateTaskComplexityScore(taskType, newScore);
        vm.stopPrank();
        
        assertEq(taskHook.getTaskComplexityScore(taskType), newScore, "Task complexity score should be updated");
    }
    
    function testUpdateTaskComplexityScoreTooHigh() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        uint256 tooHighScore = 1500; // Too high
        
        vm.startPrank(serviceManager);
        vm.expectRevert("Score too high");
        taskHook.updateTaskComplexityScore(taskType, tooHighScore);
        vm.stopPrank();
    }
    
    /*//////////////////////////////////////////////////////////////
                            GAS USAGE TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testGasUsageTaskValidation() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, block.chainid, "pool_id", "threshold");
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint256 gasStart = gasleft();
        taskHook.validatePreTaskCreation(caller, taskParams);
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for task validation:", gasUsed);
        assertTrue(gasUsed < 100000, "Gas usage should be reasonable");
    }
    
    function testGasUsageFeeCalculation() public {
        bytes32 taskType = taskHook.TASK_TYPE_MEV_MONITORING();
        bytes memory payload = abi.encode(taskType, uint256(1));
        
        ITaskMailboxTypes.TaskParams memory taskParams = ITaskMailboxTypes.TaskParams({
            payload: payload
        });
        
        uint256 gasStart = gasleft();
        taskHook.calculateTaskFee(taskParams);
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for fee calculation:", gasUsed);
        assertTrue(gasUsed < 50000, "Gas usage should be reasonable");
    }
    
    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    function _isTaskTypeSupported(bytes32[] memory taskTypes, bytes32 taskType) internal pure returns (bool) {
        for (uint256 i = 0; i < taskTypes.length; i++) {
            if (taskTypes[i] == taskType) {
                return true;
            }
        }
        return false;
    }
}
