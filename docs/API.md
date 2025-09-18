# VaultSwap Hook API Reference

## Overview

This document provides comprehensive API documentation for the VaultSwap Hook system, including smart contract interfaces, AVS APIs, and integration endpoints.

## Smart Contract APIs

### VaultSwapHook

The main hook contract that integrates with Uniswap V4.

#### Core Functions

**`initialize(address _owner, address _fheToken, address _serviceManager)`**
- Initializes the hook with owner, FHE token, and service manager
- **Parameters:**
  - `_owner`: Address of the contract owner
  - `_fheToken`: Address of the FHE token contract
  - `_serviceManager`: Address of the AVS service manager
- **Access:** Only owner
- **Events:** `HookInitialized(address owner, address fheToken, address serviceManager)`

**`beforeSwap(PoolKey calldata key, IPoolManager.SwapParams calldata params, bytes calldata hookData)`**
- Executes before a swap to implement MEV protection
- **Parameters:**
  - `key`: Pool key containing token addresses and fee tier
  - `params`: Swap parameters including amount and direction
  - `hookData`: Additional hook-specific data
- **Returns:** `bytes4` - Hook callback selector
- **Events:** `SwapExecuted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut)`

**`afterSwap(PoolKey calldata key, IPoolManager.SwapParams calldata params, BalanceDelta delta, bytes calldata hookData)`**
- Executes after a swap for post-processing
- **Parameters:**
  - `key`: Pool key
  - `params`: Swap parameters
  - `delta`: Balance changes from the swap
  - `hookData`: Additional hook data
- **Returns:** `bytes4` - Hook callback selector
- **Events:** `SwapCompleted(address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut)`

#### MEV Protection Functions

**`setMEVProtectionLevel(uint8 _level)`**
- Sets the MEV protection level (0-5)
- **Parameters:**
  - `_level`: Protection level (0=disabled, 5=maximum)
- **Access:** Only owner
- **Events:** `MEVProtectionLevelSet(uint8 oldLevel, uint8 newLevel)`

**`enableDecoyOrders(bool _enabled)`**
- Enables or disables decoy order generation
- **Parameters:**
  - `_enabled`: Whether to enable decoy orders
- **Access:** Only owner
- **Events:** `DecoyOrdersToggled(bool enabled)`

**`setMaxSlippage(uint256 _maxSlippage)`**
- Sets the maximum allowed slippage
- **Parameters:**
  - `_maxSlippage`: Maximum slippage in basis points
- **Access:** Only owner
- **Events:** `MaxSlippageSet(uint256 oldSlippage, uint256 newSlippage)`

#### Order Management Functions

**`createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline)`**
- Creates a new swap order
- **Parameters:**
  - `tokenIn`: Input token address
  - `tokenOut`: Output token address
  - `amountIn`: Input amount
  - `minAmountOut`: Minimum output amount
  - `deadline`: Order expiration timestamp
- **Returns:** `bytes32` - Order ID
- **Events:** `OrderCreated(bytes32 indexed orderId, address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline)`

**`executeOrder(bytes32 orderId)`**
- Executes a pending order
- **Parameters:**
  - `orderId`: ID of the order to execute
- **Access:** Only order owner or authorized executor
- **Events:** `OrderExecuted(bytes32 indexed orderId, address indexed executor, uint256 amountIn, uint256 amountOut)`

**`cancelOrder(bytes32 orderId)`**
- Cancels a pending order
- **Parameters:**
  - `orderId`: ID of the order to cancel
- **Access:** Only order owner
- **Events:** `OrderCancelled(bytes32 indexed orderId, address indexed user)`

#### View Functions

**`getOrder(bytes32 orderId) → (address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline, bool executed, bool cancelled)`**
- Retrieves order details
- **Parameters:**
  - `orderId`: Order ID
- **Returns:** Order details tuple

**`getUserOrders(address user) → bytes32[]`**
- Gets all orders for a user
- **Parameters:**
  - `user`: User address
- **Returns:** Array of order IDs

**`getMEVProtectionLevel() → uint8`**
- Returns current MEV protection level
- **Returns:** Current protection level (0-5)

**`isDecoyOrdersEnabled() → bool`**
- Checks if decoy orders are enabled
- **Returns:** True if decoy orders are enabled

### HybridFHERC20

FHE-enabled ERC20 token for privacy-preserving operations.

#### Core Functions

**`mint(address to, uint256 amount)`**
- Mints tokens to an address
- **Parameters:**
  - `to`: Recipient address
  - `amount`: Amount to mint
- **Access:** Only minter role
- **Events:** `Transfer(address(0), address to, uint256 amount)`

**`burn(uint256 amount)`**
- Burns tokens from caller's balance
- **Parameters:**
  - `amount`: Amount to burn
- **Events:** `Transfer(address caller, address(0), uint256 amount)`

**`encryptBalance(uint256 amount) → bytes`**
- Encrypts a balance amount using FHE
- **Parameters:**
  - `amount`: Amount to encrypt
- **Returns:** Encrypted balance data

**`decryptBalance(bytes calldata encryptedData) → uint256`**
- Decrypts balance data
- **Parameters:**
  - `encryptedData`: Encrypted balance data
- **Returns:** Decrypted amount
- **Access:** Only authorized decryptor

#### FHE Functions

**`setFHEKey(bytes calldata publicKey)`**
- Sets the FHE public key
- **Parameters:**
  - `publicKey`: FHE public key
- **Access:** Only owner
- **Events:** `FHEKeySet(bytes publicKey)`

**`enableFHE(bool enabled)`**
- Enables or disables FHE operations
- **Parameters:**
  - `enabled`: Whether to enable FHE
- **Access:** Only owner
- **Events:** `FHEEnabled(bool enabled)`

### VaultSwapServiceManager

EigenLayer AVS service manager for L1 operations.

#### Core Functions

**`registerOperator(address operator)`**
- Registers a new operator
- **Parameters:**
  - `operator`: Operator address
- **Access:** Only owner
- **Events:** `OperatorRegistered(address indexed operator)`

**`deregisterOperator(address operator)`**
- Deregisters an operator
- **Parameters:**
  - `operator`: Operator address
- **Access:** Only owner
- **Events:** `OperatorDeregistered(address indexed operator)`

**`submitTask(bytes32 taskId, bytes calldata taskData)`**
- Submits a new task
- **Parameters:**
  - `taskId`: Unique task identifier
  - `taskData`: Task data payload
- **Access:** Only registered operators
- **Events:** `TaskSubmitted(bytes32 indexed taskId, address indexed operator, bytes taskData)`

**`completeTask(bytes32 taskId, bytes calldata result)`**
- Completes a task with results
- **Parameters:**
  - `taskId`: Task identifier
  - `result`: Task result data
- **Access:** Only task submitter
- **Events:** `TaskCompleted(bytes32 indexed taskId, bytes result)`

### VaultSwapTaskHook

L2 task hook for cross-chain operations.

#### Core Functions

**`processTask(bytes32 taskId, bytes calldata taskData)`**
- Processes a task from L1
- **Parameters:**
  - `taskId`: Task identifier
  - `taskData`: Task data
- **Access:** Only authorized
- **Events:** `TaskProcessed(bytes32 indexed taskId, bytes taskData)`

**`submitResult(bytes32 taskId, bytes calldata result)`**
- Submits task result back to L1
- **Parameters:**
  - `taskId`: Task identifier
  - `result`: Result data
- **Access:** Only authorized
- **Events:** `ResultSubmitted(bytes32 indexed taskId, bytes result)`

## AVS APIs

### VaultSwapPerformer

Go-based AVS performer for off-chain task execution.

#### Configuration

**Environment Variables:**
- `L1_RPC_URL`: L1 RPC endpoint
- `L2_RPC_URL`: L2 RPC endpoint
- `PRIVATE_KEY`: Operator private key
- `SERVICE_MANAGER_ADDRESS`: L1 service manager address
- `TASK_HOOK_ADDRESS`: L2 task hook address

#### Task Types

**1. MEV Monitoring (`TaskTypeMEVMonitoring`)**
- Monitors for MEV opportunities
- Generates decoy orders
- Implements protection strategies

**2. Order Creation (`TaskTypeOrderCreation`)**
- Creates new swap orders
- Validates order parameters
- Submits to L1 service manager

**3. Order Execution (`TaskTypeOrderExecution`)**
- Executes pending orders
- Monitors execution conditions
- Handles order completion

**4. Cross-Chain Sync (`TaskTypeCrossChainSync`)**
- Synchronizes data between L1 and L2
- Monitors cross-chain messages
- Updates state across chains

#### API Endpoints

**`POST /api/v1/tasks`**
- Submit a new task
- **Body:**
  ```json
  {
    "type": "mev_monitoring",
    "data": {
      "pool_address": "0x...",
      "min_amount": "1000000000000000000",
      "max_slippage": "300"
    }
  }
  ```
- **Response:**
  ```json
  {
    "task_id": "0x...",
    "status": "submitted",
    "created_at": "2024-01-01T00:00:00Z"
  }
  ```

**`GET /api/v1/tasks/{taskId}`**
- Get task status
- **Response:**
  ```json
  {
    "task_id": "0x...",
    "type": "mev_monitoring",
    "status": "completed",
    "result": {
      "mev_opportunities": 5,
      "decoy_orders": 3
    },
    "created_at": "2024-01-01T00:00:00Z",
    "completed_at": "2024-01-01T00:05:00Z"
  }
  ```

**`GET /api/v1/orders`**
- List user orders
- **Query Parameters:**
  - `user`: User address
  - `status`: Order status (pending, executed, cancelled)
  - `limit`: Number of results (default: 50)
  - `offset`: Pagination offset
- **Response:**
  ```json
  {
    "orders": [
      {
        "order_id": "0x...",
        "user": "0x...",
        "token_in": "0x...",
        "token_out": "0x...",
        "amount_in": "1000000000000000000",
        "min_amount_out": "950000000000000000",
        "deadline": 1704067200,
        "status": "pending"
      }
    ],
    "total": 100,
    "limit": 50,
    "offset": 0
  }
  ```

## Integration Examples

### JavaScript/TypeScript

```typescript
import { ethers } from 'ethers';
import { VaultSwapHook__factory } from './contracts';

// Initialize provider and signer
const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Connect to contract
const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);

// Create an order
const tx = await hook.createOrder(
  TOKEN_IN,
  TOKEN_OUT,
  ethers.parseEther('1.0'),
  ethers.parseEther('0.95'),
  Math.floor(Date.now() / 1000) + 3600
);

await tx.wait();
```

### Python

```python
from web3 import Web3
from eth_account import Account

# Initialize Web3
w3 = Web3(Web3.HTTPProvider(RPC_URL))
account = Account.from_key(PRIVATE_KEY)

# Contract ABI and address
hook_abi = [...]  # Contract ABI
hook_address = "0x..."  # Contract address

# Create contract instance
hook = w3.eth.contract(address=hook_address, abi=hook_abi)

# Create an order
tx = hook.functions.createOrder(
    TOKEN_IN,
    TOKEN_OUT,
    Web3.to_wei(1, 'ether'),
    Web3.to_wei(0.95, 'ether'),
    int(time.time()) + 3600
).build_transaction({
    'from': account.address,
    'gas': 200000,
    'gasPrice': w3.eth.gas_price,
    'nonce': w3.eth.get_transaction_count(account.address)
})

signed_tx = account.sign_transaction(tx)
tx_hash = w3.eth.send_raw_transaction(signed_tx.rawTransaction)
```

### Go

```go
package main

import (
    "context"
    "crypto/ecdsa"
    "github.com/ethereum/go-ethereum/accounts/abi/bind"
    "github.com/ethereum/go-ethereum/common"
    "github.com/ethereum/go-ethereum/crypto"
    "github.com/ethereum/go-ethereum/ethclient"
)

func main() {
    // Connect to Ethereum
    client, err := ethclient.Dial(RPC_URL)
    if err != nil {
        log.Fatal(err)
    }

    // Load private key
    privateKey, err := crypto.HexToECDSA(PRIVATE_KEY)
    if err != nil {
        log.Fatal(err)
    }

    // Create auth
    auth, err := bind.NewKeyedTransactorWithChainID(privateKey, big.NewInt(CHAIN_ID))
    if err != nil {
        log.Fatal(err)
    }

    // Connect to contract
    hook, err := NewVaultSwapHook(common.HexToAddress(HOOK_ADDRESS), client)
    if err != nil {
        log.Fatal(err)
    }

    // Create an order
    tx, err := hook.CreateOrder(auth, TOKEN_IN, TOKEN_OUT, amountIn, minAmountOut, deadline)
    if err != nil {
        log.Fatal(err)
    }

    // Wait for transaction
    receipt, err := bind.WaitMined(context.Background(), client, tx)
    if err != nil {
        log.Fatal(err)
    }
}
```

## Error Codes

### Smart Contract Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `HookNotInitialized` | Hook not properly initialized | Call `initialize()` first |
| `InvalidOrder` | Order parameters are invalid | Check order parameters |
| `OrderExpired` | Order has passed deadline | Create new order |
| `InsufficientBalance` | Insufficient token balance | Ensure sufficient balance |
| `MEVProtectionFailed` | MEV protection check failed | Retry with different parameters |
| `Unauthorized` | Caller not authorized | Check permissions |
| `OrderAlreadyExecuted` | Order already executed | Check order status |
| `OrderCancelled` | Order was cancelled | Create new order |

### AVS Errors

| Error Code | Description | Solution |
|------------|-------------|----------|
| `TaskNotFound` | Task ID not found | Check task ID |
| `TaskAlreadyCompleted` | Task already completed | Check task status |
| `InvalidTaskData` | Task data is invalid | Validate task data |
| `OperatorNotRegistered` | Operator not registered | Register operator first |
| `CrossChainSyncFailed` | Cross-chain sync failed | Retry sync operation |

## Rate Limits

### Smart Contract
- No rate limits for contract calls
- Gas limits apply per transaction
- Block gas limits apply per block

### AVS APIs
- **Task Submission**: 100 requests/minute per operator
- **Order Queries**: 1000 requests/minute per IP
- **Status Checks**: 5000 requests/minute per IP

## Security Considerations

### Smart Contract Security
- All functions include access controls
- Input validation on all parameters
- Reentrancy protection implemented
- Integer overflow protection

### API Security
- Rate limiting on all endpoints
- Input validation and sanitization
- Authentication required for sensitive operations
- HTTPS only for production

## Support

For API issues:
- Check the [Error Codes](#error-codes) section
- Review the [Integration Examples](#integration-examples)
- Contact the development team
