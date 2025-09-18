// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {TaskAVSRegistrarBase} from "@eigenlayer-middleware/src/avs/task/TaskAVSRegistrarBase.sol";

/**
 * @title VaultSwapServiceManager
 * @notice EigenLayer L1 service manager for VaultSwap AVS
 * @dev This is a CONNECTOR contract that manages EigenLayer integration only.
 * The actual VaultSwap business logic remains in the main VaultSwapHook contract.
 * This contract handles:
 * - Operator registration with EigenLayer
 * - Staking management
 * - Task validation (delegates to L2 hook for actual VaultSwap logic)
 */
contract VaultSwapServiceManager is TaskAVSRegistrarBase {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Address of the main VaultSwap Hook contract on L2
    address public immutable vaultSwapHookL2;
    
    /// @notice Minimum stake required for VaultSwap operators
    uint256 public constant MINIMUM_VAULTSWAP_STAKE = 10 ether;
    
    /// @notice Supported chains for cross-chain VaultSwap operations
    mapping(uint256 => bool) public supportedChains;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event VaultSwapOperatorRegistered(address indexed operator, bytes32 indexed operatorId);
    event VaultSwapOperatorDeregistered(address indexed operator, bytes32 indexed operatorId);
    event VaultSwapHookUpdated(address indexed oldHook, address indexed newHook);
    event ChainSupportUpdated(uint256 indexed chainId, bool supported);
    
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Constructor that passes parameters to parent TaskAVSRegistrarBase
     * @param _allocationManager The AllocationManager contract address
     * @param _keyRegistrar The KeyRegistrar contract address
     * @param _permissionController The PermissionController contract address
     * @param _vaultSwapHookL2 The address of the main VaultSwap Hook on L2
     */
    constructor(
        IAllocationManager _allocationManager,
        IKeyRegistrar _keyRegistrar,
        IPermissionController _permissionController,
        address _vaultSwapHookL2
    ) TaskAVSRegistrarBase(_allocationManager, _keyRegistrar, _permissionController) {
        require(_vaultSwapHookL2 != address(0), "Invalid L2 hook address");
        vaultSwapHookL2 = _vaultSwapHookL2;
        
        // Initialize supported chains
        _initializeSupportedChains();
    }

    /*//////////////////////////////////////////////////////////////
                              INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Initializer that calls parent initializer
     * @param _avs The address of the AVS
     * @param _owner The owner of the contract
     * @param _initialConfig The initial AVS configuration
     */
    function initialize(address _avs, address _owner, AvsConfig memory _initialConfig) external initializer {
        __TaskAVSRegistrarBase_init(_avs, _owner, _initialConfig);
    }

    /*//////////////////////////////////////////////////////////////
                         VAULTSWAP-SPECIFIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register an operator specifically for VaultSwap tasks
     * @dev This extends the base registration with VaultSwap-specific requirements
     * @param operator The operator address to register
     * @param operatorSignature The operator's signature for EigenLayer
     */
    function registerVaultSwapOperator(
        address operator,
        bytes calldata operatorSignature
    ) external payable {
        require(msg.value >= MINIMUM_VAULTSWAP_STAKE, "Insufficient stake for VaultSwap operations");
        
        // Call parent registration logic (handles EigenLayer integration)
        _registerOperator(operator, operatorSignature);
        
        bytes32 operatorId = keccak256(abi.encodePacked(operator, block.timestamp));
        emit VaultSwapOperatorRegistered(operator, operatorId);
    }

    /**
     * @notice Deregister an operator from VaultSwap tasks
     * @param operator The operator address to deregister
     */
    function deregisterVaultSwapOperator(address operator) external {
        // Call parent deregistration logic
        _deregisterOperator(operator);
        
        bytes32 operatorId = keccak256(abi.encodePacked(operator, block.timestamp));
        emit VaultSwapOperatorDeregistered(operator, operatorId);
    }

    /**
     * @notice Check if an operator meets VaultSwap requirements
     * @param operator The operator address to check
     * @return Whether the operator is qualified for VaultSwap operations
     */
    function isVaultSwapOperatorQualified(address operator) external view returns (bool) {
        // Check base registration status and add VaultSwap-specific checks
        return _isRegistered(operator) && _getOperatorStake(operator) >= MINIMUM_VAULTSWAP_STAKE;
    }

    /**
     * @notice Get the L2 VaultSwap Hook contract address
     * @return The address of the main VaultSwap logic contract
     */
    function getVaultSwapHook() external view returns (address) {
        return vaultSwapHookL2;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Internal function to check operator registration
     * @param operator The operator address
     * @return Whether the operator is registered
     */
    function _isRegistered(address operator) internal view returns (bool) {
        // Implementation depends on TaskAVSRegistrarBase structure
        // This is a placeholder - actual implementation would check registration status
        return true; // TODO: Implement based on TaskAVSRegistrarBase
    }

    /**
     * @notice Internal function to get operator stake
     * @param operator The operator address
     * @return The operator's stake amount
     */
    function _getOperatorStake(address operator) internal view returns (uint256) {
        // Implementation depends on TaskAVSRegistrarBase structure  
        // This is a placeholder - actual implementation would return stake
        return MINIMUM_VAULTSWAP_STAKE; // TODO: Implement based on TaskAVSRegistrarBase
    }
    
    /**
     * @notice Initialize supported chains for VaultSwap operations
     */
    function _initializeSupportedChains() internal {
        supportedChains[1] = true;     // Ethereum
        supportedChains[42161] = true; // Arbitrum
        supportedChains[10] = true;    // Optimism
        supportedChains[137] = true;   // Polygon
        supportedChains[8453] = true;  // Base
    }
    
    /**
     * @notice Check if a chain is supported for cross-chain operations
     * @param chainId The chain ID to check
     * @return Whether the chain is supported
     */
    function isChainSupported(uint256 chainId) external view returns (bool) {
        return supportedChains[chainId];
    }
    
    /**
     * @notice Get all supported chain IDs
     * @return Array of supported chain IDs
     */
    function getSupportedChains() external pure returns (uint256[] memory) {
        uint256[] memory chains = new uint256[](5);
        chains[0] = 1;     // Ethereum
        chains[1] = 42161; // Arbitrum
        chains[2] = 10;    // Optimism
        chains[3] = 137;   // Polygon
        chains[4] = 8453;  // Base
        return chains;
    }

    /**
     * @notice Update chain support status (only owner)
     * @param chainId The chain ID to update
     * @param supported Whether the chain should be supported
     */
    function updateChainSupport(uint256 chainId, bool supported) external onlyOwner {
        supportedChains[chainId] = supported;
        emit ChainSupportUpdated(chainId, supported);
    }
}
