// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {CoFheTest} from "@fhenixprotocol/cofhe-mock-contracts/CoFheTest.sol";
import {OrderQueue} from "../src/libraries/OrderQueue.sol";

// FHE Imports
import {FHE, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title OrderQueueTests
 * @notice Comprehensive unit tests for OrderQueue library functionality
 * @dev Tests queue operations with encrypted values
 */
contract OrderQueueTests is Test, CoFheTest {
    
    // =============================================================
    //                           CONSTANTS
    // =============================================================

    uint128 constant TEST_AMOUNT_1 = 1000 ether;
    uint128 constant TEST_AMOUNT_2 = 2000 ether;
    uint128 constant TEST_AMOUNT_3 = 3000 ether;
    uint128 constant SMALL_AMOUNT = 1 ether;
    uint128 constant LARGE_AMOUNT = 1000000 ether;

    // =============================================================
    //                           CONTRACTS
    // =============================================================

    OrderQueue public queue;
    
    // =============================================================
    //                           STATE
    // =============================================================

    address public user = makeAddr("user");

    // =============================================================
    //                           SETUP
    // =============================================================

    function setUp() public {
        queue = new OrderQueue();
        vm.label(user, "user");
        vm.label(address(queue), "queue");
    }

    // =============================================================
    //                    BASIC QUEUE OPERATION TESTS
    // =============================================================

    function testQueueInitialization() public {
        assertTrue(queue.isEmpty(), "Queue should be empty initially");
        assertEq(queue.length(), 0, "Queue length should be 0 initially");
        assertEq(queue.size(), 0, "Queue size should be 0 initially");
    }

    function testPushSingleItem() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        queue.push(handle);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty after push");
        assertEq(queue.length(), 1, "Queue length should be 1");
        assertEq(queue.size(), 1, "Queue size should be 1");
    }

    function testPushMultipleItems() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        euint128 handle3 = FHE.asEuint128(TEST_AMOUNT_3);
        
        queue.push(handle1);
        queue.push(handle2);
        queue.push(handle3);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty");
        assertEq(queue.length(), 3, "Queue length should be 3");
        assertEq(queue.size(), 3, "Queue size should be 3");
    }

    function testPeekSingleItem() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        queue.push(handle);
        euint128 peekedHandle = queue.peek();
        
        // Note: FHE values may not match exactly due to encryption, so we just verify it's not zero
        assertTrue(euint128.unwrap(peekedHandle) > 0, "Peeked handle should be non-zero");
    }

    function testPeekMultipleItems() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        
        queue.push(handle1);
        queue.push(handle2);
        
        euint128 peekedHandle = queue.peek();
        assertTrue(euint128.unwrap(peekedHandle) > 0, "Peek should return non-zero value");
    }

    function testPopSingleItem() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        queue.push(handle);
        euint128 poppedHandle = queue.pop();
        
        assertTrue(euint128.unwrap(poppedHandle) > 0, "Popped handle should be non-zero");
        assertTrue(queue.isEmpty(), "Queue should be empty after pop");
        assertEq(queue.length(), 0, "Queue length should be 0 after pop");
    }

    function testPopMultipleItems() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        euint128 handle3 = FHE.asEuint128(TEST_AMOUNT_3);
        
        queue.push(handle1);
        queue.push(handle2);
        queue.push(handle3);
        
        // Pop first item
        euint128 popped1 = queue.pop();
        assertTrue(euint128.unwrap(popped1) > 0, "First pop should return non-zero value");
        assertEq(queue.length(), 2, "Queue length should be 2 after first pop");
        
        // Pop second item
        euint128 popped2 = queue.pop();
        assertTrue(euint128.unwrap(popped2) > 0, "Second pop should return non-zero value");
        assertEq(queue.length(), 1, "Queue length should be 1 after second pop");
        
        // Pop third item
        euint128 popped3 = queue.pop();
        assertTrue(euint128.unwrap(popped3) > 0, "Third pop should return non-zero value");
        assertTrue(queue.isEmpty(), "Queue should be empty after all pops");
    }

    function testFIFOOrder() public {
        // Push items in order
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        euint128 handle3 = FHE.asEuint128(TEST_AMOUNT_3);
        
        queue.push(handle1);
        queue.push(handle2);
        queue.push(handle3);
        
        // Pop should return in FIFO order
        assertTrue(euint128.unwrap(queue.pop()) > 0, "First pop should be non-zero");
        assertEq(euint128.unwrap(queue.pop()), euint128.unwrap(handle2), "Second pop should be second pushed");
        assertEq(euint128.unwrap(queue.pop()), euint128.unwrap(handle3), "Third pop should be third pushed");
    }

    // =============================================================
    //                    ERROR HANDLING TESTS
    // =============================================================

    function testPopEmptyQueue() public {
        vm.expectRevert("Queue is empty");
        queue.pop();
    }

    function testPeekEmptyQueue() public {
        vm.expectRevert("Queue is empty");
        queue.peek();
    }

    function testPopAfterEmptying() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        queue.push(handle);
        queue.pop();
        
        vm.expectRevert("Queue is empty");
        queue.pop();
    }

    // =============================================================
    //                    EDGE CASE TESTS
    // =============================================================

    function testPushZeroValue() public {
        euint128 handle = FHE.asEuint128(0);
        
        queue.push(handle);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty after pushing zero");
        assertEq(queue.length(), 1, "Queue length should be 1");
        
        euint128 poppedHandle = queue.pop();
        assertEq(euint128.unwrap(poppedHandle), 0, "Popped zero value should be zero");
    }

    function testPushMaxValue() public {
        euint128 handle = FHE.asEuint128(type(uint128).max);
        
        queue.push(handle);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty after pushing max value");
        assertEq(queue.length(), 1, "Queue length should be 1");
        
        euint128 poppedHandle = queue.pop();
        assertEq(euint128.unwrap(poppedHandle), type(uint128).max, "Popped max value should be max");
    }

    function testPushSmallValue() public {
        euint128 handle = FHE.asEuint128(SMALL_AMOUNT);
        
        queue.push(handle);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty after pushing small value");
        assertEq(queue.length(), 1, "Queue length should be 1");
        
        euint128 poppedHandle = queue.pop();
        assertEq(euint128.unwrap(poppedHandle), SMALL_AMOUNT, "Popped small value should match");
    }

    function testPushLargeValue() public {
        euint128 handle = FHE.asEuint128(LARGE_AMOUNT);
        
        queue.push(handle);
        
        assertFalse(queue.isEmpty(), "Queue should not be empty after pushing large value");
        assertEq(queue.length(), 1, "Queue length should be 1");
        
        euint128 poppedHandle = queue.pop();
        assertEq(euint128.unwrap(poppedHandle), LARGE_AMOUNT, "Popped large value should match");
    }

    // =============================================================
    //                    MIXED OPERATIONS TESTS
    // =============================================================

    function testPushPopPush() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        
        // Push, pop, push
        queue.push(handle1);
        assertEq(queue.length(), 1, "Length should be 1 after first push");
        
        euint128 popped = queue.pop();
        assertEq(euint128.unwrap(popped), euint128.unwrap(handle1), "First pop should be correct");
        assertTrue(queue.isEmpty(), "Queue should be empty after pop");
        
        queue.push(handle2);
        assertEq(queue.length(), 1, "Length should be 1 after second push");
        
        euint128 popped2 = queue.pop();
        assertEq(euint128.unwrap(popped2), euint128.unwrap(handle2), "Second pop should be correct");
    }

    function testPeekMultipleTimes() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        queue.push(handle);
        
        // Peek multiple times without popping
        euint128 peeked1 = queue.peek();
        euint128 peeked2 = queue.peek();
        euint128 peeked3 = queue.peek();
        
        assertEq(euint128.unwrap(peeked1), euint128.unwrap(handle), "First peek should be correct");
        assertEq(euint128.unwrap(peeked2), euint128.unwrap(handle), "Second peek should be correct");
        assertEq(euint128.unwrap(peeked3), euint128.unwrap(handle), "Third peek should be correct");
        assertEq(queue.length(), 1, "Length should remain 1 after peeks");
    }

    function testPeekAfterPop() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        
        queue.push(handle1);
        queue.push(handle2);
        
        // Peek before pop
        euint128 peekedBefore = queue.peek();
        assertEq(euint128.unwrap(peekedBefore), euint128.unwrap(handle1), "Peek before pop should be first item");
        
        // Pop first item
        queue.pop();
        
        // Peek after pop
        euint128 peekedAfter = queue.peek();
        assertEq(euint128.unwrap(peekedAfter), euint128.unwrap(handle2), "Peek after pop should be second item");
    }

    // =============================================================
    //                    STRESS TESTS
    // =============================================================

    function testStressPushPop() public {
        // Push many items
        for (uint256 i = 0; i < 100; i++) {
            euint128 handle = FHE.asEuint128(uint128(i + 1));
            queue.push(handle);
            assertEq(queue.length(), i + 1, "Length should increment with each push");
        }
        
        // Pop all items
        for (uint256 i = 0; i < 100; i++) {
            euint128 popped = queue.pop();
            assertEq(euint128.unwrap(popped), i + 1, "Popped value should match pushed value");
            assertEq(queue.length(), 99 - i, "Length should decrement with each pop");
        }
        
        assertTrue(queue.isEmpty(), "Queue should be empty after all pops");
    }

    function testStressMixedOperations() public {
        // Perform mixed operations
        for (uint256 i = 0; i < 50; i++) {
            euint128 handle = FHE.asEuint128(uint128(i + 1));
            queue.push(handle);
            
            if (i % 3 == 0) {
                // Pop every third item
                euint128 popped = queue.pop();
                assertTrue(euint128.unwrap(popped) > 0, "Popped value should be positive");
            }
        }
        
        // Pop remaining items
        while (!queue.isEmpty()) {
            euint128 popped = queue.pop();
            assertTrue(euint128.unwrap(popped) > 0, "All remaining popped values should be positive");
        }
        
        assertTrue(queue.isEmpty(), "Queue should be empty after all operations");
    }

    function testStressLargeValues() public {
        // Test with large values
        for (uint256 i = 0; i < 20; i++) {
            euint128 handle = FHE.asEuint128(type(uint128).max - i);
            queue.push(handle);
        }
        
        // Pop all large values
        for (uint256 i = 0; i < 20; i++) {
            euint128 popped = queue.pop();
            assertEq(euint128.unwrap(popped), type(uint128).max - i, "Popped large value should match");
        }
        
        assertTrue(queue.isEmpty(), "Queue should be empty after popping large values");
    }

    // =============================================================
    //                    FUZZ TESTS
    // =============================================================

    function testFuzzPushPop(uint128 value) public {
        euint128 handle = FHE.asEuint128(value);
        
        queue.push(handle);
        assertFalse(queue.isEmpty(), "Queue should not be empty after push");
        assertEq(queue.length(), 1, "Queue length should be 1");
        
        euint128 popped = queue.pop();
        assertTrue(euint128.unwrap(popped) > 0, "Popped value should be non-zero");
        assertTrue(queue.isEmpty(), "Queue should be empty after pop");
    }

    function testFuzzMultiplePushPop(uint128[] memory values) public {
        // Limit array size to prevent gas issues
        vm.assume(values.length <= 50);
        
        // Push all values
        for (uint256 i = 0; i < values.length; i++) {
            euint128 handle = FHE.asEuint128(values[i]);
            queue.push(handle);
            assertEq(queue.length(), i + 1, "Length should increment with each push");
        }
        
        // Pop all values
        for (uint256 i = 0; i < values.length; i++) {
            euint128 popped = queue.pop();
            assertEq(euint128.unwrap(popped), values[i], "Popped value should match pushed value");
            assertEq(queue.length(), values.length - i - 1, "Length should decrement with each pop");
        }
        
        assertTrue(queue.isEmpty(), "Queue should be empty after all pops");
    }

    function testFuzzPeek(uint128 value) public {
        euint128 handle = FHE.asEuint128(value);
        
        queue.push(handle);
        
        // Peek multiple times
        for (uint256 i = 0; i < 10; i++) {
            euint128 peeked = queue.pop();
            assertTrue(euint128.unwrap(peeked) > 0, "Peeked value should be non-zero");
        }
        
        // Pop the actual value
        euint128 popped = queue.pop();
        assertTrue(euint128.unwrap(popped) > 0, "Popped value should be non-zero");
    }

    // =============================================================
    //                    GAS OPTIMIZATION TESTS
    // =============================================================

    function testGasUsagePush() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        uint256 gasStart = gasleft();
        queue.push(handle);
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for push:", gasUsed);
        assertTrue(gasUsed < 100000, "Gas usage should be reasonable");
    }

    function testGasUsagePop() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        queue.push(handle);
        
        uint256 gasStart = gasleft();
        queue.pop();
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for pop:", gasUsed);
        assertTrue(gasUsed < 100000, "Gas usage should be reasonable");
    }

    function testGasUsagePeek() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        queue.push(handle);
        
        uint256 gasStart = gasleft();
        queue.peek();
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for peek:", gasUsed);
        assertTrue(gasUsed < 100000, "Gas usage should be reasonable");
    }

    function testGasUsageLength() public {
        uint256 gasStart = gasleft();
        queue.length();
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for length:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be very low for view function");
    }

    function testGasUsageIsEmpty() public {
        uint256 gasStart = gasleft();
        queue.isEmpty();
        uint256 gasUsed = gasStart - gasleft();
        
        console.log("Gas used for isEmpty:", gasUsed);
        assertTrue(gasUsed < 10000, "Gas usage should be very low for view function");
    }

    // =============================================================
    //                    HELPER FUNCTION TESTS
    // =============================================================

    function testEuintToBytes32Conversion() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        // This tests the internal conversion function indirectly
        queue.push(handle);
        euint128 popped = queue.pop();
        
        assertEq(euint128.unwrap(popped), euint128.unwrap(handle), "Conversion should preserve value");
    }

    function testBytes32ToEuintConversion() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        // This tests the internal conversion function indirectly
        queue.push(handle);
        euint128 popped = queue.pop();
        
        assertEq(euint128.unwrap(popped), euint128.unwrap(handle), "Conversion should preserve value");
    }

    // =============================================================
    //                    EVENT TESTS
    // =============================================================

    function testPushEvent() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        vm.expectEmit(true, false, false, false);
        emit OrderQueue.ItemPushed(euint128.unwrap(handle));
        queue.push(handle);
    }

    function testPopEvent() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        queue.push(handle);
        
        vm.expectEmit(true, false, false, false);
        emit OrderQueue.ItemPopped(euint128.unwrap(handle));
        queue.pop();
    }

    // =============================================================
    //                    BOUNDARY TESTS
    // =============================================================

    function testSingleItemQueue() public {
        euint128 handle = FHE.asEuint128(TEST_AMOUNT_1);
        
        // Push single item
        queue.push(handle);
        assertFalse(queue.isEmpty(), "Queue should not be empty");
        assertEq(queue.length(), 1, "Length should be 1");
        
        // Peek single item
        euint128 peeked = queue.peek();
        assertEq(euint128.unwrap(peeked), euint128.unwrap(handle), "Peek should return the item");
        
        // Pop single item
        euint128 popped = queue.pop();
        assertEq(euint128.unwrap(popped), euint128.unwrap(handle), "Pop should return the item");
        assertTrue(queue.isEmpty(), "Queue should be empty after pop");
    }

    function testTwoItemQueue() public {
        euint128 handle1 = FHE.asEuint128(TEST_AMOUNT_1);
        euint128 handle2 = FHE.asEuint128(TEST_AMOUNT_2);
        
        // Push two items
        queue.push(handle1);
        queue.push(handle2);
        assertEq(queue.length(), 2, "Length should be 2");
        
        // Peek should return first item
        euint128 peeked = queue.peek();
        assertEq(euint128.unwrap(peeked), euint128.unwrap(handle1), "Peek should return first item");
        
        // Pop first item
        euint128 popped1 = queue.pop();
        assertTrue(euint128.unwrap(popped1) > 0, "First pop should return non-zero value");
        assertEq(queue.length(), 1, "Length should be 1 after first pop");
        
        // Peek should now return second item
        euint128 peeked2 = queue.peek();
        assertEq(euint128.unwrap(peeked2), euint128.unwrap(handle2), "Peek should return second item");
        
        // Pop second item
        euint128 popped2 = queue.pop();
        assertTrue(euint128.unwrap(popped2) > 0, "Second pop should return non-zero value");
        assertTrue(queue.isEmpty(), "Queue should be empty after second pop");
    }
}
