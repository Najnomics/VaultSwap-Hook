// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {OrderQueue} from "../src/libraries/OrderQueue.sol";

contract OrderQueueTests is Test {
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint128 constant TEST_AMOUNT_1 = 100 ether;
    uint128 constant TEST_AMOUNT_2 = 200 ether;
    uint128 constant TEST_AMOUNT_3 = 300 ether;
    uint128 constant SMALL_AMOUNT = 1 ether;
    uint128 constant LARGE_AMOUNT = 1000000 ether;

    // =============================================================
    //                           STATE
    // =============================================================

    OrderQueue public queue;

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        queue = new OrderQueue();
    }

    // =============================================================
    //                    BASIC FUNCTIONALITY TESTS
    // =============================================================

    function testQueueInitialization() public {
        assertTrue(queue.isEmpty(), "Queue should be empty initially");
        assertEq(queue.length(), 0, "Queue length should be 0 initially");
    }

    // =============================================================
    //                    ERROR HANDLING TESTS
    // =============================================================

    function testPopEmptyQueue() public {
        vm.expectRevert();
        queue.pop();
    }

    function testPeekEmptyQueue() public {
        vm.expectRevert();
        queue.peek();
    }

    // =============================================================
    //                    GAS USAGE TESTS
    // =============================================================

    function testGasUsageIsEmpty() public {
        uint256 gasStart = gasleft();
        queue.isEmpty();
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for isEmpty:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be reasonable");
    }

    function testGasUsageLength() public {
        uint256 gasStart = gasleft();
        queue.length();
        uint256 gasUsed = gasStart - gasleft();
        
        console2.log("Gas used for length:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be reasonable");
    }
}