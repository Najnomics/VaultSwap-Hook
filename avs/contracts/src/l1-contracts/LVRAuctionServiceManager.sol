// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {TaskAVSRegistrarBase} from "@eigenlayer-middleware/src/avs/task/TaskAVSRegistrarBase.sol";

/**
 * @title LVRAuctionServiceManager
 * @notice EigenLayer L1 service manager for LVR Auction AVS
 * @dev This is a CONNECTOR contract that manages EigenLayer integration only.
 * The actual LVR auction business logic remains in the main LVRAuctionHook contract.
 * This contract handles:
 * - Operator registration with EigenLayer
 * - Staking management
 * - Task validation (delegates to L2 hook for actual auction logic)
 */
contract LVRAuctionServiceManager is TaskAVSRegistrarBase {
    
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/
    
    /// @notice Address of the main LVR Auction Hook contract on L2
    address public immutable lvrAuctionHookL2;
    
    /// @notice Minimum stake required for LVR auction operators
    uint256 public constant MINIMUM_LVR_STAKE = 10 ether;
    
    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/
    
    event LVROperatorRegistered(address indexed operator, bytes32 indexed operatorId);
    event LVROperatorDeregistered(address indexed operator, bytes32 indexed operatorId);
    event LVRAuctionHookUpdated(address indexed oldHook, address indexed newHook);
    
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @dev Constructor that passes parameters to parent TaskAVSRegistrarBase
     * @param _allocationManager The AllocationManager contract address
     * @param _keyRegistrar The KeyRegistrar contract address
     * @param _permissionController The PermissionController contract address
     * @param _lvrAuctionHookL2 The address of the main LVR Auction Hook on L2
     */
    constructor(
        IAllocationManager _allocationManager,
        IKeyRegistrar _keyRegistrar,
        IPermissionController _permissionController,
        address _lvrAuctionHookL2
    ) TaskAVSRegistrarBase(_allocationManager, _keyRegistrar, _permissionController) {
        require(_lvrAuctionHookL2 != address(0), "Invalid L2 hook address");
        lvrAuctionHookL2 = _lvrAuctionHookL2;
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
                         LVR-SPECIFIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Register an operator specifically for LVR auction tasks
     * @dev This extends the base registration with LVR-specific requirements
     * @param operator The operator address to register
     * @param operatorSignature The operator's signature for EigenLayer
     */
    function registerLVROperator(
        address operator,
        bytes calldata operatorSignature
    ) external payable {
        require(msg.value >= MINIMUM_LVR_STAKE, "Insufficient stake for LVR operations");
        
        // Call parent registration logic (handles EigenLayer integration)
        _registerOperator(operator, operatorSignature);
        
        bytes32 operatorId = keccak256(abi.encodePacked(operator, block.timestamp));
        emit LVROperatorRegistered(operator, operatorId);
    }

    /**
     * @notice Deregister an operator from LVR auction tasks
     * @param operator The operator address to deregister
     */
    function deregisterLVROperator(address operator) external {
        // Call parent deregistration logic
        _deregisterOperator(operator);
        
        bytes32 operatorId = keccak256(abi.encodePacked(operator, block.timestamp));
        emit LVROperatorDeregistered(operator, operatorId);
    }

    /**
     * @notice Check if an operator meets LVR auction requirements
     * @param operator The operator address to check
     * @return Whether the operator is qualified for LVR auctions
     */
    function isLVROperatorQualified(address operator) external view returns (bool) {
        // Check base registration status and add LVR-specific checks
        return _isRegistered(operator) && _getOperatorStake(operator) >= MINIMUM_LVR_STAKE;
    }

    /**
     * @notice Get the L2 LVR Auction Hook contract address
     * @return The address of the main auction logic contract
     */
    function getLVRAuctionHook() external view returns (address) {
        return lvrAuctionHookL2;
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
        return MINIMUM_LVR_STAKE; // TODO: Implement based on TaskAVSRegistrarBase
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
}