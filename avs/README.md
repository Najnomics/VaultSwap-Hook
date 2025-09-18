# VaultSwap AVS (Actively Validated Services)

A sophisticated EigenLayer AVS implementation for VaultSwap, providing advanced MEV protection, cross-chain order execution, and private FHE-enabled trading capabilities.

## Overview

VaultSwap AVS is designed to work seamlessly with the VaultSwap Hook system, providing:

- **MEV Protection**: Advanced detection and mitigation of MEV attacks
- **Cross-Chain Execution**: Seamless order execution across multiple chains
- **Private Trading**: FHE-enabled private order processing
- **Intelligent Routing**: Optimal execution strategies for large orders
- **MEV Distribution**: Fair distribution of MEV profits to stakeholders

## Architecture

### L1 Contracts (Ethereum)
- **VaultSwapServiceManager**: Manages operator registration and staking
- **IVaultSwapDirectory**: Interface for AVS directory management

### L2 Contracts (Arbitrum/Optimism)
- **VaultSwapTaskHook**: Handles task validation and execution
- **VaultSwapHook**: Main business logic contract

### Go Performer
- **VaultSwapPerformer**: Executes tasks on behalf of operators
- Multi-chain price monitoring and MEV detection
- FHE order processing and validation

## Task Types

### Core MEV Protection
- `mev_monitoring`: Real-time MEV detection and monitoring
- `cross_chain_price_sync`: Synchronize prices across chains
- `mev_opportunity_detection`: Detect profitable MEV opportunities

### Order Management
- `order_creation`: Create new trading orders
- `private_order_setup`: Set up FHE-encrypted private orders
- `order_validation`: Validate order parameters and signatures
- `fhe_order_processing`: Process encrypted orders using FHE

### Execution and Settlement
- `order_execution`: Execute validated orders
- `mev_distribution`: Distribute MEV profits to stakeholders
- `cross_chain_execution`: Execute cross-chain arbitrage

## Supported Chains

- Ethereum (Chain ID: 1)
- Arbitrum (Chain ID: 42161)
- Optimism (Chain ID: 10)
- Polygon (Chain ID: 137)
- Base (Chain ID: 8453)

## Installation

### Prerequisites
- Go 1.21+
- Foundry
- Node.js 18+

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd VaultSwap-Hook/avs
```

2. Install dependencies:
```bash
go mod tidy
```

3. Install Foundry dependencies:
```bash
forge install
```

## Deployment

### L1 Contracts (Ethereum)

```bash
# Deploy VaultSwapServiceManager
forge script script/DeployVaultSwapL1Contracts.s.sol:DeployVaultSwapL1Contracts --rpc-url <ethereum-rpc> --broadcast --verify
```

### L2 Contracts (Arbitrum/Optimism)

```bash
# Deploy VaultSwapTaskHook
forge script script/DeployVaultSwapL2Contracts.s.sol:DeployVaultSwapL2Contracts --rpc-url <l2-rpc> --broadcast --verify
```

## Running the Performer

1. Set environment variables:
```bash
export PRIVATE_KEY="your-private-key"
export ETHEREUM_RPC="https://mainnet.infura.io/v3/your-key"
export ARBITRUM_RPC="https://arb1.arbitrum.io/rpc"
# ... other chain RPCs
```

2. Run the performer:
```bash
go run cmd/main.go
```

## Configuration

### Task Fees
Task fees are dynamically calculated based on:
- Task complexity score
- Chain fee multiplier
- Base fee for task type

### MEV Distribution
- 85% to Liquidity Providers
- 10% to AVS Operators
- 3% Protocol Fee
- 2% Gas Compensation

## Testing

### Run Solidity Tests
```bash
forge test
```

### Run Go Tests
```bash
go test ./...
```

### Run Integration Tests
```bash
./test.sh
```

## Monitoring

The AVS provides comprehensive monitoring through:
- Task execution metrics
- MEV detection statistics
- Cross-chain price synchronization status
- Operator performance tracking

## Security

- All sensitive operations use FHE encryption
- Multi-signature validation for critical operations
- Comprehensive audit trails
- Regular security reviews

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For support and questions:
- GitHub Issues
- Discord: [VaultSwap Community]
- Documentation: [VaultSwap Docs]

## Roadmap

- [ ] Enhanced FHE integration
- [ ] Additional chain support
- [ ] Advanced MEV detection algorithms
- [ ] Cross-chain bridge optimization
- [ ] Institutional-grade compliance tools