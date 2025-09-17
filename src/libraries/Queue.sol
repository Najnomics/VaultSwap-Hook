// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {euint128, FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title Queue
 * @notice Generic queue implementation for order processing
 * @dev Stub implementation - actual queue logic is in OrderQueue
 */
contract Queue {
    euint128[] private items;
    uint256 private front;
    
    function enqueue(euint128 item) external {
        items.push(item);
    }
    
    function dequeue() external returns (euint128) {
        require(front < items.length, "Queue empty");
        return items[front++];
    }
    
    function isEmpty() external view returns (bool) {
        return front >= items.length;
    }
    
    function size() external view returns (uint256) {
        return items.length - front;
    }
}