# VaultSwap Hook Quick Start Guide

Get up and running with VaultSwap Hook in minutes!

## Prerequisites

Before you begin, ensure you have the following installed:

- **Node.js**: 18+ with pnpm
- **Foundry**: Latest version
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development

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

### 3. Set Up Environment

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

## Quick Start

### 1. Start Local Development

```bash
# Start Anvil (in one terminal)
anvil

# Deploy contracts (in another terminal)
./scripts/deploy-anvil.sh
```

### 2. Run Tests

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

### 3. Start AVS Performer

```bash
cd avs
go run cmd/main.go
```

## Basic Usage

### Create an Order

```typescript
import { ethers } from 'ethers';
import { VaultSwapHook__factory } from './contracts';

async function createOrder() {
    // Initialize provider and signer
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);
    
    // Connect to contract
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
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

### Execute an Order

```typescript
async function executeOrder(orderId: string) {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Execute order
    const tx = await hook.executeOrder(orderId);
    const receipt = await tx.wait();
    
    console.log('Order executed:', receipt.transactionHash);
}
```

### Set MEV Protection

```typescript
async function setMEVProtection() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Set maximum protection level
    await hook.setMEVProtectionLevel(5);
    
    // Enable decoy orders
    await hook.enableDecoyOrders(true);
    
    console.log('MEV protection enabled');
}
```

## Next Steps

### 1. Read the Documentation

- **[Architecture Guide](ARCHITECTURE.md)** - Understand the system architecture
- **[API Reference](API.md)** - Complete API documentation
- **[Examples](EXAMPLES.md)** - Practical code examples

### 2. Explore Advanced Features

- **MEV Protection**: Advanced MEV protection strategies
- **Privacy Features**: FHE-enabled privacy
- **Cross-Chain**: L1/L2 task synchronization
- **AVS Integration**: EigenLayer AVS integration

### 3. Join the Community

- **Discord**: Join our Discord community
- **GitHub**: Star and watch the repository
- **Twitter**: Follow for updates

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
```

**3. Deployment Issues**
```bash
# Check Anvil is running
curl http://localhost:8545
```

### Getting Help

- **GitHub Issues**: Report issues on GitHub
- **Discord**: Get help on Discord
- **Documentation**: Check the documentation
- **FAQ**: Read the FAQ

## What's Next?

### Learn More
- **[Getting Started Guide](GETTING_STARTED.md)** - Comprehensive beginner's guide
- **[Tutorial](TUTORIAL.md)** - Hands-on tutorial
- **[Architecture Guide](ARCHITECTURE.md)** - System architecture

### Advanced Usage
- **[Examples](EXAMPLES.md)** - Advanced examples
- **[API Reference](API.md)** - Complete API reference
- **[Deployment Guide](DEPLOYMENT.md)** - Production deployment

### Community
- **[Contributing](CONTRIBUTING.md)** - How to contribute
- **[Discord](https://discord.gg/vaultswap)** - Join the community
- **[GitHub](https://github.com/VaultSwap/VaultSwap-Hook)** - Source code

---

**Ready to dive deeper?** Check out our [Getting Started Guide](GETTING_STARTED.md) or [Architecture Guide](ARCHITECTURE.md).

**Have questions?** Visit our [FAQ](FAQ.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

---

*This quick start guide is regularly updated. Last updated: January 1, 2024*
