// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title DeployPermit2
 * @notice Utility for deploying Permit2 in test environments
 * @dev Stub implementation for test compatibility
 */
contract DeployPermit2 {
    address public constant PERMIT2_ADDRESS = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    
    function deployPermit2() external pure returns (address) {
        return PERMIT2_ADDRESS;
    }
    
    function getPermit2Address() external pure returns (address) {
        return PERMIT2_ADDRESS;
    }
}