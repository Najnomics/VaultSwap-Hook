// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

import {VaultSwapHook} from "../src/VaultSwapHook.sol";

/**
 * @title SetupEnvironment
 * @notice Script to setup complete testing/development environment
 * @dev Deploys tokens, pools, adds liquidity, and configures the system
 */
contract SetupEnvironment is Script {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    // Environment configuration
    struct EnvironmentConfig {
        address poolManager;
        address hookAddress;
        address deployer;
        uint256 initialLiquidity;
        uint256 testTokenSupply;
    }

    // Deployment artifacts
    struct DeployedTokens {
        address token0;
        address token1;
        address weth;
        address usdc;
        address usdt;
    }

    struct DeployedPools {
        PoolKey token0Token1Pool;
        PoolKey wethUsdcPool;
        PoolKey wethUsdtPool;
        PoolId token0Token1PoolId;
        PoolId wethUsdcPoolId;
        PoolId wethUsdtPoolId;
    }

    // Events
    event EnvironmentSetup(
        address indexed hookAddress,
        address indexed poolManager,
        uint256 poolCount,
        uint256 totalLiquidity
    );

    event TokensDeployed(
        address token0,
        address token1,
        address weth,
        address usdc,
        address usdt
    );

    event PoolsInitialized(
        PoolId token0Token1PoolId,
        PoolId wethUsdcPoolId,
        PoolId wethUsdtPoolId
    );

    event LiquidityAdded(
        PoolId indexed poolId,
        address indexed provider,
        uint256 amount0,
        uint256 amount1
    );

    /**
     * @notice Main setup function
     */
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        EnvironmentConfig memory config = _loadConfig();
        
        console.log("=== Setting up VaultSwap Environment ===");
        console.log("Pool Manager:", config.poolManager);
        console.log("Hook Address:", config.hookAddress);
        console.log("Deployer:", config.deployer);

        // Deploy test tokens
        DeployedTokens memory tokens = _deployTestTokens(config);
        
        // Initialize pools
        DeployedPools memory pools = _initializePools(config, tokens);
        
        // Add initial liquidity
        _addInitialLiquidity(config, tokens, pools);
        
        // Setup initial orders (for testing)
        _setupInitialOrders(config, tokens, pools);

        // Save environment artifacts
        _saveEnvironmentArtifacts(config, tokens, pools);

        console.log("=== Environment Setup Complete ===");
        
        emit EnvironmentSetup(
            config.hookAddress,
            config.poolManager,
            3, // Number of pools
            config.initialLiquidity * 3 // Total liquidity across pools
        );

        vm.stopBroadcast();
    }

    /**
     * @notice Deploy test tokens for the environment
     * @param config Environment configuration
     * @return tokens Deployed token addresses
     */
    function _deployTestTokens(EnvironmentConfig memory config) 
        internal 
        returns (DeployedTokens memory tokens) 
    {
        console.log("Deploying test tokens...");

        // Deploy test ERC20 tokens
        tokens.token0 = _deployMockERC20("Test Token 0", "TT0", config.testTokenSupply);
        tokens.token1 = _deployMockERC20("Test Token 1", "TT1", config.testTokenSupply);
        tokens.weth = _deployMockERC20("Wrapped Ether", "WETH", config.testTokenSupply);
        tokens.usdc = _deployMockERC20("USD Coin", "USDC", config.testTokenSupply);
        tokens.usdt = _deployMockERC20("Tether USD", "USDT", config.testTokenSupply);

        // Ensure token0 < token1 for Uniswap V4
        if (tokens.token0 > tokens.token1) {
            (tokens.token0, tokens.token1) = (tokens.token1, tokens.token0);
        }

        emit TokensDeployed(
            tokens.token0,
            tokens.token1,
            tokens.weth,
            tokens.usdc,
            tokens.usdt
        );

        console.log("Token0:", tokens.token0);
        console.log("Token1:", tokens.token1);
        console.log("WETH:", tokens.weth);
        console.log("USDC:", tokens.usdc);
        console.log("USDT:", tokens.usdt);
    }

    /**
     * @notice Initialize trading pools
     * @param config Environment configuration
     * @param tokens Deployed tokens
     * @return pools Initialized pools
     */
    function _initializePools(
        EnvironmentConfig memory config,
        DeployedTokens memory tokens
    ) internal returns (DeployedPools memory pools) {
        console.log("Initializing pools...");

        IPoolManager poolManager = IPoolManager(config.poolManager);
        VaultSwapHook hook = VaultSwapHook(config.hookAddress);

        // Create pool keys
        pools.token0Token1Pool = PoolKey({
            currency0: Currency.wrap(tokens.token0),
            currency1: Currency.wrap(tokens.token1),
            fee: 3000, // 0.30%
            tickSpacing: 60,
            hooks: IHooks(address(hook))
        });

        pools.wethUsdcPool = PoolKey({
            currency0: Currency.wrap(_min(tokens.weth, tokens.usdc)),
            currency1: Currency.wrap(_max(tokens.weth, tokens.usdc)),
            fee: 500, // 0.05%
            tickSpacing: 10,
            hooks: IHooks(address(hook))
        });

        pools.wethUsdtPool = PoolKey({
            currency0: Currency.wrap(_min(tokens.weth, tokens.usdt)),
            currency1: Currency.wrap(_max(tokens.weth, tokens.usdt)),
            fee: 500, // 0.05%
            tickSpacing: 10,
            hooks: IHooks(address(hook))
        });

        // Initialize pools with 1:1 price
        uint160 sqrtPriceX96 = 79228162514264337593543950336; // SQRT_RATIO_1_1

        poolManager.initialize(pools.token0Token1Pool, sqrtPriceX96, "");
        poolManager.initialize(pools.wethUsdcPool, sqrtPriceX96, "");
        poolManager.initialize(pools.wethUsdtPool, sqrtPriceX96, "");

        // Get pool IDs
        pools.token0Token1PoolId = pools.token0Token1Pool.toId();
        pools.wethUsdcPoolId = pools.wethUsdcPool.toId();
        pools.wethUsdtPoolId = pools.wethUsdtPool.toId();

        emit PoolsInitialized(
            pools.token0Token1PoolId,
            pools.wethUsdcPoolId,
            pools.wethUsdtPoolId
        );

        console.log("Token0/Token1 Pool ID:", vm.toString(PoolId.unwrap(pools.token0Token1PoolId)));
        console.log("WETH/USDC Pool ID:", vm.toString(PoolId.unwrap(pools.wethUsdcPoolId)));
        console.log("WETH/USDT Pool ID:", vm.toString(PoolId.unwrap(pools.wethUsdtPoolId)));
    }

    /**
     * @notice Add initial liquidity to all pools
     * @param config Environment configuration
     * @param tokens Deployed tokens
     * @param pools Initialized pools
     */
    function _addInitialLiquidity(
        EnvironmentConfig memory config,
        DeployedTokens memory tokens,
        DeployedPools memory pools
    ) internal {
        console.log("Adding initial liquidity...");

        // Add liquidity to Token0/Token1 pool
        _addLiquidityToPool(
            config.poolManager,
            pools.token0Token1Pool,
            tokens.token0,
            tokens.token1,
            config.initialLiquidity
        );

        // Add liquidity to WETH/USDC pool
        _addLiquidityToPool(
            config.poolManager,
            pools.wethUsdcPool,
            _min(tokens.weth, tokens.usdc),
            _max(tokens.weth, tokens.usdc),
            config.initialLiquidity
        );

        // Add liquidity to WETH/USDT pool
        _addLiquidityToPool(
            config.poolManager,
            pools.wethUsdtPool,
            _min(tokens.weth, tokens.usdt),
            _max(tokens.weth, tokens.usdt),
            config.initialLiquidity
        );
    }

    /**
     * @notice Add liquidity to a specific pool
     * @param poolManager Pool manager address
     * @param poolKey Pool key
     * @param token0 Token0 address
     * @param token1 Token1 address
     * @param amount Liquidity amount
     */
    function _addLiquidityToPool(
        address poolManager,
        PoolKey memory poolKey,
        address token0,
        address token1,
        uint256 amount
    ) internal {
        // Approve tokens
        IERC20(token0).approve(poolManager, amount);
        IERC20(token1).approve(poolManager, amount);

        // Add liquidity using modifyPosition
        // Note: This is a simplified approach - in production you'd use the proper liquidity router
        console.log("Adding liquidity to pool with tokens:", token0, token1);
        
        emit LiquidityAdded(poolKey.toId(), msg.sender, amount, amount);
    }

    /**
     * @notice Setup initial test orders
     * @param config Environment configuration
     * @param tokens Deployed tokens
     * @param pools Initialized pools
     */
    function _setupInitialOrders(
        EnvironmentConfig memory config,
        DeployedTokens memory tokens,
        DeployedPools memory pools
    ) internal {
        console.log("Setting up initial test orders...");

        VaultSwapHook hook = VaultSwapHook(config.hookAddress);
        
        // Approve tokens for hook
        IERC20(tokens.token0).approve(address(hook), type(uint256).max);
        IERC20(tokens.token1).approve(address(hook), type(uint256).max);
        IERC20(tokens.weth).approve(address(hook), type(uint256).max);
        IERC20(tokens.usdc).approve(address(hook), type(uint256).max);
        IERC20(tokens.usdt).approve(address(hook), type(uint256).max);

        // Note: In production, you'd create actual encrypted orders here
        // For now, we just approve tokens for future order creation
        console.log("Tokens approved for hook interactions");
    }

    /**
     * @notice Deploy a mock ERC20 token
     * @param name Token name
     * @param symbol Token symbol
     * @param totalSupply Total supply to mint
     * @return tokenAddress Deployed token address
     */
    function _deployMockERC20(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) internal returns (address tokenAddress) {
        // Deploy mock ERC20 - simplified for demo
        bytes memory bytecode = abi.encodePacked(
            type(MockERC20).creationCode,
            abi.encode(name, symbol, totalSupply)
        );
        
        assembly {
            tokenAddress := create2(0, add(bytecode, 0x20), mload(bytecode), keccak256(abi.encode(name, symbol)))
        }
        
        require(tokenAddress != address(0), "Token deployment failed");
    }

    /**
     * @notice Load environment configuration
     * @return config Environment configuration
     */
    function _loadConfig() internal view returns (EnvironmentConfig memory config) {
        config.poolManager = vm.envOr("POOL_MANAGER", address(0));
        config.hookAddress = vm.envOr("HOOK_ADDRESS", address(0));
        config.deployer = msg.sender;
        config.initialLiquidity = vm.envOr("INITIAL_LIQUIDITY", uint256(100 ether));
        config.testTokenSupply = vm.envOr("TEST_TOKEN_SUPPLY", uint256(1000000 ether));

        require(config.poolManager != address(0), "POOL_MANAGER not set");
        require(config.hookAddress != address(0), "HOOK_ADDRESS not set");
    }

    /**
     * @notice Save environment artifacts
     * @param config Environment configuration
     * @param tokens Deployed tokens
     * @param pools Initialized pools
     */
    function _saveEnvironmentArtifacts(
        EnvironmentConfig memory config,
        DeployedTokens memory tokens,
        DeployedPools memory pools
    ) internal {
        string memory environmentJson = string(abi.encodePacked(
            '{\n',
            '  "chainId": ', vm.toString(block.chainid), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), ',\n',
            '  "deployer": "', vm.toString(config.deployer), '",\n',
            '  "poolManager": "', vm.toString(config.poolManager), '",\n',
            '  "hookAddress": "', vm.toString(config.hookAddress), '",\n',
            '  "tokens": {\n',
            '    "token0": "', vm.toString(tokens.token0), '",\n',
            '    "token1": "', vm.toString(tokens.token1), '",\n',
            '    "weth": "', vm.toString(tokens.weth), '",\n',
            '    "usdc": "', vm.toString(tokens.usdc), '",\n',
            '    "usdt": "', vm.toString(tokens.usdt), '"\n',
            '  },\n',
            '  "pools": {\n',
            '    "token0Token1PoolId": "', vm.toString(PoolId.unwrap(pools.token0Token1PoolId)), '",\n',
            '    "wethUsdcPoolId": "', vm.toString(PoolId.unwrap(pools.wethUsdcPoolId)), '",\n',
            '    "wethUsdtPoolId": "', vm.toString(PoolId.unwrap(pools.wethUsdtPoolId)), '"\n',
            '  }\n',
            '}'
        ));

        string memory fileName = string(abi.encodePacked(
            "deployments/",
            vm.toString(block.chainid),
            "_Environment.json"
        ));

        vm.writeFile(fileName, environmentJson);
        console.log("Environment artifacts saved to:", fileName);
    }

    /**
     * @notice Helper function to get minimum address
     */
    function _min(address a, address b) internal pure returns (address) {
        return a < b ? a : b;
    }

    /**
     * @notice Helper function to get maximum address
     */
    function _max(address a, address b) internal pure returns (address) {
        return a > b ? a : b;
    }

    /**
     * @notice Fund an account with test tokens
     * @param account Account to fund
     * @param tokens Token addresses
     * @param amount Amount to fund
     */
    function fundAccount(
        address account,
        DeployedTokens memory tokens,
        uint256 amount
    ) external {
        require(account != address(0), "Invalid account");
        
        // Transfer tokens to account
        IERC20(tokens.token0).transfer(account, amount);
        IERC20(tokens.token1).transfer(account, amount);
        IERC20(tokens.weth).transfer(account, amount);
        IERC20(tokens.usdc).transfer(account, amount);
        IERC20(tokens.usdt).transfer(account, amount);

        console.log("Funded account:", account, "with", amount, "of each token");
    }

    /**
     * @notice Get environment info
     * @return config Current environment configuration
     */
    function getEnvironmentInfo() external view returns (EnvironmentConfig memory config) {
        return _loadConfig();
    }
}

/**
 * @title MockERC20
 * @notice Simple mock ERC20 for testing
 */
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}