// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

/**
 * @title OrderQueue
 * @notice FHE-compatible queue implementation for encrypted order handles
 * @dev Uses OpenZeppelin DoubleEndedQueue for efficient storage
 */
contract OrderQueue {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    // =============================================================
    //                           EVENTS
    // =============================================================

    event ItemPushed(uint256 indexed handle);
    event ItemPopped(uint256 indexed handle);
    event QueueCleared();

    // =============================================================
    //                           STORAGE
    // =============================================================

    /// @notice The queue storage
    DoubleEndedQueue.Bytes32Deque private queue;

    // =============================================================
    //                    QUEUE OPERATIONS
    // =============================================================

    /**
     * @notice Push an encrypted value to the back of the queue
     * @param handle Encrypted value handle to push
     */
    function push(euint128 handle) external {
        DoubleEndedQueue.pushBack(queue, euintToBytes32(handle));
        emit ItemPushed(euint128.unwrap(handle));
    }

    /**
     * @notice Pop an encrypted value from the front of the queue
     * @return handle The encrypted value handle that was popped
     */
    function pop() external returns (euint128) {
        if (queue.length() == 0) revert("Queue is empty");
        
        bytes32 item = DoubleEndedQueue.popFront(queue);
        euint128 handle = bytes32ToEuint(item);
        emit ItemPopped(euint128.unwrap(handle));
        return handle;
    }

    /**
     * @notice Peek at the front of the queue without removing
     * @return handle The encrypted value handle at the front
     */
    function peek() external view returns (euint128) {
        if (queue.length() == 0) revert("Queue is empty");
        
        bytes32 item = DoubleEndedQueue.front(queue);
        return bytes32ToEuint(item);
    }

    /**
     * @notice Get the length of the queue
     * @return length Current queue length
     */
    function length() external view returns (uint256) {
        return queue.length();
    }

    /**
     * @notice Check if the queue is empty
     * @return empty Whether the queue is empty
     */
    function isEmpty() external view returns (bool) {
        return queue.length() == 0;
    }

    /**
     * @notice Get the size of the queue (alias for length)
     * @return size Current queue size
     */
    function size() external view returns (uint256) {
        return queue.length();
    }

    // =============================================================
    //                    HELPER FUNCTIONS
    // =============================================================

    /**
     * @notice Convert euint128 to bytes32 for storage
     * @param value The encrypted value to convert
     * @return The bytes32 representation
     */
    function euintToBytes32(euint128 value) internal pure returns (bytes32) {
        return bytes32(euint128.unwrap(value));
    }

    /**
     * @notice Convert bytes32 to euint128 from storage
     * @param value The bytes32 value to convert
     * @return The euint128 representation
     */
    function bytes32ToEuint(bytes32 value) internal pure returns (euint128) {
        return euint128.wrap(uint128(uint256(value)));
    }
}