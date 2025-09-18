# VaultSwap Hook Troubleshooting Guide

This guide helps you diagnose and resolve common issues with VaultSwap Hook.

## Table of Contents

- [Common Issues](#common-issues)
- [Installation Issues](#installation-issues)
- [Configuration Issues](#configuration-issues)
- [Smart Contract Issues](#smart-contract-issues)
- [AVS Issues](#avs-issues)
- [Cross-Chain Issues](#cross-chain-issues)
- [Performance Issues](#performance-issues)
- [Debugging Tools](#debugging-tools)

## Common Issues

### 1. Connection Issues

**Problem**: Cannot connect to RPC endpoints

**Symptoms**:
- "Connection refused" errors
- "Network error" messages
- Timeout errors

**Solutions**:
```bash
# Check RPC connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  $L1_RPC_URL

# Test with different RPC providers
export L1_RPC_URL=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
export L1_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/YOUR_API_KEY

# Check network status
cast block-number --rpc-url $L1_RPC_URL
```

### 2. Gas Issues

**Problem**: Transactions failing due to gas

**Symptoms**:
- "Out of gas" errors
- "Gas limit exceeded" messages
- Transaction reverts

**Solutions**:
```bash
# Increase gas limit
forge script script/DeployVaultSwapHook.s.sol \
  --gas-limit 2000000 \
  --rpc-url $L1_RPC_URL

# Use gas estimation
cast estimate $HOOK_ADDRESS "createOrder(address,address,uint256,uint256,uint256)" \
  $TOKEN_IN $TOKEN_OUT $AMOUNT_IN $MIN_AMOUNT_OUT $DEADLINE \
  --rpc-url $L1_RPC_URL

# Check gas price
cast gas-price --rpc-url $L1_RPC_URL
```

### 3. Contract Issues

**Problem**: Contract calls failing

**Symptoms**:
- "Contract not found" errors
- "Function not found" messages
- Revert errors

**Solutions**:
```bash
# Verify contract address
cast call $HOOK_ADDRESS "name()" --rpc-url $L1_RPC_URL

# Check contract code
cast code $HOOK_ADDRESS --rpc-url $L1_RPC_URL

# Verify function exists
cast interface $HOOK_ADDRESS --rpc-url $L1_RPC_URL
```

## Installation Issues

### 1. Node.js Issues

**Problem**: Node.js version incompatible

**Error**: "Node.js version 16.x.x is not supported"

**Solution**:
```bash
# Check Node.js version
node --version

# Update Node.js
# macOS
brew upgrade node

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows: Download from https://nodejs.org/
```

### 2. Foundry Issues

**Problem**: Foundry not found

**Error**: "forge: command not found"

**Solution**:
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

# Verify installation
forge --version
```

### 3. Go Issues

**Problem**: Go version incompatible

**Error**: "Go version 1.19.x is not supported"

**Solution**:
```bash
# Check Go version
go version

# Update Go
# macOS
brew upgrade go

# Linux
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Windows: Download from https://golang.org/dl/
```

### 4. Docker Issues

**Problem**: Docker not running

**Error**: "Cannot connect to Docker daemon"

**Solution**:
```bash
# Start Docker service
# macOS: Start Docker Desktop
# Linux
sudo systemctl start docker
sudo usermod -aG docker $USER

# Windows: Start Docker Desktop
```

## Configuration Issues

### 1. Environment Variables

**Problem**: Missing environment variables

**Error**: "Environment variable L1_RPC_URL is not set"

**Solution**:
```bash
# Check environment variables
env | grep L1_RPC_URL

# Set environment variables
export L1_RPC_URL=http://localhost:8545
export L2_RPC_URL=http://localhost:8546

# Or use .env file
cp .env.example .env
nano .env
```

### 2. Private Key Issues

**Problem**: Invalid private key format

**Error**: "Invalid private key format"

**Solution**:
```bash
# Check private key format
echo $L1_PRIVATE_KEY | wc -c
# Should output 66 (0x + 64 hex characters)

# Generate new private key
openssl rand -hex 32

# Set private key
export L1_PRIVATE_KEY=0x...
```

### 3. Contract Address Issues

**Problem**: Invalid contract addresses

**Error**: "Contract not found at address"

**Solution**:
```bash
# Verify contract addresses
cast call $HOOK_ADDRESS "name()" --rpc-url $L1_RPC_URL

# Check if contract is deployed
cast code $HOOK_ADDRESS --rpc-url $L1_RPC_URL

# Redeploy contracts
./scripts/deploy-anvil.sh
```

## Smart Contract Issues

### 1. Compilation Issues

**Problem**: Solidity compilation errors

**Error**: "Compilation failed"

**Solution**:
```bash
# Clean build artifacts
forge clean

# Reinstall dependencies
forge install

# Rebuild
forge build

# Check for syntax errors
forge build --sizes
```

### 2. Deployment Issues

**Problem**: Contract deployment failing

**Error**: "Deployment failed"

**Solution**:
```bash
# Check deployment script
forge script script/DeployVaultSwapHook.s.sol --dry-run

# Increase gas limit
forge script script/DeployVaultSwapHook.s.sol \
  --gas-limit 5000000 \
  --rpc-url $L1_RPC_URL

# Check account balance
cast balance $DEPLOYER_ADDRESS --rpc-url $L1_RPC_URL
```

### 3. Function Call Issues

**Problem**: Function calls failing

**Error**: "Function call reverted"

**Solution**:
```bash
# Check function signature
cast interface $HOOK_ADDRESS --rpc-url $L1_RPC_URL

# Test function call
cast call $HOOK_ADDRESS "createOrder(address,address,uint256,uint256,uint256)" \
  $TOKEN_IN $TOKEN_OUT $AMOUNT_IN $MIN_AMOUNT_OUT $DEADLINE \
  --rpc-url $L1_RPC_URL

# Check function permissions
cast call $HOOK_ADDRESS "hasRole(bytes32,address)" \
  $ROLE $CALLER_ADDRESS --rpc-url $L1_RPC_URL
```

## AVS Issues

### 1. Performer Issues

**Problem**: AVS performer not starting

**Error**: "Failed to start performer"

**Solution**:
```bash
# Check Go dependencies
cd avs
go mod tidy
go mod verify

# Build performer
go build -o bin/vaultswap-performer cmd/main.go

# Run performer
./bin/vaultswap-performer
```

### 2. Task Processing Issues

**Problem**: Tasks not being processed

**Error**: "Task processing failed"

**Solution**:
```bash
# Check task queue
cast call $SERVICE_MANAGER_ADDRESS "getTaskQueue()" --rpc-url $L1_RPC_URL

# Check performer status
curl http://localhost:9090/health

# Restart performer
pkill vaultswap-performer
./bin/vaultswap-performer
```

### 3. Cross-Chain Issues

**Problem**: Cross-chain communication failing

**Error**: "Cross-chain message failed"

**Solution**:
```bash
# Check L1/L2 connectivity
cast block-number --rpc-url $L1_RPC_URL
cast block-number --rpc-url $L2_RPC_URL

# Check message bridge
cast call $MESSAGE_BRIDGE_ADDRESS "getMessageStatus(bytes32)" \
  $MESSAGE_ID --rpc-url $L1_RPC_URL

# Retry cross-chain operation
./scripts/retry-cross-chain.sh
```

## Cross-Chain Issues

### 1. Message Bridge Issues

**Problem**: Messages not crossing chains

**Error**: "Message bridge timeout"

**Solution**:
```bash
# Check bridge status
cast call $BRIDGE_ADDRESS "isBridgeActive()" --rpc-url $L1_RPC_URL

# Check message queue
cast call $BRIDGE_ADDRESS "getMessageQueue()" --rpc-url $L1_RPC_URL

# Retry message
cast send $BRIDGE_ADDRESS "retryMessage(bytes32)" \
  $MESSAGE_ID --rpc-url $L1_RPC_URL
```

### 2. State Synchronization Issues

**Problem**: State not syncing between chains

**Error**: "State sync failed"

**Solution**:
```bash
# Check state sync
cast call $SYNC_ADDRESS "getSyncStatus()" --rpc-url $L1_RPC_URL

# Force state sync
cast send $SYNC_ADDRESS "forceSync()" --rpc-url $L1_RPC_URL

# Check sync status
cast call $SYNC_ADDRESS "isSynced()" --rpc-url $L1_RPC_URL
```

## Performance Issues

### 1. Slow Execution

**Problem**: Orders executing slowly

**Symptoms**:
- Long wait times
- Timeout errors
- High gas costs

**Solution**:
```bash
# Check network congestion
cast gas-price --rpc-url $L1_RPC_URL

# Increase gas price
cast send $HOOK_ADDRESS "createOrder(...)" \
  --gas-price 30000000000 --rpc-url $L1_RPC_URL

# Use batch operations
cast send $HOOK_ADDRESS "batchCreateOrders(...)" \
  --rpc-url $L1_RPC_URL
```

### 2. High Gas Costs

**Problem**: Gas costs too high

**Symptoms**:
- Expensive transactions
- Out of gas errors
- Slow confirmation

**Solution**:
```bash
# Optimize gas usage
forge build --sizes

# Use gas estimation
cast estimate $HOOK_ADDRESS "createOrder(...)" --rpc-url $L1_RPC_URL

# Use L2 for cheaper transactions
export L2_RPC_URL=https://arb1.arbitrum.io/rpc
```

### 3. Memory Issues

**Problem**: Out of memory errors

**Error**: "Out of memory"

**Solution**:
```bash
# Check memory usage
free -h

# Increase memory limit
export NODE_OPTIONS="--max-old-space-size=4096"

# Restart with more memory
node --max-old-space-size=4096 index.js
```

## Debugging Tools

### 1. Logging

**Enable Debug Logging**:
```bash
# Set log level
export LOG_LEVEL=debug

# Enable verbose output
export VERBOSE=true

# Run with debug
DEBUG=* pnpm start
```

### 2. Network Debugging

**Check Network Status**:
```bash
# Check RPC connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  $L1_RPC_URL

# Check network status
cast block-number --rpc-url $L1_RPC_URL
cast gas-price --rpc-url $L1_RPC_URL
```

### 3. Contract Debugging

**Debug Contract Calls**:
```bash
# Trace transaction
cast trace $TX_HASH --rpc-url $L1_RPC_URL

# Debug function call
cast debug $TX_HASH --rpc-url $L1_RPC_URL

# Check contract state
cast call $HOOK_ADDRESS "getOrder(bytes32)" \
  $ORDER_ID --rpc-url $L1_RPC_URL
```

### 4. Performance Debugging

**Monitor Performance**:
```bash
# Check system resources
top
htop
iostat

# Monitor network
netstat -tulpn | grep :8545
ss -tulpn | grep :8545

# Check disk usage
df -h
du -sh *
```

## Error Codes

### Smart Contract Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `HookNotInitialized` | Hook not initialized | Call `initialize()` first |
| `InvalidOrder` | Invalid order parameters | Check order parameters |
| `OrderExpired` | Order deadline passed | Create new order |
| `InsufficientBalance` | Insufficient token balance | Ensure sufficient balance |
| `MEVProtectionFailed` | MEV protection failed | Retry with different parameters |
| `Unauthorized` | Caller not authorized | Check permissions |
| `OrderAlreadyExecuted` | Order already executed | Check order status |
| `OrderCancelled` | Order was cancelled | Create new order |

### AVS Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `TaskNotFound` | Task ID not found | Check task ID |
| `TaskAlreadyCompleted` | Task already completed | Check task status |
| `InvalidTaskData` | Task data invalid | Validate task data |
| `OperatorNotRegistered` | Operator not registered | Register operator first |
| `CrossChainSyncFailed` | Cross-chain sync failed | Retry sync operation |

### Network Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `ConnectionRefused` | RPC connection refused | Check RPC URL |
| `Timeout` | Request timeout | Increase timeout |
| `RateLimited` | Rate limit exceeded | Wait and retry |
| `InvalidResponse` | Invalid RPC response | Check RPC provider |

## Getting Help

### Support Channels

1. **GitHub Issues**: Report bugs and issues
2. **Discord**: Get real-time help
3. **Email**: Contact support team
4. **Documentation**: Check guides and FAQs

### Reporting Issues

**When reporting issues, include**:
- Error messages and logs
- Steps to reproduce
- Environment details
- Configuration files
- Screenshots if applicable

### Community Support

- **Discord**: https://discord.gg/vaultswap
- **GitHub**: https://github.com/VaultSwap/VaultSwap-Hook
- **Twitter**: @VaultSwap

## Prevention

### Best Practices

1. **Regular Updates**: Keep dependencies updated
2. **Monitoring**: Monitor system health
3. **Backups**: Regular backups of data
4. **Testing**: Test changes thoroughly
5. **Documentation**: Keep documentation updated

### Maintenance

1. **Regular Checks**: Check system status
2. **Log Review**: Review logs regularly
3. **Performance Monitoring**: Monitor performance metrics
4. **Security Updates**: Apply security updates
5. **Dependency Updates**: Update dependencies regularly

---

**Still having issues?** Check out our [FAQ](FAQ.md) or join our [Discord](https://discord.gg/vaultswap).

**Need more help?** Visit our [Support](SUPPORT.md) page or open a [GitHub issue](https://github.com/VaultSwap/VaultSwap-Hook/issues).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

---

*This troubleshooting guide is regularly updated. Last updated: January 1, 2024*
