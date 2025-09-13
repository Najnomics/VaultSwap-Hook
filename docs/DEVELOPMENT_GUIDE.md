# VaultSwap Hook Development Guide

## Table of Contents

1. [Getting Started](#getting-started)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Structure](#project-structure)
4. [Building and Testing](#building-and-testing)
5. [Deployment](#deployment)
6. [Configuration](#configuration)
7. [Contributing](#contributing)
8. [Troubleshooting](#troubleshooting)

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js** (v18 or higher)
- **pnpm** (v8 or higher)
- **Foundry** (latest version)
- **Git**

### Quick Start

1. **Clone the repository**:
```bash
git clone https://github.com/your-org/VaultSwap-Hook.git
cd VaultSwap-Hook
```

2. **Install dependencies**:
```bash
make install
```

3. **Build the project**:
```bash
make build
```

4. **Run tests**:
```bash
make test
```

5. **Deploy locally**:
```bash
make deploy-local
```

## Development Environment Setup

### 1. Environment Variables

Copy the example environment file and configure it:

```bash
cp .env.example .env
```

Key environment variables:

```bash
# Core Configuration
PRIVATE_KEY=your_private_key_here
RPC_URL=https://your.rpc.endpoint.here

# Network Configuration
POOL_MANAGER=0x0000000000000000000000000000000000000000
HOOK_ADDRESS=0x0000000000000000000000000000000000000000
FHE_GATEWAY=0x0000000000000000000000000000000000000000

# Development Settings
INITIAL_LIQUIDITY=100000000000000000000  # 100 ETH
TEST_TOKEN_SUPPLY=1000000000000000000000000  # 1M tokens
VERIFY_CONTRACTS=true
```

### 2. Local Development Network

Start a local Anvil network:

```bash
make dev
```

This will start Anvil on `http://localhost:8545` with default accounts.

### 3. IDE Configuration

#### VS Code Settings

Recommended VS Code extensions:
- **Solidity** by Juan Blanco
- **Prettier** for code formatting
- **ESLint** for JavaScript/TypeScript linting

### 4. Git Hooks

Set up pre-commit hooks for code quality:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
```

## Project Structure

```
VaultSwap-Hook/
├── src/                          # Smart contracts
│   ├── VaultSwapHook.sol        # Main hook contract
│   └── lib/                     # Library contracts
│       ├── MEVProtection.sol    # MEV protection system
│       ├── IntelligentRouter.sol # Cross-pool routing
│       ├── ExecutionStrategies.sol # Execution algorithms
│       ├── ExecutionAnalytics.sol # Performance analytics
│       ├── FHEPermissions.sol   # FHE permission management
│       ├── VaultSwapLib.sol     # Core utilities
│       └── OrderQueue.sol       # Order queue management
├── test/                        # Test files
│   └── VaultSwapHook.t.sol     # Comprehensive test suite
├── script/                      # Deployment scripts
│   ├── DeployVaultSwapHook.s.sol # Main deployment
│   └── SetupEnvironment.s.sol   # Environment setup
├── docs/                        # Documentation
├── .env.example                 # Environment template
├── foundry.toml                 # Foundry configuration
├── Makefile                     # Build automation
└── README.md                    # Project overview
```

### Key Directories

- **`src/`**: Contains all smart contracts
- **`test/`**: Comprehensive test suite with 200+ tests
- **`script/`**: Deployment and setup scripts
- **`docs/`**: Documentation and guides

## Building and Testing

### Building

```bash
# Standard build
make build

# Build with contract size information
make build-verbose

# Clean build artifacts
make clean
```

### Testing

#### Basic Testing

```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Run specific test contract
forge test --match-contract VaultSwapHookTest
```

#### Advanced Testing

```bash
# Test coverage analysis
make test-coverage

# Gas usage analysis
make test-gas

# Fuzz testing
make test-fuzz

# Invariant testing
make test-invariant
```

#### Test Structure

Our test suite includes:

1. **Core Functionality Tests** (50+ tests)
   - Order submission and cancellation
   - Basic hook lifecycle
   - Permission management

2. **MEV Protection Tests** (40+ tests)
   - All 5 protection levels
   - Attack detection scenarios
   - Decoy order systems

3. **Execution Strategy Tests** (30+ tests)
   - TWAP, VWAP, Opportunistic, Immediate
   - Strategy validation
   - Fragment calculations

4. **Intelligent Router Tests** (25+ tests)
   - Single pool, multi-pool routing
   - Liquidity optimization
   - Gas efficiency

5. **Analytics Tests** (20+ tests)
   - Execution quality scoring
   - Performance metrics
   - Compliance reporting

6. **Integration Tests** (15+ tests)
   - Uniswap V4 integration
   - FHE library integration
   - Cross-component interaction

7. **Edge Case Tests** (15+ tests)
   - Boundary value testing
   - Error condition handling
   - Security scenarios

8. **Stress Tests** (5+ tests)
   - Concurrent operations
   - High-load scenarios
   - Performance under stress

### Code Quality

```bash
# Format code
make format

# Check formatting
make format-check

# Run linter
make lint
```

## Deployment

### Local Deployment

```bash
# Deploy to local Anvil
make deploy-local

# Setup complete environment (tokens, pools, liquidity)
make setup-environment
```

### Testnet Deployment

```bash
# Deploy to Arbitrum Sepolia
make deploy-sepolia

# Deploy to Base Sepolia
make deploy-base-sepolia

# Deploy to Fhenix testnet
make deploy-fhenix
```

### Mainnet Deployment

```bash
# Deploy to Arbitrum One
make deploy-arbitrum

# Deploy to Base Mainnet
make deploy-base
```

### Deployment Configuration

Update network configurations in `script/DeployVaultSwapHook.s.sol`:

```solidity
// Ethereum Mainnet
networkConfigs[1] = NetworkConfig({
    poolManager: 0x..., // Actual mainnet address
    fheGateway: 0x...,  // FHE gateway address
    deployerPrivateKey: 0,
    verifyContracts: true
});
```

### Verification

```bash
# Verify on Arbitrum Sepolia
make verify-sepolia

# Verify on Base Sepolia
make verify-base-sepolia
```

## Configuration

### Foundry Configuration

`foundry.toml`:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
remappings = [
    "@uniswap/v4-core/=lib/v4-core/",
    "@fhenixprotocol/cofhe-contracts/=lib/cofhe-contracts/",
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"
]

[profile.default.fuzz]
runs = 1000

[profile.default.invariant]
runs = 256
depth = 32
```

### MEV Protection Configuration

Configure protection levels in `MEVProtection.sol`:

```solidity
// Adjust decoy counts per protection level
uint8[6] public constant DECOY_COUNTS = [0, 2, 3, 5, 8, 12];

// Adjust execution delays (seconds)
uint32[6] public constant EXECUTION_DELAYS = [0, 30, 60, 120, 300, 600];
```

### Gas Optimization

Optimize gas usage:

```solidity
// Use packed structs
struct PackedOrder {
    uint128 amount;      // Instead of uint256
    uint64 deadline;     // Instead of uint256
    uint32 mevLevel;     // Instead of uint256
    uint8 direction;     // Instead of uint256
}
```

## Contributing

### Code Style

Follow these conventions:

1. **Solidity Style**:
   - Use 4 spaces for indentation
   - Follow [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
   - Document all public functions with NatSpec

2. **Naming Conventions**:
   - Functions: `camelCase`
   - Variables: `camelCase`
   - Constants: `UPPER_SNAKE_CASE`
   - Events: `PascalCase`

3. **Documentation**:
   - All public functions must have NatSpec comments
   - Complex logic should be commented
   - Update documentation for new features

### Testing Requirements

- All new features must have tests
- Aim for 100% line coverage
- Include edge case testing
- Add integration tests for new components

### Pull Request Process

1. **Create Feature Branch**:
```bash
git checkout -b feature/your-feature-name
```

2. **Make Changes**:
   - Write code following style guidelines
   - Add comprehensive tests
   - Update documentation

3. **Test Changes**:
```bash
make test
make test-coverage
make build
```

4. **Submit PR**:
   - Clear description of changes
   - Link to related issues
   - Include test results

### Security Review

All code changes undergo security review:

1. **Automated Checks**:
   - Static analysis with Slither
   - Gas optimization analysis
   - Test coverage verification

2. **Manual Review**:
   - Logic correctness
   - Security vulnerability assessment
   - Performance impact evaluation

## Troubleshooting

### Common Issues

#### 1. Build Failures

**Problem**: `Error: Could not find FHE contract`

**Solution**:
```bash
# Reinstall dependencies
forge clean
make install
make build
```

#### 2. Test Failures

**Problem**: `Error: FHE operations not working in tests`

**Solution**:
```bash
# Check FHE setup
forge test --match-test test_FHE -vvv
```

#### 3. Deployment Issues

**Problem**: `Error: Hook address validation failed`

**Solution**:
```bash
# Verify hook flags match deployment address
# Check CREATE2 salt calculation
forge script script/DeployVaultSwapHook.s.sol --dry-run
```

#### 4. Permission Errors

**Problem**: `Error: FHE permission denied`

**Solution**:
```bash
# Check permission granting in tests
# Verify FHE.allow() calls
# Check user/contract addresses
```

### Debug Tools

#### 1. Forge Debug

```bash
# Debug specific test
forge test --match-test testName --debug

# Debug with traces
forge test --match-test testName -vvvv
```

#### 2. Gas Profiling

```bash
# Generate gas report
forge test --gas-report

# Profile specific function
forge test --match-test testName --gas-report
```

#### 3. Coverage Analysis

```bash
# Generate coverage report
forge coverage

# Generate LCOV report
forge coverage --report lcov
```

### Performance Optimization

#### 1. Gas Optimization

- Use `uint256` for most calculations (optimal for EVM)
- Pack structs to minimize storage slots
- Cache storage reads in memory variables
- Use libraries for common operations

#### 2. FHE Optimization

- Batch FHE operations when possible
- Minimize encrypted value creation
- Cache FHE permissions
- Use appropriate FHE data types

#### 3. Test Optimization

- Group related tests in single transaction
- Use setUp() for common initialization
- Mock external dependencies
- Parallelize independent tests

### Monitoring and Alerting

#### 1. Contract Events

Monitor key events in production:

```solidity
event VaultOrderSubmitted(bytes32 indexed orderId, address indexed owner);
event MEVDetected(bytes32 indexed orderId, uint8 attackType);
event ExecutionCompleted(bytes32 indexed orderId, uint256 score);
```

#### 2. Performance Metrics

Track important metrics:
- Order execution success rate
- Average execution time
- Gas usage per operation
- MEV protection effectiveness

#### 3. Error Monitoring

Set up alerts for:
- Contract execution failures
- Unusual gas usage
- MEV attack attempts
- Permission violations

## Advanced Development

### Custom Execution Strategies

Add new execution algorithms:

```solidity
// 1. Add strategy constant
uint8 public constant CUSTOM_EXECUTION = 5;

// 2. Update validation
function isValidStrategy(uint8 strategy) internal pure returns (bool) {
    return strategy >= 1 && strategy <= 5; // Include new strategy
}

// 3. Implement strategy logic
function executeCustomStrategy(bytes32 orderId) internal {
    // Custom strategy implementation
}
```

### Custom MEV Protection

Extend MEV protection:

```solidity
// 1. Add new detection method
function detectCustomAttack(
    PoolKey memory key,
    SwapParams memory params
) internal view returns (bool) {
    // Custom detection logic
}

// 2. Integrate into main detection
function detectMEV(...) internal view returns (bool, string memory) {
    // Include custom detection
    if (detectCustomAttack(key, params)) {
        return (true, "Custom attack detected");
    }
    // ... existing detection logic
}
```

### Performance Profiling

Profile contract performance:

```bash
# Enable detailed profiling
export FOUNDRY_PROFILE=profiling

# Run profiling tests
forge test --match-contract PerformanceTest --gas-report

# Analyze results
forge coverage --report summary
```

This development guide provides comprehensive information for developers working on the VaultSwap Hook project, from initial setup to advanced customization and optimization.