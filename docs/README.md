# VaultSwap Hook Documentation

Welcome to the VaultSwap Hook documentation! This comprehensive guide covers everything you need to know about the VaultSwap Hook project.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Architecture](#architecture)
- [API Reference](#api-reference)
- [Deployment](#deployment)
- [Security](#security)
- [Contributing](#contributing)
- [Support](#support)

## Overview

VaultSwap Hook is a revolutionary Uniswap V4 hook that provides advanced MEV protection, intelligent routing, and privacy-preserving features using Fully Homomorphic Encryption (FHE). Built on EigenLayer's Actively Validated Services (AVS) framework and integrated with Fhenix, it represents the future of decentralized trading.

### Key Features

- **MEV Protection**: Advanced strategies to protect against Miner Extractable Value
- **Privacy**: FHE-enabled order processing for confidential trading
- **Cross-Chain**: Seamless L1/L2 task synchronization
- **AVS Integration**: EigenLayer AVS for decentralized task execution
- **High Performance**: Optimized for gas efficiency and speed

## Quick Start

### Prerequisites

- **Node.js**: 18+ with pnpm
- **Foundry**: Latest version
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development

### Installation

```bash
# Clone the repository
git clone https://github.com/VaultSwap/VaultSwap-Hook.git
cd VaultSwap-Hook

# Install dependencies
pnpm install
forge install

# Set up environment
cp .env.example .env
# Edit .env with your configuration
```

### Running Tests

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

### Local Development

```bash
# Start Anvil
anvil

# Deploy contracts
./scripts/deploy-anvil.sh

# Start AVS performer
cd avs
go run cmd/main.go
```

## Architecture

The VaultSwap Hook system consists of several key components:

### Smart Contracts
- **VaultSwapHook**: Main Uniswap V4 hook
- **HybridFHERC20**: FHE-enabled ERC20 token
- **VaultSwapServiceManager**: L1 AVS service manager
- **VaultSwapTaskHook**: L2 task processing hook

### AVS Components
- **VaultSwapPerformer**: Go-based task executor
- **Cross-chain Communication**: L1/L2 synchronization
- **Task Management**: Order processing and execution

### FHE Integration
- **Privacy-preserving Operations**: Encrypted order processing
- **Key Management**: Secure FHE key handling
- **Fhenix Integration**: FHE infrastructure

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).

## API Reference

### Smart Contract APIs

The VaultSwap Hook provides comprehensive smart contract interfaces:

```solidity
// Create a new order
function createOrder(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
) external returns (bytes32 orderId);

// Execute an order
function executeOrder(bytes32 orderId) external;

// Set MEV protection level
function setMEVProtectionLevel(uint8 level) external;
```

### AVS APIs

The AVS performer provides REST APIs for task management:

```bash
# Submit a task
curl -X POST /api/v1/tasks \
  -H "Content-Type: application/json" \
  -d '{"type": "mev_monitoring", "data": {...}}'

# Get task status
curl /api/v1/tasks/{taskId}
```

For complete API documentation, see [API.md](API.md).

## Deployment

### Local Development

```bash
# Deploy to Anvil
./scripts/deploy-anvil.sh
```

### Testnet

```bash
# Deploy to Sepolia
./scripts/deploy-testnet.sh
```

### Mainnet

```bash
# Deploy to mainnet
./scripts/deploy-mainnet.sh
```

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

## Security

VaultSwap Hook implements multiple layers of security:

- **Smart Contract Security**: Access controls, reentrancy protection, input validation
- **FHE Security**: Secure key management, encrypted operations
- **AVS Security**: Task validation, operator reputation
- **Cross-chain Security**: Message verification, state validation

For security information and vulnerability reporting, see [SECURITY.md](SECURITY.md).

## Contributing

We welcome contributions from the community! Here's how you can help:

1. **Report Issues**: Found a bug? Report it on GitHub
2. **Suggest Features**: Have an idea? Open a discussion
3. **Submit Code**: Fix bugs or add features
4. **Improve Docs**: Help others understand the project

For contribution guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

## Support

### Getting Help

- **GitHub Issues**: For bug reports and feature requests
- **Discord**: For community support and discussions
- **Email**: For security issues and business inquiries

### Resources

- **Documentation**: This comprehensive guide
- **API Reference**: Complete API documentation
- **Examples**: Integration examples and tutorials
- **Community**: Discord server and GitHub discussions

## License

VaultSwap Hook is licensed under the MIT License. See [LICENSE.md](LICENSE.md) for details.

## Changelog

For a complete list of changes, see [CHANGELOG.md](CHANGELOG.md).

## Acknowledgments

- **EigenLayer**: For the AVS framework
- **Fhenix**: For FHE infrastructure
- **Uniswap**: For the V4 hook framework
- **OpenZeppelin**: For secure smart contract libraries
- **Community**: For contributions and feedback

## Contact

- **Website**: https://vaultswap.io
- **GitHub**: https://github.com/VaultSwap/VaultSwap-Hook
- **Discord**: https://discord.gg/vaultswap
- **Email**: contact@vaultswap.io

---

**VaultSwap Hook** - The future of decentralized trading with MEV protection and privacy.

*Last updated: January 1, 2024*
