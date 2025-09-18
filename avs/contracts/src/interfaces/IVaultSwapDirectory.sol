// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title IVaultSwapDirectory
 * @notice Interface for VaultSwap AVS directory management
 * @dev Provides standardized interface for VaultSwap AVS operations
 */
interface IVaultSwapDirectory {
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultSwapAVSRegistered(bytes32 indexed avsId, address indexed avsAddress);
    event VaultSwapAVSDeregistered(bytes32 indexed avsId);
    event VaultSwapOperatorAdded(bytes32 indexed avsId, address indexed operator);
    event VaultSwapOperatorRemoved(bytes32 indexed avsId, address indexed operator);
    
    /*//////////////////////////////////////////////////////////////
                                FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Register a new VaultSwap AVS
     * @param avsId The unique identifier for the AVS
     * @param avsAddress The address of the AVS contract
     * @param metadataURI URI containing AVS metadata
     */
    function registerVaultSwapAVS(
        bytes32 avsId,
        address avsAddress,
        string calldata metadataURI
    ) external;
    
    /**
     * @notice Deregister a VaultSwap AVS
     * @param avsId The unique identifier for the AVS
     */
    function deregisterVaultSwapAVS(bytes32 avsId) external;
    
    /**
     * @notice Add an operator to a VaultSwap AVS
     * @param avsId The unique identifier for the AVS
     * @param operator The operator address to add
     */
    function addVaultSwapOperator(bytes32 avsId, address operator) external;
    
    /**
     * @notice Remove an operator from a VaultSwap AVS
     * @param avsId The unique identifier for the AVS
     * @param operator The operator address to remove
     */
    function removeVaultSwapOperator(bytes32 avsId, address operator) external;
    
    /**
     * @notice Check if an AVS is registered
     * @param avsId The unique identifier for the AVS
     * @return Whether the AVS is registered
     */
    function isVaultSwapAVSRegistered(bytes32 avsId) external view returns (bool);
    
    /**
     * @notice Get AVS address by ID
     * @param avsId The unique identifier for the AVS
     * @return The AVS contract address
     */
    function getVaultSwapAVSAddress(bytes32 avsId) external view returns (address);
    
    /**
     * @notice Get all registered VaultSwap AVS IDs
     * @return Array of registered AVS IDs
     */
    function getAllVaultSwapAVSIds() external view returns (bytes32[] memory);
    
    /**
     * @notice Get operators for a specific AVS
     * @param avsId The unique identifier for the AVS
     * @return Array of operator addresses
     */
    function getVaultSwapAVSOperators(bytes32 avsId) external view returns (address[] memory);
    
    /**
     * @notice Check if an operator is registered for an AVS
     * @param avsId The unique identifier for the AVS
     * @param operator The operator address to check
     * @return Whether the operator is registered for the AVS
     */
    function isVaultSwapOperatorRegistered(bytes32 avsId, address operator) external view returns (bool);
}
