# VaultSwap Hook Deployment Guide

## Overview

This guide covers the deployment of VaultSwap Hook across different networks and environments.

## Prerequisites

### Required Software
- **Foundry**: Latest version
- **Node.js**: 18+ with pnpm
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development

### Required Accounts
- Ethereum account with sufficient ETH
- API keys for block explorers
- RPC endpoints for target networks

## Environment Setup

### 1. Clone Repository
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

### 3. Configure Environment
```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

## Deployment Options

### Local Development (Anvil)

**Start Anvil:**
```bash
anvil
```

**Deploy Contracts:**
```bash
# Using deployment script
./scripts/deploy-anvil.sh

# Or manually
forge script script/DeployVaultSwapHookSimple.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Testnet Deployment (Sepolia)

**Prerequisites:**
- Sepolia ETH for gas fees
- Etherscan API key for verification

**Deploy:**
```bash
# Using deployment script
./scripts/deploy-testnet.sh

# Or manually
forge script script/DeployVaultSwapHook.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $SEPOLIA_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Mainnet Deployment

**Prerequisites:**
- Mainnet ETH for gas fees
- Etherscan API key for verification
- Thorough testing on testnets

**Deploy:**
```bash
# Using deployment script
./scripts/deploy-mainnet.sh

# Or manually
forge script script/DeployVaultSwapHook.s.sol \
  --rpc-url $MAINNET_RPC_URL \
  --private-key $MAINNET_PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## AVS Deployment

### L1 Contracts (Ethereum)

**Deploy Service Manager:**
```bash
cd avs
make deploy-l1 L1_RPC_URL=$MAINNET_RPC_URL
```

### L2 Contracts (Arbitrum)

**Deploy Task Hook:**
```bash
cd avs
make deploy-l2 L2_RPC_URL=$ARBITRUM_RPC_URL
```

## Post-Deployment

### 1. Verify Contracts
```bash
# Check deployment status
forge verify-contract <CONTRACT_ADDRESS> <CONTRACT_NAME> \
  --etherscan-api-key $ETHERSCAN_API_KEY

# Verify on block explorer
cast call <CONTRACT_ADDRESS> "name()" --rpc-url $RPC_URL
```

### 2. Initialize Contracts
```bash
# Set up initial configuration
cast send <HOOK_ADDRESS> "initialize()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 3. Configure Parameters
```bash
# Set MEV protection level
cast send <HOOK_ADDRESS> "setMEVProtectionLevel(uint8)" 3 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Enable decoy orders
cast send <HOOK_ADDRESS> "enableDecoyOrders(bool)" true \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## Network-Specific Configuration

### Ethereum Mainnet
- **Chain ID**: 1
- **Gas Price**: 20-50 gwei
- **Confirmation Blocks**: 12

### Arbitrum
- **Chain ID**: 42161
- **Gas Price**: 0.1 gwei
- **Confirmation Blocks**: 1

### Optimism
- **Chain ID**: 10
- **Gas Price**: 0.001 gwei
- **Confirmation Blocks**: 1

### Polygon
- **Chain ID**: 137
- **Gas Price**: 30-100 gwei
- **Confirmation Blocks**: 30

### Base
- **Chain ID**: 8453
- **Gas Price**: 0.001 gwei
- **Confirmation Blocks**: 1

## Security Considerations

### Private Key Management
- Use hardware wallets for mainnet
- Never commit private keys to version control
- Use environment variables for sensitive data

### Multi-Signature Setup
- Deploy with multi-sig for mainnet
- Set up timelock for critical functions
- Implement emergency pause functionality

### Verification
- Verify all contracts on block explorers
- Run comprehensive tests before deployment
- Monitor for security vulnerabilities

## Troubleshooting

### Common Issues

**1. Insufficient Gas**
```bash
# Increase gas limit
forge script script/DeployVaultSwapHook.s.sol \
  --gas-limit 10000000 \
  --rpc-url $RPC_URL
```

**2. Verification Failed**
```bash
# Check contract source
forge verify-contract <ADDRESS> <CONTRACT> \
  --etherscan-api-key $API_KEY \
  --show-standard-json-input
```

**3. RPC Connection Issues**
```bash
# Test RPC connection
cast block-number --rpc-url $RPC_URL
```

### Debug Commands

```bash
# Check deployment status
forge script script/DeployVaultSwapHook.s.sol --dry-run

# Simulate deployment
forge script script/DeployVaultSwapHook.s.sol --fork-url $RPC_URL

# Debug specific function
cast call <CONTRACT_ADDRESS> "functionName()" --rpc-url $RPC_URL
```

## Monitoring

### On-Chain Monitoring
- Contract event monitoring
- Gas usage tracking
- Transaction success rates

### Off-Chain Monitoring
- System health checks
- Performance metrics
- Error rate monitoring

## Rollback Procedures

### Emergency Pause
```bash
# Pause contract
cast send <HOOK_ADDRESS> "pause()" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### Contract Upgrade
```bash
# Deploy new implementation
forge script script/UpgradeVaultSwapHook.s.sol \
  --rpc-url $RPC_URL \
  --broadcast

# Update proxy
cast send <PROXY_ADDRESS> "upgradeTo(address)" <NEW_IMPLEMENTATION> \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

## Support

For deployment issues:
- Check the [Troubleshooting](#troubleshooting) section
- Review the [Architecture Guide](ARCHITECTURE.md)
- Contact the development team