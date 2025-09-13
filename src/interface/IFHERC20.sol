// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {InEuint128, euint128} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

/**
 * @title IFHERC20
 * @notice Interface for FHE-enabled ERC20 tokens
 * @dev Defines the basic interface for tokens that support FHE operations
 */
interface IFHERC20 {
    /**
     * @notice Mint encrypted tokens to a user
     * @param user Address to mint tokens to
     * @param amount Encrypted amount to mint
     */
    function mintEncrypted(address user, InEuint128 memory amount) external;
    
    /**
     * @notice Transfer encrypted tokens
     * @param to Address to transfer to
     * @param amount Encrypted amount to transfer
     * @return success Whether the transfer was successful
     */
    function transferEncrypted(address to, InEuint128 memory amount) external returns (bool success);
    
    /**
     * @notice Get encrypted balance of a user
     * @param user Address to check balance for
     * @return balance Encrypted balance
     */
    function encBalances(address user) external view returns (euint128 balance);
}