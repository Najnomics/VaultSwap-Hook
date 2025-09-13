// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {PoolManager} from "@uniswap/v4-core/src/PoolManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {CurrencyLibrary, Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {FHE} from "@fhenixprotocol/cofhe-contracts/FHE.sol";

import {VaultSwapHook} from "../src/VaultSwapHook.sol";

/**
 * @title DeployVaultSwapHook
 * @notice Deployment script for VaultSwapHook with proper configuration
 * @dev Handles deployment across different networks with appropriate settings
 */
contract DeployVaultSwapHook is Script {
    using CurrencyLibrary for Currency;

    // Network configurations
    struct NetworkConfig {
        address poolManager;
        address fheGateway;
        uint256 deployerPrivateKey;
        bool verifyContracts;
    }

    // Deployment results
    struct DeploymentResult {
        address hookAddress;
        uint160 hookFlags;
        bytes32 salt;
        address poolManager;
        uint256 blockNumber;
        bytes32 txHash;
    }

    // Network configurations
    mapping(uint256 => NetworkConfig) public networkConfigs;
    
    // Events
    event VaultSwapHookDeployed(
        address indexed hookAddress,
        address indexed poolManager,
        uint160 hookFlags,
        bytes32 salt
    );
    
    event PoolInitialized(
        address indexed token0,
        address indexed token1,
        uint24 fee,
        address poolManager
    );

    modifier onlySupportedNetwork() {
        require(networkConfigs[block.chainid].poolManager != address(0), "Unsupported network");
        _;
    }

    constructor() {
        _setupNetworkConfigs();
    }

    /**
     * @notice Main deployment function
     * @dev Deploys VaultSwapHook with CREATE2 for deterministic addresses
     */
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DeploymentResult memory result = deployVaultSwapHook();
        
        // Log deployment results
        console.log("=== VaultSwapHook Deployment Results ===");
        console.log("Hook Address:", result.hookAddress);
        console.log("Pool Manager:", result.poolManager);
        console.log("Hook Flags:", result.hookFlags);
        console.log("Salt:", vm.toString(result.salt));
        console.log("Block Number:", result.blockNumber);
        console.log("Transaction Hash:", vm.toString(result.txHash));

        vm.stopBroadcast();

        // Save deployment artifacts
        _saveDeploymentArtifacts(result);
        
        // Verify contracts if configured
        if (networkConfigs[block.chainid].verifyContracts) {
            _verifyContracts(result);
        }
    }

    /**
     * @notice Deploy VaultSwapHook with CREATE2
     * @return result Deployment result containing all relevant information
     */
    function deployVaultSwapHook() public onlySupportedNetwork returns (DeploymentResult memory result) {
        NetworkConfig memory config = networkConfigs[block.chainid];
        
        // Calculate hook flags
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG
        );

        // Generate salt for CREATE2
        bytes32 salt = _generateSalt();
        
        // Deploy hook with CREATE2
        bytes memory creationCode = abi.encodePacked(
            type(VaultSwapHook).creationCode,
            abi.encode(config.poolManager)
        );
        
        address hookAddress = _create2Deploy(creationCode, salt, flags);
        
        // Verify deployment
        require(hookAddress != address(0), "Hook deployment failed");
        require(hookAddress == address(flags), "Hook address mismatch");

        // Initialize FHE if needed
        _initializeFHE(hookAddress, config.fheGateway);

        result = DeploymentResult({
            hookAddress: hookAddress,
            hookFlags: flags,
            salt: salt,
            poolManager: config.poolManager,
            blockNumber: block.number,
            txHash: tx.origin == address(0) ? bytes32(0) : blockhash(block.number - 1)
        });

        emit VaultSwapHookDeployed(hookAddress, config.poolManager, flags, salt);
    }

    /**
     * @notice Deploy hook to a specific address using CREATE2
     * @param creationCode Contract creation code
     * @param salt CREATE2 salt
     * @param targetAddress Target deployment address
     * @return deployedAddress Address of deployed contract
     */
    function _create2Deploy(
        bytes memory creationCode,
        bytes32 salt,
        uint160 targetAddress
    ) internal returns (address deployedAddress) {
        // Calculate expected address
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(creationCode)
            )
        );
        address expectedAddress = address(uint160(uint256(hash)));
        
        // Ensure the address matches our target
        require(expectedAddress == address(targetAddress), "Address mismatch");
        
        assembly {
            deployedAddress := create2(0, add(creationCode, 0x20), mload(creationCode), salt)
        }
        
        require(deployedAddress == expectedAddress, "CREATE2 deployment failed");
    }

    /**
     * @notice Generate deterministic salt for CREATE2
     * @return salt Bytes32 salt value
     */
    function _generateSalt() internal view returns (bytes32 salt) {
        // Use block chainid and a fixed string for deterministic deployment
        salt = keccak256(abi.encodePacked("VaultSwapHook", block.chainid, "v1.0.0"));
    }

    /**
     * @notice Initialize FHE gateway connection
     * @param hookAddress Address of deployed hook
     * @param fheGateway Address of FHE gateway (if applicable)
     */
    function _initializeFHE(address hookAddress, address fheGateway) internal {
        if (fheGateway != address(0)) {
            // Initialize FHE connection
            // This would depend on the specific FHE implementation
            console.log("Initializing FHE gateway connection for hook:", hookAddress);
            console.log("FHE Gateway:", fheGateway);
        }
    }

    /**
     * @notice Setup network configurations
     */
    function _setupNetworkConfigs() internal {
        // Ethereum Mainnet
        networkConfigs[1] = NetworkConfig({
            poolManager: address(0), // To be updated with actual mainnet address
            fheGateway: address(0),  // To be updated with FHE gateway address
            deployerPrivateKey: 0,
            verifyContracts: true
        });

        // Ethereum Sepolia Testnet
        networkConfigs[11155111] = NetworkConfig({
            poolManager: address(0), // To be updated with testnet address
            fheGateway: address(0),  // To be updated with FHE gateway address
            deployerPrivateKey: 0,
            verifyContracts: true
        });

        // Fhenix Testnet (example)
        networkConfigs[42069] = NetworkConfig({
            poolManager: address(0), // To be updated with Fhenix testnet address
            fheGateway: address(0),  // To be updated with FHE gateway address
            deployerPrivateKey: 0,
            verifyContracts: false // May not support verification
        });

        // Local development
        networkConfigs[31337] = NetworkConfig({
            poolManager: address(0), // Will be set during local deployment
            fheGateway: address(0),  // Local FHE setup
            deployerPrivateKey: 0,
            verifyContracts: false
        });
    }

    /**
     * @notice Save deployment artifacts to file
     * @param result Deployment result to save
     */
    function _saveDeploymentArtifacts(DeploymentResult memory result) internal {
        string memory deploymentJson = string(abi.encodePacked(
            '{\n',
            '  "hookAddress": "', vm.toString(result.hookAddress), '",\n',
            '  "poolManager": "', vm.toString(result.poolManager), '",\n',
            '  "hookFlags": "', vm.toString(result.hookFlags), '",\n',
            '  "salt": "', vm.toString(result.salt), '",\n',
            '  "blockNumber": ', vm.toString(result.blockNumber), ',\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), ',\n',
            '  "deployer": "', vm.toString(msg.sender), '"\n',
            '}'
        ));

        string memory fileName = string(abi.encodePacked(
            "deployments/",
            vm.toString(block.chainid),
            "_VaultSwapHook.json"
        ));

        vm.writeFile(fileName, deploymentJson);
        console.log("Deployment artifacts saved to:", fileName);
    }

    /**
     * @notice Verify deployed contracts
     * @param result Deployment result
     */
    function _verifyContracts(DeploymentResult memory result) internal {
        console.log("Starting contract verification...");
        
        // Construct verification command
        string[] memory verifyCmd = new string[](7);
        verifyCmd[0] = "forge";
        verifyCmd[1] = "verify-contract";
        verifyCmd[2] = vm.toString(result.hookAddress);
        verifyCmd[3] = "src/VaultSwapHook.sol:VaultSwapHook";
        verifyCmd[4] = "--constructor-args";
        verifyCmd[5] = abi.encode(result.poolManager);
        verifyCmd[6] = "--watch";

        // Note: In production, this would use the appropriate API key and explorer
        console.log("Run the following command to verify the contract:");
        console.log("forge verify-contract", vm.toString(result.hookAddress), 
                   "src/VaultSwapHook.sol:VaultSwapHook --constructor-args", 
                   vm.toString(abi.encode(result.poolManager)));
    }

    /**
     * @notice Deploy and initialize a test pool (for development)
     * @param hookAddress Address of deployed hook
     * @param token0 Address of token0
     * @param token1 Address of token1
     * @param fee Pool fee
     * @return poolKey Initialized pool key
     */
    function deployTestPool(
        address hookAddress,
        address token0,
        address token1,
        uint24 fee
    ) external returns (PoolKey memory poolKey) {
        require(hookAddress != address(0), "Invalid hook address");
        require(token0 < token1, "Token addresses not sorted");

        NetworkConfig memory config = networkConfigs[block.chainid];
        IPoolManager poolManager = IPoolManager(config.poolManager);

        poolKey = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: fee,
            tickSpacing: 60,
            hooks: IHooks(hookAddress)
        });

        // Initialize pool
        poolManager.initialize(poolKey, 79228162514264337593543950336, ""); // SQRT_RATIO_1_1

        emit PoolInitialized(token0, token1, fee, address(poolManager));
        
        console.log("Test pool initialized:");
        console.log("Token0:", token0);
        console.log("Token1:", token1);
        console.log("Fee:", fee);
        console.log("Hook:", hookAddress);
    }

    /**
     * @notice Update network configuration
     * @param chainId Chain ID to update
     * @param poolManager Pool manager address
     * @param fheGateway FHE gateway address
     * @param verifyContracts Whether to verify contracts
     */
    function updateNetworkConfig(
        uint256 chainId,
        address poolManager,
        address fheGateway,
        bool verifyContracts
    ) external {
        networkConfigs[chainId] = NetworkConfig({
            poolManager: poolManager,
            fheGateway: fheGateway,
            deployerPrivateKey: 0,
            verifyContracts: verifyContracts
        });
        
        console.log("Updated network config for chain ID:", chainId);
    }

    /**
     * @notice Get network configuration
     * @param chainId Chain ID to query
     * @return config Network configuration
     */
    function getNetworkConfig(uint256 chainId) external view returns (NetworkConfig memory config) {
        return networkConfigs[chainId];
    }

    /**
     * @notice Calculate hook address for given salt
     * @param salt CREATE2 salt
     * @param poolManager Pool manager address
     * @return hookAddress Calculated hook address
     */
    function calculateHookAddress(
        bytes32 salt,
        address poolManager
    ) external view returns (address hookAddress) {
        bytes memory creationCode = abi.encodePacked(
            type(VaultSwapHook).creationCode,
            abi.encode(poolManager)
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(creationCode)
            )
        );

        hookAddress = address(uint160(uint256(hash)));
    }

    /**
     * @notice Emergency deployment with custom salt
     * @param customSalt Custom salt for deployment
     * @return result Deployment result
     */
    function emergencyDeploy(bytes32 customSalt) external returns (DeploymentResult memory result) {
        NetworkConfig memory config = networkConfigs[block.chainid];
        require(config.poolManager != address(0), "Network not configured");

        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | 
            Hooks.AFTER_SWAP_FLAG |
            Hooks.BEFORE_INITIALIZE_FLAG |
            Hooks.AFTER_INITIALIZE_FLAG
        );

        bytes memory creationCode = abi.encodePacked(
            type(VaultSwapHook).creationCode,
            abi.encode(config.poolManager)
        );

        address hookAddress = _create2Deploy(creationCode, customSalt, flags);

        result = DeploymentResult({
            hookAddress: hookAddress,
            hookFlags: flags,
            salt: customSalt,
            poolManager: config.poolManager,
            blockNumber: block.number,
            txHash: bytes32(0)
        });

        emit VaultSwapHookDeployed(hookAddress, config.poolManager, flags, customSalt);
    }
}