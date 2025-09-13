# VaultSwap Hook - Deployment Guide

## Table of Contents
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Local Development](#local-development)
- [Testnet Deployment](#testnet-deployment)
- [Mainnet Deployment](#mainnet-deployment)
- [Configuration](#configuration)
- [Verification](#verification)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Software
- **Foundry**: For smart contract development and deployment
- **Node.js**: For JavaScript/TypeScript tooling
- **Git**: For version control
- **Docker**: For local development environment (optional)

### Required Accounts
- **Deployer Wallet**: Wallet with sufficient funds for deployment
- **API Keys**: Block explorer API keys for verification
- **RPC Access**: Access to network RPC endpoints

### Required Knowledge
- **Solidity**: Smart contract development
- **Foundry**: Forge and Cast tools
- **Uniswap v4**: Hook development
- **FHE**: Fully Homomorphic Encryption concepts

## Environment Setup

### 1. Clone Repository

```bash
git clone https://github.com/your-org/vaultswap-hook.git
cd vaultswap-hook
```

### 2. Install Dependencies

```bash
# Install Foundry dependencies
make install

# Install Node.js dependencies (if any)
npm install
```

### 3. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit environment file
nano .env
```

### 4. Configure Environment Variables

```bash
# Required variables
PRIVATE_KEY=your_private_key_here
ARBITRUM_SEPOLIA_RPC=https://sepolia-rollup.arbitrum.io/rpc
ARBISCAN_API_KEY=your_arbiscan_api_key_here

# Optional variables
POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000
```

## Local Development

### 1. Start Local Anvil

```bash
# Start Anvil in background
make dev

# Or start manually
anvil --host 0.0.0.0 --port 8545
```

### 2. Deploy to Local Network

```bash
# Deploy all contracts
make deploy-local

# Or deploy manually
forge script script/DeployVaultSwap.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 3. Configure Local Deployment

```bash
# Configure contracts
make configure-local

# Or configure manually
forge script script/ConfigureVaultSwap.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 4. Run Tests

```bash
# Run all tests
make test

# Run specific test
forge test --match-contract VaultSwapTest -vv

# Run with coverage
make test-coverage
```

## Testnet Deployment

### Arbitrum Sepolia

#### 1. Deploy Contracts

```bash
# Deploy to Arbitrum Sepolia
make deploy-sepolia

# Or deploy manually
forge script script/DeployVaultSwap.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --private-key $PRIVATE_KEY
```

#### 2. Configure Deployment

```bash
# Configure contracts
make configure-sepolia

# Or configure manually
forge script script/ConfigureVaultSwap.s.sol \
  --rpc-url $ARBITRUM_SEPOLIA_RPC \
  --broadcast \
  --private-key $PRIVATE_KEY
```

#### 3. Verify Contracts

```bash
# Verify contracts
make verify-sepolia

# Or verify manually
forge verify-contract \
  --chain-id 421614 \
  --num-of-optimizations 200 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS) \
  $VAULTSWAP_ADDRESS \
  src/VaultSwap.sol:VaultSwap
```

### Base Sepolia

#### 1. Deploy Contracts

```bash
# Deploy to Base Sepolia
make deploy-base-sepolia

# Or deploy manually
forge script script/DeployVaultSwap.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  --private-key $PRIVATE_KEY
```

#### 2. Configure Deployment

```bash
# Configure contracts
make configure-base-sepolia
```

#### 3. Verify Contracts

```bash
# Verify contracts
make verify-base-sepolia
```

## Mainnet Deployment

### Arbitrum One

#### 1. Pre-deployment Checklist

- [ ] All tests passing
- [ ] Security audit completed
- [ ] Configuration reviewed
- [ ] Deployment script tested
- [ ] Emergency procedures in place

#### 2. Deploy Contracts

```bash
# Deploy to Arbitrum One
make deploy-arbitrum

# Or deploy manually
forge script script/DeployVaultSwap.s.sol \
  --rpc-url $ARBITRUM_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $ARBISCAN_API_KEY \
  --private-key $PRIVATE_KEY
```

#### 3. Configure Deployment

```bash
# Configure contracts
make configure-arbitrum
```

#### 4. Verify Contracts

```bash
# Verify contracts
make verify-arbitrum
```

### Base Mainnet

#### 1. Deploy Contracts

```bash
# Deploy to Base Mainnet
make deploy-base

# Or deploy manually
forge script script/DeployVaultSwap.s.sol \
  --rpc-url $BASE_RPC \
  --broadcast \
  --verify \
  --etherscan-api-key $BASESCAN_API_KEY \
  --private-key $PRIVATE_KEY
```

#### 2. Configure Deployment

```bash
# Configure contracts
make configure-base
```

#### 3. Verify Contracts

```bash
# Verify contracts
make verify-base
```

## Configuration

### Network-specific Configuration

Each network has specific configuration parameters:

#### Arbitrum Sepolia
```bash
# Low limits for testnet
MEV_PROTECTION_LEVELS=1,2,3
DECOY_COUNTS=1,2,3
EXECUTION_DELAYS=10,30,60
```

#### Arbitrum One
```bash
# Full feature set
MEV_PROTECTION_LEVELS=1,2,3,4,5
DECOY_COUNTS=2,3,5,8,12
EXECUTION_DELAYS=30,60,120,300,600
```

### Component Configuration

#### MEV Protection
```bash
# Configure protection levels
MEV_PROTECTION_LEVEL_1_DECOY_COUNT=2
MEV_PROTECTION_LEVEL_1_EXECUTION_DELAY=30
MEV_PROTECTION_LEVEL_1_GAS_THRESHOLD=20
```

#### Routing
```bash
# Configure routing strategies
ROUTING_STRATEGY_BEST_PRICE=0
ROUTING_STRATEGY_LOWEST_IMPACT=1
ROUTING_STRATEGY_FASTEST=2
ROUTING_STRATEGY_BALANCED=3
```

#### Analytics
```bash
# Configure analytics
ENABLE_DETAILED_METRICS=true
ENABLE_RISK_ASSESSMENT=true
ENABLE_BENCHMARKING=true
DATA_RETENTION_PERIOD=31536000
```

### Institutional Configuration

#### Compliance
```bash
# Configure compliance thresholds
KYC_SCORE_THRESHOLD=80
AML_SCORE_THRESHOLD=85
REGULATORY_SCORE_THRESHOLD=90
RISK_SCORE_THRESHOLD=75
```

#### Risk Management
```bash
# Configure risk limits
RISK_LIMIT_LEVEL_1=1000000
RISK_LIMIT_LEVEL_2=5000000
RISK_LIMIT_LEVEL_3=10000000
RISK_LIMIT_LEVEL_4=50000000
RISK_LIMIT_LEVEL_5=100000000
```

## Verification

### Contract Verification

#### Automatic Verification
```bash
# Verify during deployment
forge script script/DeployVaultSwap.s.sol --verify
```

#### Manual Verification
```bash
# Verify specific contract
forge verify-contract \
  --chain-id 421614 \
  --num-of-optimizations 200 \
  --watch \
  --constructor-args $(cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS) \
  $VAULTSWAP_ADDRESS \
  src/VaultSwap.sol:VaultSwap
```

### Verification Checklist

- [ ] All contracts verified
- [ ] Constructor arguments correct
- [ ] Source code matches
- [ ] Optimization settings correct
- [ ] Network parameters correct

## Monitoring

### Health Checks

#### Contract Health
```bash
# Check contract deployment
cast call $VAULTSWAP_ADDRESS "getHookPermissions()" --rpc-url $RPC_URL

# Check MEV detection
cast call $MEV_DETECTION_ADDRESS "getMEVStatistics()" --rpc-url $RPC_URL

# Check router
cast call $ROUTER_ADDRESS "getRoutingStatistics()" --rpc-url $RPC_URL
```

#### System Health
```bash
# Check analytics
cast call $ANALYTICS_ADDRESS "getGlobalStatistics()" --rpc-url $RPC_URL

# Check institutional features
cast call $INSTITUTIONAL_FEATURES_ADDRESS "getGlobalStatistics()" --rpc-url $RPC_URL
```

### Monitoring Setup

#### 1. Set up Monitoring Endpoints

```bash
# Configure monitoring
MONITORING_ENDPOINT=https://monitoring.vaultswap.com
ALERT_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

#### 2. Configure Alerts

```bash
# Configure alert thresholds
ALERT_MEV_DETECTION_THRESHOLD=5
ALERT_RISK_VIOLATION_THRESHOLD=3
ALERT_COMPLIANCE_VIOLATION_THRESHOLD=1
```

#### 3. Set up Logging

```bash
# Configure logging
ENABLE_DEBUG_LOGGING=false
ENABLE_TEST_MODE=false
ENABLE_MOCK_DATA=false
```

## Troubleshooting

### Common Issues

#### 1. Deployment Failures

**Issue**: Contract deployment fails
**Solution**: Check gas limits and RPC connectivity

```bash
# Check gas limits
cast gas-price --rpc-url $RPC_URL

# Check RPC connectivity
cast block-number --rpc-url $RPC_URL
```

#### 2. Verification Failures

**Issue**: Contract verification fails
**Solution**: Check constructor arguments and source code

```bash
# Check constructor arguments
cast abi-encode "constructor(address)" $POOL_MANAGER_ADDRESS

# Check source code
forge build --sizes
```

#### 3. Configuration Issues

**Issue**: Configuration script fails
**Solution**: Check environment variables and network parameters

```bash
# Check environment variables
env | grep -E "(RPC|API|ADDRESS)"

# Check network parameters
cast chain-id --rpc-url $RPC_URL
```

### Debug Commands

#### 1. Check Contract State

```bash
# Check contract state
cast call $VAULTSWAP_ADDRESS "getPerformanceMetrics()" --rpc-url $RPC_URL

# Check specific order
cast call $VAULTSWAP_ADDRESS "getOrder(bytes32)" $ORDER_ID --rpc-url $RPC_URL
```

#### 2. Check Transactions

```bash
# Check transaction status
cast tx $TX_HASH --rpc-url $RPC_URL

# Check transaction receipt
cast receipt $TX_HASH --rpc-url $RPC_URL
```

#### 3. Check Logs

```bash
# Check contract logs
cast logs --address $VAULTSWAP_ADDRESS --rpc-url $RPC_URL

# Check specific event
cast logs --address $VAULTSWAP_ADDRESS --topic 0x... --rpc-url $RPC_URL
```

### Emergency Procedures

#### 1. Pause System

```bash
# Pause VaultSwap (if pause function exists)
cast send $VAULTSWAP_ADDRESS "pause()" --private-key $PRIVATE_KEY --rpc-url $RPC_URL
```

#### 2. Emergency Withdrawal

```bash
# Emergency withdrawal (if function exists)
cast send $VAULTSWAP_ADDRESS "emergencyWithdraw()" --private-key $PRIVATE_KEY --rpc-url $RPC_URL
```

#### 3. Update Configuration

```bash
# Update configuration
forge script script/ConfigureVaultSwap.s.sol --rpc-url $RPC_URL --broadcast --private-key $PRIVATE_KEY
```

## Best Practices

### Security

1. **Use Multi-sig Wallets**: For mainnet deployments
2. **Test Thoroughly**: On testnets before mainnet
3. **Monitor Continuously**: Set up monitoring and alerting
4. **Keep Private Keys Secure**: Use hardware wallets when possible

### Performance

1. **Optimize Gas Usage**: Use efficient data structures
2. **Batch Operations**: When possible
3. **Monitor Performance**: Track gas usage and execution time
4. **Scale Gradually**: Start with small limits and increase

### Maintenance

1. **Regular Updates**: Keep dependencies updated
2. **Monitor Metrics**: Track system performance
3. **Backup Configuration**: Keep configuration backups
4. **Document Changes**: Document all changes and updates

## Support

### Getting Help

- **Documentation**: Check this guide and architecture docs
- **Issues**: Create GitHub issues for bugs
- **Discussions**: Use GitHub discussions for questions
- **Community**: Join our Discord/Telegram for support

### Reporting Issues

When reporting issues, include:

1. **Network**: Which network you're using
2. **Version**: Contract version and Foundry version
3. **Error Message**: Full error message
4. **Steps to Reproduce**: Detailed steps
5. **Logs**: Relevant logs and output

### Contributing

1. **Fork Repository**: Fork the repository
2. **Create Branch**: Create feature branch
3. **Make Changes**: Implement changes
4. **Test Changes**: Run tests and verify
5. **Submit PR**: Submit pull request

## Conclusion

This deployment guide provides comprehensive instructions for deploying VaultSwap Hook across different networks. Follow the steps carefully and always test on testnets before mainnet deployment.

For additional support or questions, please refer to the documentation or contact the development team.
