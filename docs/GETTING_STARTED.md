# Getting Started with VaultSwap Hook

Welcome to VaultSwap Hook! This comprehensive guide will help you get started with the VaultSwap Hook project.

## Table of Contents

- [What is VaultSwap Hook?](#what-is-vaultswap-hook)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Basic Usage](#basic-usage)
- [Advanced Features](#advanced-features)
- [Next Steps](#next-steps)

## What is VaultSwap Hook?

VaultSwap Hook is a revolutionary Uniswap V4 hook that provides:

- **MEV Protection**: Advanced strategies to protect against Miner Extractable Value
- **Privacy**: FHE-enabled order processing for confidential trading
- **Cross-Chain**: Seamless L1/L2 task synchronization
- **AVS Integration**: EigenLayer AVS for decentralized task execution
- **High Performance**: Optimized for gas efficiency and speed

## Prerequisites

### Required Software

- **Node.js**: 18+ with pnpm
- **Foundry**: Latest version
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development

### Required Knowledge

- **Solidity**: Basic smart contract development
- **TypeScript/JavaScript**: Frontend development
- **Go**: Basic Go programming (for AVS)
- **Blockchain**: Understanding of blockchain concepts

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/VaultSwap/VaultSwap-Hook.git
cd VaultSwap-Hook
```

### 2. Install Dependencies

```bash
# Install Node.js dependencies
pnpm install

# Install Foundry dependencies
forge install

# Install AVS dependencies
cd avs
go mod tidy
cd ..
```

### 3. Verify Installation

```bash
# Check Node.js version
node --version

# Check Foundry version
forge --version

# Check Go version
go version

# Check Docker
docker --version
```

## Configuration

### 1. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 2. Configure Environment Variables

```bash
# RPC URLs
L1_RPC_URL=http://localhost:8545
L2_RPC_URL=http://localhost:8546

# Private keys (for testing only)
L1_PRIVATE_KEY=0x...
L2_PRIVATE_KEY=0x...

# Contract addresses (will be set after deployment)
HOOK_ADDRESS=0x...
FHE_TOKEN_ADDRESS=0x...
SERVICE_MANAGER_ADDRESS=0x...
TASK_HOOK_ADDRESS=0x...

# AVS configuration
AVS_PRIVATE_KEY=0x...
AVS_RPC_URL=http://localhost:8545
```

### 3. Start Local Development

```bash
# Start Anvil (in one terminal)
anvil

# Deploy contracts (in another terminal)
./scripts/deploy-anvil.sh
```

## Basic Usage

### 1. Create an Order

```typescript
import { ethers } from 'ethers';
import { VaultSwapHook__factory } from './contracts';

async function createOrder() {
    // Initialize provider and signer
    const provider = new ethers.JsonRpcProvider(process.env.L1_RPC_URL);
    const signer = new ethers.Wallet(process.env.L1_PRIVATE_KEY, provider);
    
    // Connect to contract
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    
    // Create order
    const tx = await hook.createOrder(
        TOKEN_IN,           // Input token address
        TOKEN_OUT,          // Output token address
        ethers.parseEther('1.0'),  // 1 ETH
        ethers.parseEther('0.95'), // Minimum 0.95 ETH out
        Math.floor(Date.now() / 1000) + 3600 // 1 hour deadline
    );
    
    const receipt = await tx.wait();
    console.log('Order created:', receipt.logs[0].args.orderId);
}
```

### 2. Execute an Order

```typescript
async function executeOrder(orderId: string) {
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    
    // Execute order
    const tx = await hook.executeOrder(orderId);
    const receipt = await tx.wait();
    
    console.log('Order executed:', receipt.transactionHash);
}
```

### 3. Check Order Status

```typescript
async function getOrderStatus(orderId: string) {
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    
    const order = await hook.getOrder(orderId);
    console.log('Order details:', {
        user: order.user,
        tokenIn: order.tokenIn,
        tokenOut: order.tokenOut,
        amountIn: order.amountIn.toString(),
        minAmountOut: order.minAmountOut.toString(),
        deadline: new Date(Number(order.deadline) * 1000),
        executed: order.executed,
        cancelled: order.cancelled
    });
}
```

## Advanced Features

### 1. MEV Protection

```typescript
async function setMEVProtection() {
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    
    // Set protection level (0-5, where 5 is maximum)
    await hook.setMEVProtectionLevel(5);
    
    // Enable decoy orders
    await hook.enableDecoyOrders(true);
    
    // Set maximum slippage (in basis points)
    await hook.setMaxSlippage(300); // 3%
    
    console.log('MEV protection configured');
}
```

### 2. Privacy Features

```typescript
import { HybridFHERC20__factory } from './contracts';

async function usePrivacyFeatures() {
    const fheToken = HybridFHERC20__factory.connect(process.env.FHE_TOKEN_ADDRESS, signer);
    
    // Mint tokens
    const mintTx = await fheToken.mint(USER_ADDRESS, ethers.parseEther('100'));
    await mintTx.wait();
    
    // Encrypt balance
    const encryptedBalance = await fheToken.encryptBalance(ethers.parseEther('50'));
    console.log('Encrypted balance:', encryptedBalance);
    
    // Use encrypted balance in order
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    const tx = await hook.createOrderWithFHE(
        process.env.FHE_TOKEN_ADDRESS,
        TOKEN_OUT,
        encryptedBalance,
        ethers.parseEther('0.95'),
        Math.floor(Date.now() / 1000) + 3600
    );
    
    console.log('Private order created');
}
```

### 3. Cross-Chain Operations

```typescript
import { VaultSwapServiceManager__factory } from './contracts';

async function submitCrossChainTask() {
    const serviceManager = VaultSwapServiceManager__factory.connect(
        process.env.SERVICE_MANAGER_ADDRESS, 
        signer
    );
    
    // Submit task to L1
    const taskData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256', 'uint256'],
        [TOKEN_IN, ethers.parseEther('1.0'), Math.floor(Date.now() / 1000) + 3600]
    );
    
    const tx = await serviceManager.submitTask(
        ethers.keccak256(ethers.toUtf8Bytes('task-' + Date.now())),
        taskData
    );
    
    const receipt = await tx.wait();
    console.log('Task submitted to L1:', receipt.transactionHash);
}
```

## Testing

### 1. Run Tests

```bash
# Run Solidity tests
forge test

# Run Go tests
cd avs
go test ./...
cd ..

# Run with coverage
forge coverage --ir-minimum
```

### 2. Test Specific Features

```bash
# Test MEV protection
forge test --match-test testMEVProtection

# Test privacy features
forge test --match-test testPrivacyFeatures

# Test cross-chain operations
forge test --match-test testCrossChain
```

### 3. Integration Testing

```bash
# Run integration tests
forge test --match-contract IntegrationTest

# Run with gas reporting
forge test --gas-report
```

## Deployment

### 1. Local Deployment

```bash
# Deploy to Anvil
./scripts/deploy-anvil.sh
```

### 2. Testnet Deployment

```bash
# Deploy to Sepolia
./scripts/deploy-testnet.sh
```

### 3. Mainnet Deployment

```bash
# Deploy to mainnet
./scripts/deploy-mainnet.sh
```

## Monitoring

### 1. Start AVS Performer

```bash
cd avs
go run cmd/main.go
```

### 2. Monitor Events

```typescript
async function monitorEvents() {
    const hook = VaultSwapHook__factory.connect(process.env.HOOK_ADDRESS, signer);
    
    // Listen for order events
    hook.on('OrderCreated', (orderId, user, tokenIn, tokenOut, amountIn, minAmountOut, deadline) => {
        console.log('New order created:', {
            orderId,
            user,
            tokenIn,
            tokenOut,
            amountIn: amountIn.toString(),
            minAmountOut: minAmountOut.toString(),
            deadline: new Date(Number(deadline) * 1000)
        });
    });
    
    hook.on('OrderExecuted', (orderId, executor, amountIn, amountOut) => {
        console.log('Order executed:', {
            orderId,
            executor,
            amountIn: amountIn.toString(),
            amountOut: amountOut.toString()
        });
    });
}
```

## Troubleshooting

### Common Issues

**1. Installation Issues**
```bash
# Clear cache and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

**2. Test Failures**
```bash
# Run tests with verbose output
forge test -vvv

# Check specific test
forge test --match-test testSpecificFunction
```

**3. Deployment Issues**
```bash
# Check Anvil is running
curl http://localhost:8545

# Check contract addresses
cat .env | grep ADDRESS
```

**4. AVS Issues**
```bash
# Check Go dependencies
cd avs
go mod tidy

# Run AVS tests
go test ./...
```

### Getting Help

- **GitHub Issues**: Report issues on GitHub
- **Discord**: Get help on Discord
- **Documentation**: Check the documentation
- **FAQ**: Read the FAQ

## Next Steps

### 1. Learn More

- **[Architecture Guide](ARCHITECTURE.md)** - Understand the system architecture
- **[API Reference](API.md)** - Complete API documentation
- **[Examples](EXAMPLES.md)** - Practical code examples

### 2. Advanced Topics

- **MEV Protection**: Advanced MEV protection strategies
- **Privacy Features**: FHE-enabled privacy
- **Cross-Chain**: L1/L2 task synchronization
- **AVS Integration**: EigenLayer AVS integration

### 3. Contribute

- **Code Contributions**: Submit pull requests
- **Documentation**: Improve documentation
- **Testing**: Help with testing
- **Community**: Engage with the community

## Resources

### Documentation
- **[README](README.md)** - Project overview
- **[Architecture](ARCHITECTURE.md)** - System architecture
- **[API Reference](API.md)** - API documentation
- **[Examples](EXAMPLES.md)** - Code examples

### Community
- **GitHub**: https://github.com/VaultSwap/VaultSwap-Hook
- **Discord**: https://discord.gg/vaultswap
- **Twitter**: @VaultSwap

### Support
- **GitHub Issues**: Report issues
- **Discord**: Community support
- **Email**: support@vaultswap.io

---

**Ready for more?** Check out our [Architecture Guide](ARCHITECTURE.md) or [API Reference](API.md).

**Have questions?** Visit our [FAQ](FAQ.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

---

*This getting started guide is regularly updated. Last updated: January 1, 2024*
