# VaultSwap Hook Examples

This document provides practical examples of how to use VaultSwap Hook in various scenarios.

## Table of Contents

- [Basic Usage](#basic-usage)
- [MEV Protection](#mev-protection)
- [Privacy Features](#privacy-features)
- [Cross-Chain Operations](#cross-chain-operations)
- [AVS Integration](#avs-integration)
- [Advanced Examples](#advanced-examples)

## Basic Usage

### Creating a Simple Order

```typescript
import { ethers } from 'ethers';
import { VaultSwapHook__factory } from './contracts';

async function createSimpleOrder() {
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

### Executing an Order

```typescript
async function executeOrder(orderId: string) {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Execute order
    const tx = await hook.executeOrder(orderId);
    const receipt = await tx.wait();
    
    console.log('Order executed:', receipt.transactionHash);
}
```

### Checking Order Status

```typescript
async function getOrderStatus(orderId: string) {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
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

## MEV Protection

### Setting Protection Level

```typescript
async function setMEVProtection() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Set maximum protection level
    const tx = await hook.setMEVProtectionLevel(5);
    await tx.wait();
    
    console.log('MEV protection level set to maximum');
}
```

### Enabling Decoy Orders

```typescript
async function enableDecoyOrders() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Enable decoy order generation
    const tx = await hook.enableDecoyOrders(true);
    await tx.wait();
    
    console.log('Decoy orders enabled');
}
```

### Advanced MEV Protection

```typescript
async function advancedMEVProtection() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Set multiple protection parameters
    await hook.setMEVProtectionLevel(4);
    await hook.enableDecoyOrders(true);
    await hook.setMaxSlippage(300); // 3% max slippage
    
    // Create order with MEV protection
    const tx = await hook.createOrder(
        TOKEN_IN,
        TOKEN_OUT,
        ethers.parseEther('1.0'),
        ethers.parseEther('0.97'), // Higher minimum for protection
        Math.floor(Date.now() / 1000) + 1800 // 30 minutes
    );
    
    console.log('Order created with advanced MEV protection');
}
```

## Privacy Features

### Using FHE Token

```typescript
import { HybridFHERC20__factory } from './contracts';

async function useFHEToken() {
    const fheToken = HybridFHERC20__factory.connect(FHE_TOKEN_ADDRESS, signer);
    
    // Mint tokens
    const mintTx = await fheToken.mint(USER_ADDRESS, ethers.parseEther('100'));
    await mintTx.wait();
    
    // Encrypt balance
    const encryptedBalance = await fheToken.encryptBalance(ethers.parseEther('50'));
    console.log('Encrypted balance:', encryptedBalance);
    
    // Use encrypted balance in order
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    const tx = await hook.createOrderWithFHE(
        FHE_TOKEN_ADDRESS,
        TOKEN_OUT,
        encryptedBalance,
        ethers.parseEther('0.95'),
        Math.floor(Date.now() / 1000) + 3600
    );
    
    console.log('Order created with FHE privacy');
}
```

### Private Order Processing

```typescript
async function privateOrderProcessing() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Create private order
    const tx = await hook.createPrivateOrder(
        TOKEN_IN,
        TOKEN_OUT,
        ethers.parseEther('1.0'),
        ethers.parseEther('0.95'),
        Math.floor(Date.now() / 1000) + 3600,
        true // Enable privacy
    );
    
    const receipt = await tx.wait();
    console.log('Private order created:', receipt.logs[0].args.orderId);
}
```

## Cross-Chain Operations

### L1 to L2 Task Submission

```typescript
async function submitL1Task() {
    const serviceManager = VaultSwapServiceManager__factory.connect(
        SERVICE_MANAGER_ADDRESS, 
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

### L2 Task Processing

```typescript
async function processL2Task() {
    const taskHook = VaultSwapTaskHook__factory.connect(TASK_HOOK_ADDRESS, signer);
    
    // Process task on L2
    const taskData = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256', 'uint256'],
        [TOKEN_IN, ethers.parseEther('1.0'), Math.floor(Date.now() / 1000) + 3600]
    );
    
    const tx = await taskHook.processTask(
        ethers.keccak256(ethers.toUtf8Bytes('task-' + Date.now())),
        taskData
    );
    
    const receipt = await tx.wait();
    console.log('Task processed on L2:', receipt.transactionHash);
}
```

## AVS Integration

### Starting AVS Performer

```go
package main

import (
    "context"
    "log"
    "os"
    "os/signal"
    "syscall"
    "time"
)

func main() {
    // Initialize performer
    performer, err := NewVaultSwapPerformer()
    if err != nil {
        log.Fatal("Failed to initialize performer:", err)
    }
    
    // Start performer
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    
    go performer.Start(ctx)
    
    // Wait for shutdown signal
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    <-c
    
    log.Println("Shutting down performer...")
    cancel()
    time.Sleep(5 * time.Second)
}
```

### Custom Task Handler

```go
func (p *VaultSwapPerformer) handleCustomTask(task *Task) error {
    switch task.Type {
    case TaskTypeMEVMonitoring:
        return p.handleMEVMonitoring(task)
    case TaskTypeOrderCreation:
        return p.handleOrderCreation(task)
    case TaskTypeOrderExecution:
        return p.handleOrderExecution(task)
    case TaskTypeCrossChainSync:
        return p.handleCrossChainSync(task)
    default:
        return fmt.Errorf("unknown task type: %s", task.Type)
    }
}

func (p *VaultSwapPerformer) handleMEVMonitoring(task *Task) error {
    // Monitor for MEV opportunities
    opportunities, err := p.monitorMEVOpportunities(task.Data)
    if err != nil {
        return err
    }
    
    // Generate decoy orders if needed
    if len(opportunities) > 0 {
        decoyOrders, err := p.generateDecoyOrders(opportunities)
        if err != nil {
            return err
        }
        
        // Submit decoy orders
        for _, order := range decoyOrders {
            if err := p.submitOrder(order); err != nil {
                log.Printf("Failed to submit decoy order: %v", err)
            }
        }
    }
    
    return nil
}
```

## Advanced Examples

### Multi-Token Order

```typescript
async function createMultiTokenOrder() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Create order with multiple tokens
    const tokens = [TOKEN_A, TOKEN_B, TOKEN_C];
    const amounts = [
        ethers.parseEther('1.0'),
        ethers.parseEther('2.0'),
        ethers.parseEther('3.0')
    ];
    
    const tx = await hook.createMultiTokenOrder(
        tokens,
        amounts,
        TOKEN_OUT,
        ethers.parseEther('5.0'),
        Math.floor(Date.now() / 1000) + 3600
    );
    
    console.log('Multi-token order created');
}
```

### Batch Order Execution

```typescript
async function executeBatchOrders(orderIds: string[]) {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Execute multiple orders in batch
    const tx = await hook.executeBatchOrders(orderIds);
    const receipt = await tx.wait();
    
    console.log(`Executed ${orderIds.length} orders in batch`);
}
```

### Order with Custom Parameters

```typescript
async function createCustomOrder() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Create order with custom parameters
    const customParams = {
        maxSlippage: 200, // 2%
        priorityFee: ethers.parseEther('0.001'),
        deadline: Math.floor(Date.now() / 1000) + 1800,
        privacy: true,
        mevProtection: 4
    };
    
    const tx = await hook.createOrderWithParams(
        TOKEN_IN,
        TOKEN_OUT,
        ethers.parseEther('1.0'),
        ethers.parseEther('0.95'),
        customParams
    );
    
    console.log('Custom order created with parameters');
}
```

### Error Handling

```typescript
async function robustOrderCreation() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    try {
        // Create order with error handling
        const tx = await hook.createOrder(
            TOKEN_IN,
            TOKEN_OUT,
            ethers.parseEther('1.0'),
            ethers.parseEther('0.95'),
            Math.floor(Date.now() / 1000) + 3600
        );
        
        const receipt = await tx.wait();
        console.log('Order created successfully:', receipt.transactionHash);
        
    } catch (error) {
        if (error.code === 'INSUFFICIENT_BALANCE') {
            console.error('Insufficient token balance');
        } else if (error.code === 'INVALID_ORDER') {
            console.error('Invalid order parameters');
        } else if (error.code === 'ORDER_EXPIRED') {
            console.error('Order deadline has passed');
        } else {
            console.error('Unknown error:', error.message);
        }
    }
}
```

### Monitoring and Events

```typescript
async function monitorEvents() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
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
    
    hook.on('OrderCancelled', (orderId, user) => {
        console.log('Order cancelled:', { orderId, user });
    });
}
```

## Testing Examples

### Unit Test Example

```typescript
import { expect } from 'chai';
import { ethers } from 'ethers';

describe('VaultSwapHook', () => {
    let hook: VaultSwapHook;
    let owner: ethers.Wallet;
    let user: ethers.Wallet;
    
    beforeEach(async () => {
        // Deploy contract
        const VaultSwapHook = await ethers.getContractFactory('VaultSwapHook');
        hook = await VaultSwapHook.deploy();
        await hook.deployed();
        
        // Initialize
        await hook.initialize(owner.address, FHE_TOKEN_ADDRESS, SERVICE_MANAGER_ADDRESS);
    });
    
    it('should create an order', async () => {
        const tx = await hook.connect(user).createOrder(
            TOKEN_IN,
            TOKEN_OUT,
            ethers.parseEther('1.0'),
            ethers.parseEther('0.95'),
            Math.floor(Date.now() / 1000) + 3600
        );
        
        const receipt = await tx.wait();
        const event = receipt.events?.find(e => e.event === 'OrderCreated');
        
        expect(event).to.not.be.undefined;
        expect(event?.args?.user).to.equal(user.address);
    });
});
```

### Integration Test Example

```typescript
describe('VaultSwap Hook Integration', () => {
    it('should execute complete order flow', async () => {
        // 1. Create order
        const orderTx = await hook.createOrder(/* ... */);
        const orderReceipt = await orderTx.wait();
        const orderId = orderReceipt.events[0].args.orderId;
        
        // 2. Execute order
        const executeTx = await hook.executeOrder(orderId);
        const executeReceipt = await executeTx.wait();
        
        // 3. Verify execution
        const order = await hook.getOrder(orderId);
        expect(order.executed).to.be.true;
    });
});
```

## Performance Optimization

### Gas Optimization

```typescript
async function optimizedOrderCreation() {
    const hook = VaultSwapHook__factory.connect(HOOK_ADDRESS, signer);
    
    // Use batch operations to save gas
    const tx = await hook.batchCreateOrders([
        {
            tokenIn: TOKEN_A,
            tokenOut: TOKEN_B,
            amountIn: ethers.parseEther('1.0'),
            minAmountOut: ethers.parseEther('0.95'),
            deadline: Math.floor(Date.now() / 1000) + 3600
        },
        {
            tokenIn: TOKEN_B,
            tokenOut: TOKEN_C,
            amountIn: ethers.parseEther('2.0'),
            minAmountOut: ethers.parseEther('1.9'),
            deadline: Math.floor(Date.now() / 1000) + 3600
        }
    ]);
    
    console.log('Batch order creation completed');
}
```

### Memory Optimization

```go
func (p *VaultSwapPerformer) optimizedTaskProcessing() {
    // Use object pooling for frequent allocations
    taskPool := sync.Pool{
        New: func() interface{} {
            return &Task{}
        },
    }
    
    for {
        // Get task from pool
        task := taskPool.Get().(*Task)
        
        // Process task
        if err := p.processTask(task); err != nil {
            log.Printf("Task processing failed: %v", err)
        }
        
        // Reset and return to pool
        task.Reset()
        taskPool.Put(task)
    }
}
```

## Troubleshooting

### Common Issues

**1. Transaction Reverted**
```typescript
try {
    const tx = await hook.createOrder(/* ... */);
    await tx.wait();
} catch (error) {
    if (error.message.includes('execution reverted')) {
        console.error('Transaction reverted:', error.message);
    }
}
```

**2. Insufficient Gas**
```typescript
// Estimate gas before sending
const gasEstimate = await hook.estimateGas.createOrder(/* ... */);
const tx = await hook.createOrder(/* ... */, {
    gasLimit: gasEstimate.mul(120).div(100) // Add 20% buffer
});
```

**3. Network Issues**
```typescript
// Retry with exponential backoff
async function retryWithBackoff(fn: () => Promise<any>, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
        try {
            return await fn();
        } catch (error) {
            if (i === maxRetries - 1) throw error;
            await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
        }
    }
}
```

## Best Practices

1. **Always validate inputs** before creating orders
2. **Use appropriate gas limits** for transactions
3. **Handle errors gracefully** with proper error messages
4. **Monitor events** for order status updates
5. **Use batch operations** when possible for gas efficiency
6. **Test thoroughly** on testnets before mainnet
7. **Keep private keys secure** and never commit them
8. **Use environment variables** for configuration
9. **Implement proper logging** for debugging
10. **Follow security best practices** for smart contract interactions

For more examples and advanced usage, check out the [API Reference](API.md) and [Architecture Guide](ARCHITECTURE.md).
