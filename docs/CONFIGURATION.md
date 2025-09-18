# VaultSwap Hook Configuration Guide

This guide covers all configuration options for VaultSwap Hook.

## Table of Contents

- [Environment Variables](#environment-variables)
- [Network Configuration](#network-configuration)
- [Security Settings](#security-settings)
- [Privacy Configuration](#privacy-configuration)
- [AVS Configuration](#avs-configuration)
- [Monitoring Settings](#monitoring-settings)
- [Advanced Configuration](#advanced-configuration)

## Environment Variables

### Core Settings

```bash
# Project name and version
PROJECT_NAME=VaultSwap-Hook
PROJECT_VERSION=1.0.0
ENVIRONMENT=development

# Debug settings
DEBUG=true
LOG_LEVEL=info
VERBOSE=false
```

### RPC Configuration

```bash
# L1 RPC URLs
L1_RPC_URL=http://localhost:8545
L1_RPC_URL_WS=ws://localhost:8545
L1_RPC_URL_BACKUP=http://backup.localhost:8545

# L2 RPC URLs
L2_RPC_URL=http://localhost:8546
L2_RPC_URL_WS=ws://localhost:8546
L2_RPC_URL_BACKUP=http://backup.localhost:8546

# RPC timeout settings
RPC_TIMEOUT=30000
RPC_RETRY_ATTEMPTS=3
RPC_RETRY_DELAY=1000
```

### Contract Addresses

```bash
# Main contracts
HOOK_ADDRESS=0x...
FHE_TOKEN_ADDRESS=0x...
SERVICE_MANAGER_ADDRESS=0x...
TASK_HOOK_ADDRESS=0x...

# Factory contracts
HOOK_FACTORY_ADDRESS=0x...
FHE_TOKEN_FACTORY_ADDRESS=0x...

# Proxy contracts
HOOK_PROXY_ADDRESS=0x...
SERVICE_MANAGER_PROXY_ADDRESS=0x...
```

## Network Configuration

### Ethereum Mainnet

```bash
# Network settings
CHAIN_ID=1
NETWORK_NAME=ethereum
NETWORK_TYPE=mainnet

# Gas settings
GAS_PRICE=20000000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=100000000000
PRIORITY_FEE=2000000000

# Block settings
BLOCK_CONFIRMATIONS=12
BLOCK_TIMEOUT=300000
```

### Sepolia Testnet

```bash
# Network settings
CHAIN_ID=11155111
NETWORK_NAME=sepolia
NETWORK_TYPE=testnet

# Gas settings
GAS_PRICE=1000000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=50000000000
PRIORITY_FEE=1000000000

# Block settings
BLOCK_CONFIRMATIONS=3
BLOCK_TIMEOUT=120000
```

### Arbitrum

```bash
# Network settings
CHAIN_ID=42161
NETWORK_NAME=arbitrum
NETWORK_TYPE=l2

# Gas settings
GAS_PRICE=100000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=1000000000
PRIORITY_FEE=0

# Block settings
BLOCK_CONFIRMATIONS=1
BLOCK_TIMEOUT=60000
```

### Optimism

```bash
# Network settings
CHAIN_ID=10
NETWORK_NAME=optimism
NETWORK_TYPE=l2

# Gas settings
GAS_PRICE=1000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=10000000
PRIORITY_FEE=0

# Block settings
BLOCK_CONFIRMATIONS=1
BLOCK_TIMEOUT=60000
```

### Polygon

```bash
# Network settings
CHAIN_ID=137
NETWORK_NAME=polygon
NETWORK_TYPE=l2

# Gas settings
GAS_PRICE=30000000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=100000000000
PRIORITY_FEE=0

# Block settings
BLOCK_CONFIRMATIONS=30
BLOCK_TIMEOUT=300000
```

### Base

```bash
# Network settings
CHAIN_ID=8453
NETWORK_NAME=base
NETWORK_TYPE=l2

# Gas settings
GAS_PRICE=1000000
GAS_LIMIT=1000000
MAX_GAS_PRICE=10000000
PRIORITY_FEE=0

# Block settings
BLOCK_CONFIRMATIONS=1
BLOCK_TIMEOUT=60000
```

## Security Settings

### Access Control

```bash
# Owner settings
OWNER_ADDRESS=0x...
OWNER_PRIVATE_KEY=0x...

# Operator settings
OPERATOR_ADDRESS=0x...
OPERATOR_PRIVATE_KEY=0x...

# Admin settings
ADMIN_ADDRESS=0x...
ADMIN_PRIVATE_KEY=0x...

# Role settings
ENABLE_ROLE_BASED_ACCESS=true
REQUIRE_MULTI_SIG=false
MULTI_SIG_THRESHOLD=2
```

### Private Key Management

```bash
# Key storage
KEY_STORAGE_TYPE=file
KEY_FILE_PATH=./keys/private.key
KEY_ENCRYPTION=true
KEY_ENCRYPTION_PASSWORD=your_password

# Hardware wallet
HARDWARE_WALLET_TYPE=ledger
HARDWARE_WALLET_PATH=usb://ledger
HARDWARE_WALLET_ACCOUNT=0
```

### Security Features

```bash
# MEV protection
ENABLE_MEV_PROTECTION=true
MEV_PROTECTION_LEVEL=5
ENABLE_DECOY_ORDERS=true
DECOY_ORDER_COUNT=3
DECOY_ORDER_DELAY=1000

# Slippage protection
MAX_SLIPPAGE=300
SLIPPAGE_TOLERANCE=50
ENABLE_SLIPPAGE_PROTECTION=true

# Reentrancy protection
ENABLE_REENTRANCY_GUARD=true
REENTRANCY_GUARD_DELAY=1000
```

## Privacy Configuration

### FHE Settings

```bash
# FHE enablement
ENABLE_FHE=true
FHE_PROVIDER=fhenix
FHE_NETWORK=testnet

# FHE keys
FHE_PUBLIC_KEY=0x...
FHE_PRIVATE_KEY=0x...
FHE_KEY_PATH=./keys/fhe.key

# FHE operations
FHE_ENCRYPTION_ALGORITHM=paillier
FHE_KEY_SIZE=2048
FHE_OPERATION_TIMEOUT=30000
```

### Privacy Features

```bash
# Order privacy
ENABLE_ORDER_PRIVACY=true
PRIVATE_ORDER_TIMEOUT=3600
ENCRYPT_ORDER_DATA=true

# Balance privacy
ENABLE_BALANCE_PRIVACY=true
ENCRYPT_BALANCE_DATA=true
PRIVATE_BALANCE_TIMEOUT=1800

# Transaction privacy
ENABLE_TRANSACTION_PRIVACY=true
PRIVATE_TRANSACTION_TIMEOUT=7200
```

## AVS Configuration

### Service Manager Settings

```bash
# Service manager
SERVICE_MANAGER_ADDRESS=0x...
SERVICE_MANAGER_PRIVATE_KEY=0x...
SERVICE_MANAGER_RPC_URL=http://localhost:8545

# Task settings
TASK_TIMEOUT=300000
TASK_RETRY_ATTEMPTS=3
TASK_RETRY_DELAY=5000
MAX_CONCURRENT_TASKS=10

# Operator settings
OPERATOR_REGISTRATION_REQUIRED=true
OPERATOR_STAKE_REQUIRED=1000000000000000000
OPERATOR_SLASH_THRESHOLD=3
```

### Task Hook Settings

```bash
# Task hook
TASK_HOOK_ADDRESS=0x...
TASK_HOOK_PRIVATE_KEY=0x...
TASK_HOOK_RPC_URL=http://localhost:8546

# Cross-chain settings
CROSS_CHAIN_ENABLED=true
CROSS_CHAIN_TIMEOUT=600000
CROSS_CHAIN_RETRY_ATTEMPTS=5
CROSS_CHAIN_RETRY_DELAY=10000

# Message settings
MESSAGE_TIMEOUT=300000
MESSAGE_RETRY_ATTEMPTS=3
MESSAGE_RETRY_DELAY=5000
```

### Performer Settings

```bash
# Performer configuration
PERFORMER_ENABLED=true
PERFORMER_RPC_URL=http://localhost:8545
PERFORMER_PRIVATE_KEY=0x...

# Task processing
TASK_PROCESSING_ENABLED=true
TASK_PROCESSING_INTERVAL=5000
TASK_PROCESSING_BATCH_SIZE=10
TASK_PROCESSING_TIMEOUT=300000

# Monitoring
PERFORMER_MONITORING_ENABLED=true
PERFORMER_METRICS_PORT=9090
PERFORMER_HEALTH_CHECK_INTERVAL=30000
```

## Monitoring Settings

### Logging Configuration

```bash
# Log levels
LOG_LEVEL=info
LOG_FORMAT=json
LOG_OUTPUT=console
LOG_FILE_PATH=./logs/vaultswap.log
LOG_MAX_SIZE=100MB
LOG_MAX_FILES=10

# Log categories
LOG_SMART_CONTRACTS=true
LOG_AVS_OPERATIONS=true
LOG_CROSS_CHAIN=true
LOG_MEV_PROTECTION=true
LOG_PRIVACY_OPERATIONS=true
```

### Metrics Configuration

```bash
# Metrics collection
METRICS_ENABLED=true
METRICS_PORT=9090
METRICS_PATH=/metrics
METRICS_INTERVAL=10000

# Metrics categories
METRICS_ORDER_PROCESSING=true
METRICS_MEV_PROTECTION=true
METRICS_CROSS_CHAIN=true
METRICS_AVS_OPERATIONS=true
METRICS_PRIVACY_OPERATIONS=true
```

### Health Checks

```bash
# Health check settings
HEALTH_CHECK_ENABLED=true
HEALTH_CHECK_PORT=8080
HEALTH_CHECK_PATH=/health
HEALTH_CHECK_INTERVAL=30000
HEALTH_CHECK_TIMEOUT=5000

# Health check endpoints
HEALTH_CHECK_L1_RPC=true
HEALTH_CHECK_L2_RPC=true
HEALTH_CHECK_CONTRACTS=true
HEALTH_CHECK_AVS=true
```

### Alerting

```bash
# Alert settings
ALERTING_ENABLED=true
ALERT_WEBHOOK_URL=https://hooks.slack.com/...
ALERT_EMAIL_SMTP_HOST=smtp.gmail.com
ALERT_EMAIL_SMTP_PORT=587
ALERT_EMAIL_USERNAME=alerts@vaultswap.io
ALERT_EMAIL_PASSWORD=your_password

# Alert thresholds
ALERT_ORDER_FAILURE_RATE=0.1
ALERT_MEV_PROTECTION_FAILURE_RATE=0.05
ALERT_CROSS_CHAIN_FAILURE_RATE=0.1
ALERT_AVS_FAILURE_RATE=0.05
```

## Advanced Configuration

### Performance Settings

```bash
# Performance optimization
ENABLE_PERFORMANCE_MODE=true
PERFORMANCE_BATCH_SIZE=100
PERFORMANCE_PARALLEL_PROCESSING=true
PERFORMANCE_CACHE_ENABLED=true
PERFORMANCE_CACHE_SIZE=1000
PERFORMANCE_CACHE_TTL=300000
```

### Database Settings

```bash
# Database configuration
DATABASE_TYPE=sqlite
DATABASE_URL=./data/vaultswap.db
DATABASE_MAX_CONNECTIONS=10
DATABASE_CONNECTION_TIMEOUT=30000
DATABASE_QUERY_TIMEOUT=30000

# Database tables
DATABASE_ORDERS_TABLE=orders
DATABASE_TASKS_TABLE=tasks
DATABASE_EVENTS_TABLE=events
DATABASE_METRICS_TABLE=metrics
```

### API Settings

```bash
# API configuration
API_ENABLED=true
API_PORT=3000
API_HOST=0.0.0.0
API_CORS_ENABLED=true
API_CORS_ORIGINS=*
API_RATE_LIMIT=1000
API_RATE_LIMIT_WINDOW=60000

# API authentication
API_AUTH_ENABLED=false
API_AUTH_TYPE=jwt
API_AUTH_SECRET=your_secret
API_AUTH_EXPIRES_IN=3600
```

### WebSocket Settings

```bash
# WebSocket configuration
WEBSOCKET_ENABLED=true
WEBSOCKET_PORT=3001
WEBSOCKET_HOST=0.0.0.0
WEBSOCKET_CORS_ENABLED=true
WEBSOCKET_CORS_ORIGINS=*

# WebSocket events
WEBSOCKET_ORDER_EVENTS=true
WEBSOCKET_TASK_EVENTS=true
WEBSOCKET_MEV_EVENTS=true
WEBSOCKET_PRIVACY_EVENTS=true
```

## Configuration Files

### Environment File (.env)

```bash
# Copy template
cp .env.example .env

# Edit configuration
nano .env
```

### Configuration File (config.json)

```json
{
  "network": {
    "l1": {
      "rpcUrl": "http://localhost:8545",
      "chainId": 1,
      "gasPrice": "20000000000"
    },
    "l2": {
      "rpcUrl": "http://localhost:8546",
      "chainId": 42161,
      "gasPrice": "100000000"
    }
  },
  "security": {
    "mevProtection": {
      "enabled": true,
      "level": 5,
      "decoyOrders": true
    },
    "privacy": {
      "enabled": true,
      "fheProvider": "fhenix"
    }
  },
  "avs": {
    "enabled": true,
    "serviceManager": "0x...",
    "taskHook": "0x..."
  }
}
```

### Docker Compose (docker-compose.yml)

```yaml
version: '3.8'
services:
  vaultswap-hook:
    build: .
    ports:
      - "3000:3000"
      - "8545:8545"
      - "8546:8546"
    environment:
      - L1_RPC_URL=http://localhost:8545
      - L2_RPC_URL=http://localhost:8546
    volumes:
      - ./data:/app/data
      - ./keys:/app/keys
    depends_on:
      - anvil
      - arbitrum

  anvil:
    image: foundry-rs/foundry:latest
    command: anvil
    ports:
      - "8545:8545"

  arbitrum:
    image: arbitrum/arbitrum:latest
    ports:
      - "8546:8546"
```

## Validation

### Configuration Validation

```bash
# Validate configuration
pnpm run validate-config

# Check environment variables
pnpm run check-env

# Test network connectivity
pnpm run test-network
```

### Configuration Testing

```bash
# Test configuration
pnpm run test-config

# Test with different environments
NODE_ENV=test pnpm run test-config
NODE_ENV=production pnpm run test-config
```

## Best Practices

### Security Best Practices

1. **Never commit private keys** to version control
2. **Use environment variables** for sensitive data
3. **Enable all security features** in production
4. **Regularly rotate keys** and passwords
5. **Monitor security events** and alerts

### Performance Best Practices

1. **Optimize gas usage** for smart contracts
2. **Use batch operations** when possible
3. **Enable caching** for frequently accessed data
4. **Monitor performance metrics** regularly
5. **Scale horizontally** when needed

### Privacy Best Practices

1. **Enable FHE** for sensitive operations
2. **Use encrypted storage** for private data
3. **Implement proper key management**
4. **Monitor privacy events** and violations
5. **Regularly audit privacy settings**

## Troubleshooting

### Common Configuration Issues

**1. Invalid RPC URLs**
```bash
# Check RPC connectivity
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  $L1_RPC_URL
```

**2. Invalid Contract Addresses**
```bash
# Verify contract addresses
cast call $HOOK_ADDRESS "name()" --rpc-url $L1_RPC_URL
```

**3. Invalid Private Keys**
```bash
# Check private key format
echo $L1_PRIVATE_KEY | wc -c
# Should output 66 (0x + 64 hex characters)
```

### Configuration Debugging

```bash
# Enable debug logging
DEBUG=true LOG_LEVEL=debug pnpm start

# Check configuration
pnpm run config:check

# Validate all settings
pnpm run config:validate
```

## Support

### Configuration Support

- **GitHub Issues**: Report configuration issues
- **Discord**: Get help with configuration
- **Documentation**: Check configuration guides

### Resources

- **[Installation Guide](INSTALLATION.md)** - Installation and setup
- **[Deployment Guide](DEPLOYMENT.md)** - Deployment configuration
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions

---

**Configuration complete?** Check out our [Deployment Guide](DEPLOYMENT.md) or [Getting Started Guide](GETTING_STARTED.md).

**Having issues?** Visit our [Troubleshooting Guide](TROUBLESHOOTING.md) or join our [Discord](https://discord.gg/vaultswap).

**Ready to deploy?** See our [Deployment Guide](DEPLOYMENT.md).

---

*This configuration guide is regularly updated. Last updated: January 1, 2024*
