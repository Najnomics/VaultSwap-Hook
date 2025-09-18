# VaultSwap Hook Tutorial

This tutorial will walk you through building a complete application using VaultSwap Hook.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Setup](#project-setup)
- [Building the Frontend](#building-the-frontend)
- [Integrating VaultSwap Hook](#integrating-vaultswap-hook)
- [Adding MEV Protection](#adding-mev-protection)
- [Implementing Privacy Features](#implementing-privacy-features)
- [Cross-Chain Integration](#cross-chain-integration)
- [Testing the Application](#testing-the-application)
- [Deployment](#deployment)

## Prerequisites

Before starting this tutorial, ensure you have:

- **Node.js**: 18+ with pnpm
- **Foundry**: Latest version
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development
- **Basic Knowledge**: TypeScript, React, and blockchain concepts

## Project Setup

### 1. Create a New Project

```bash
# Create new project directory
mkdir vaultswap-tutorial
cd vaultswap-tutorial

# Initialize package.json
pnpm init

# Install dependencies
pnpm add ethers @types/node typescript
pnpm add -D @types/react @types/react-dom
```

### 2. Set Up TypeScript

```bash
# Create tsconfig.json
cat > tsconfig.json << EOF
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
EOF
```

### 3. Create Project Structure

```bash
mkdir -p src/{components,contracts,utils,types}
mkdir -p public
```

## Building the Frontend

### 1. Create the Main App Component

```typescript
// src/App.tsx
import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { VaultSwapHook__factory } from './contracts';
import { OrderForm } from './components/OrderForm';
import { OrderList } from './components/OrderList';
import { MEVProtection } from './components/MEVProtection';

interface AppState {
  provider: ethers.Provider | null;
  signer: ethers.Signer | null;
  hook: any | null;
  account: string | null;
  orders: any[];
}

function App() {
  const [state, setState] = useState<AppState>({
    provider: null,
    signer: null,
    hook: null,
    account: null,
    orders: []
  });

  useEffect(() => {
    initializeApp();
  }, []);

  const initializeApp = async () => {
    try {
      // Check if MetaMask is installed
      if (typeof window.ethereum !== 'undefined') {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const signer = await provider.getSigner();
        const account = await signer.getAddress();

        // Connect to VaultSwap Hook contract
        const hook = VaultSwapHook__factory.connect(
          process.env.REACT_APP_HOOK_ADDRESS!,
          signer
        );

        setState({
          provider,
          signer,
          hook,
          account,
          orders: []
        });

        // Load existing orders
        await loadOrders(hook, account);
      } else {
        console.error('MetaMask not installed');
      }
    } catch (error) {
      console.error('Failed to initialize app:', error);
    }
  };

  const loadOrders = async (hook: any, account: string) => {
    try {
      const userOrders = await hook.getUserOrders(account);
      const orders = await Promise.all(
        userOrders.map(async (orderId: string) => {
          const order = await hook.getOrder(orderId);
          return {
            id: orderId,
            ...order
          };
        })
      );
      setState(prev => ({ ...prev, orders }));
    } catch (error) {
      console.error('Failed to load orders:', error);
    }
  };

  return (
    <div className="App">
      <header>
        <h1>VaultSwap Hook Tutorial</h1>
        {state.account && (
          <p>Connected: {state.account}</p>
        )}
      </header>
      
      <main>
        <MEVProtection hook={state.hook} />
        <OrderForm hook={state.hook} onOrderCreated={() => loadOrders(state.hook, state.account!)} />
        <OrderList orders={state.orders} hook={state.hook} />
      </main>
    </div>
  );
}

export default App;
```

### 2. Create the Order Form Component

```typescript
// src/components/OrderForm.tsx
import React, { useState } from 'react';
import { ethers } from 'ethers';

interface OrderFormProps {
  hook: any;
  onOrderCreated: () => void;
}

export function OrderForm({ hook, onOrderCreated }: OrderFormProps) {
  const [formData, setFormData] = useState({
    tokenIn: '',
    tokenOut: '',
    amountIn: '',
    minAmountOut: '',
    deadline: ''
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!hook) {
      alert('Please connect your wallet first');
      return;
    }

    try {
      const tx = await hook.createOrder(
        formData.tokenIn,
        formData.tokenOut,
        ethers.parseEther(formData.amountIn),
        ethers.parseEther(formData.minAmountOut),
        Math.floor(Date.now() / 1000) + parseInt(formData.deadline) * 3600
      );

      await tx.wait();
      alert('Order created successfully!');
      onOrderCreated();
      
      // Reset form
      setFormData({
        tokenIn: '',
        tokenOut: '',
        amountIn: '',
        minAmountOut: '',
        deadline: ''
      });
    } catch (error) {
      console.error('Failed to create order:', error);
      alert('Failed to create order. Please try again.');
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  return (
    <form onSubmit={handleSubmit} className="order-form">
      <h2>Create New Order</h2>
      
      <div className="form-group">
        <label htmlFor="tokenIn">Token In Address:</label>
        <input
          type="text"
          id="tokenIn"
          name="tokenIn"
          value={formData.tokenIn}
          onChange={handleChange}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="tokenOut">Token Out Address:</label>
        <input
          type="text"
          id="tokenOut"
          name="tokenOut"
          value={formData.tokenOut}
          onChange={handleChange}
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="amountIn">Amount In (ETH):</label>
        <input
          type="number"
          id="amountIn"
          name="amountIn"
          value={formData.amountIn}
          onChange={handleChange}
          step="0.001"
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="minAmountOut">Minimum Amount Out (ETH):</label>
        <input
          type="number"
          id="minAmountOut"
          name="minAmountOut"
          value={formData.minAmountOut}
          onChange={handleChange}
          step="0.001"
          required
        />
      </div>

      <div className="form-group">
        <label htmlFor="deadline">Deadline (hours):</label>
        <input
          type="number"
          id="deadline"
          name="deadline"
          value={formData.deadline}
          onChange={handleChange}
          min="1"
          required
        />
      </div>

      <button type="submit" className="submit-btn">
        Create Order
      </button>
    </form>
  );
}
```

### 3. Create the Order List Component

```typescript
// src/components/OrderList.tsx
import React from 'react';
import { ethers } from 'ethers';

interface Order {
  id: string;
  user: string;
  tokenIn: string;
  tokenOut: string;
  amountIn: ethers.BigNumber;
  minAmountOut: ethers.BigNumber;
  deadline: ethers.BigNumber;
  executed: boolean;
  cancelled: boolean;
}

interface OrderListProps {
  orders: Order[];
  hook: any;
}

export function OrderList({ orders, hook }: OrderListProps) {
  const executeOrder = async (orderId: string) => {
    if (!hook) return;

    try {
      const tx = await hook.executeOrder(orderId);
      await tx.wait();
      alert('Order executed successfully!');
    } catch (error) {
      console.error('Failed to execute order:', error);
      alert('Failed to execute order. Please try again.');
    }
  };

  const cancelOrder = async (orderId: string) => {
    if (!hook) return;

    try {
      const tx = await hook.cancelOrder(orderId);
      await tx.wait();
      alert('Order cancelled successfully!');
    } catch (error) {
      console.error('Failed to cancel order:', error);
      alert('Failed to cancel order. Please try again.');
    }
  };

  return (
    <div className="order-list">
      <h2>Your Orders</h2>
      
      {orders.length === 0 ? (
        <p>No orders found. Create your first order above!</p>
      ) : (
        <div className="orders">
          {orders.map((order) => (
            <div key={order.id} className="order-item">
              <div className="order-info">
                <p><strong>Order ID:</strong> {order.id}</p>
                <p><strong>Token In:</strong> {order.tokenIn}</p>
                <p><strong>Token Out:</strong> {order.tokenOut}</p>
                <p><strong>Amount In:</strong> {ethers.formatEther(order.amountIn)} ETH</p>
                <p><strong>Min Amount Out:</strong> {ethers.formatEther(order.minAmountOut)} ETH</p>
                <p><strong>Deadline:</strong> {new Date(Number(order.deadline) * 1000).toLocaleString()}</p>
                <p><strong>Status:</strong> {
                  order.executed ? 'Executed' : 
                  order.cancelled ? 'Cancelled' : 
                  'Pending'
                }</p>
              </div>
              
              <div className="order-actions">
                {!order.executed && !order.cancelled && (
                  <>
                    <button 
                      onClick={() => executeOrder(order.id)}
                      className="execute-btn"
                    >
                      Execute
                    </button>
                    <button 
                      onClick={() => cancelOrder(order.id)}
                      className="cancel-btn"
                    >
                      Cancel
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
```

## Integrating VaultSwap Hook

### 1. Set Up Contract Interfaces

```typescript
// src/contracts/VaultSwapHook.ts
import { ethers } from 'ethers';

export const VaultSwapHookABI = [
  "function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline) external returns (bytes32)",
  "function executeOrder(bytes32 orderId) external",
  "function cancelOrder(bytes32 orderId) external",
  "function getOrder(bytes32 orderId) external view returns (address user, address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline, bool executed, bool cancelled)",
  "function getUserOrders(address user) external view returns (bytes32[])",
  "function setMEVProtectionLevel(uint8 level) external",
  "function enableDecoyOrders(bool enabled) external",
  "function setMaxSlippage(uint256 maxSlippage) external",
  "event OrderCreated(bytes32 indexed orderId, address indexed user, address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline)",
  "event OrderExecuted(bytes32 indexed orderId, address indexed executor, uint256 amountIn, uint256 amountOut)",
  "event OrderCancelled(bytes32 indexed orderId, address indexed user)"
];

export class VaultSwapHook {
  private contract: ethers.Contract;

  constructor(address: string, signer: ethers.Signer) {
    this.contract = new ethers.Contract(address, VaultSwapHookABI, signer);
  }

  async createOrder(
    tokenIn: string,
    tokenOut: string,
    amountIn: ethers.BigNumber,
    minAmountOut: ethers.BigNumber,
    deadline: number
  ): Promise<ethers.TransactionResponse> {
    return this.contract.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
  }

  async executeOrder(orderId: string): Promise<ethers.TransactionResponse> {
    return this.contract.executeOrder(orderId);
  }

  async cancelOrder(orderId: string): Promise<ethers.TransactionResponse> {
    return this.contract.cancelOrder(orderId);
  }

  async getOrder(orderId: string): Promise<any> {
    return this.contract.getOrder(orderId);
  }

  async getUserOrders(user: string): Promise<string[]> {
    return this.contract.getUserOrders(user);
  }

  async setMEVProtectionLevel(level: number): Promise<ethers.TransactionResponse> {
    return this.contract.setMEVProtectionLevel(level);
  }

  async enableDecoyOrders(enabled: boolean): Promise<ethers.TransactionResponse> {
    return this.contract.enableDecoyOrders(enabled);
  }

  async setMaxSlippage(maxSlippage: ethers.BigNumber): Promise<ethers.TransactionResponse> {
    return this.contract.setMaxSlippage(maxSlippage);
  }

  on(event: string, listener: (...args: any[]) => void) {
    this.contract.on(event, listener);
  }

  off(event: string, listener: (...args: any[]) => void) {
    this.contract.off(event, listener);
  }
}
```

### 2. Create Utility Functions

```typescript
// src/utils/contracts.ts
import { ethers } from 'ethers';
import { VaultSwapHook } from '../contracts/VaultSwapHook';

export async function connectToVaultSwapHook(
  address: string,
  signer: ethers.Signer
): Promise<VaultSwapHook> {
  return new VaultSwapHook(address, signer);
}

export async function getTokenBalance(
  tokenAddress: string,
  userAddress: string,
  provider: ethers.Provider
): Promise<ethers.BigNumber> {
  const tokenContract = new ethers.Contract(
    tokenAddress,
    ['function balanceOf(address) view returns (uint256)'],
    provider
  );
  
  return tokenContract.balanceOf(userAddress);
}

export async function approveToken(
  tokenAddress: string,
  spenderAddress: string,
  amount: ethers.BigNumber,
  signer: ethers.Signer
): Promise<ethers.TransactionResponse> {
  const tokenContract = new ethers.Contract(
    tokenAddress,
    ['function approve(address,uint256) returns (bool)'],
    signer
  );
  
  return tokenContract.approve(spenderAddress, amount);
}
```

## Adding MEV Protection

### 1. Create MEV Protection Component

```typescript
// src/components/MEVProtection.tsx
import React, { useState, useEffect } from 'react';

interface MEVProtectionProps {
  hook: any;
}

export function MEVProtection({ hook }: MEVProtectionProps) {
  const [protectionLevel, setProtectionLevel] = useState(0);
  const [decoyOrders, setDecoyOrders] = useState(false);
  const [maxSlippage, setMaxSlippage] = useState(300); // 3%

  useEffect(() => {
    if (hook) {
      loadMEVSettings();
    }
  }, [hook]);

  const loadMEVSettings = async () => {
    try {
      const level = await hook.getMEVProtectionLevel();
      const decoyEnabled = await hook.isDecoyOrdersEnabled();
      const slippage = await hook.getMaxSlippage();
      
      setProtectionLevel(Number(level));
      setDecoyOrders(decoyEnabled);
      setMaxSlippage(Number(slippage));
    } catch (error) {
      console.error('Failed to load MEV settings:', error);
    }
  };

  const updateProtectionLevel = async (level: number) => {
    if (!hook) return;

    try {
      await hook.setMEVProtectionLevel(level);
      setProtectionLevel(level);
      alert('MEV protection level updated!');
    } catch (error) {
      console.error('Failed to update protection level:', error);
      alert('Failed to update protection level. Please try again.');
    }
  };

  const toggleDecoyOrders = async (enabled: boolean) => {
    if (!hook) return;

    try {
      await hook.enableDecoyOrders(enabled);
      setDecoyOrders(enabled);
      alert('Decoy orders setting updated!');
    } catch (error) {
      console.error('Failed to toggle decoy orders:', error);
      alert('Failed to update decoy orders setting. Please try again.');
    }
  };

  const updateMaxSlippage = async (slippage: number) => {
    if (!hook) return;

    try {
      await hook.setMaxSlippage(ethers.parseUnits(slippage.toString(), 2));
      setMaxSlippage(slippage);
      alert('Max slippage updated!');
    } catch (error) {
      console.error('Failed to update max slippage:', error);
      alert('Failed to update max slippage. Please try again.');
    }
  };

  return (
    <div className="mev-protection">
      <h2>MEV Protection Settings</h2>
      
      <div className="setting-group">
        <label htmlFor="protection-level">Protection Level (0-5):</label>
        <input
          type="range"
          id="protection-level"
          min="0"
          max="5"
          value={protectionLevel}
          onChange={(e) => updateProtectionLevel(parseInt(e.target.value))}
        />
        <span>{protectionLevel}</span>
      </div>

      <div className="setting-group">
        <label>
          <input
            type="checkbox"
            checked={decoyOrders}
            onChange={(e) => toggleDecoyOrders(e.target.checked)}
          />
          Enable Decoy Orders
        </label>
      </div>

      <div className="setting-group">
        <label htmlFor="max-slippage">Max Slippage (basis points):</label>
        <input
          type="number"
          id="max-slippage"
          min="0"
          max="10000"
          value={maxSlippage}
          onChange={(e) => updateMaxSlippage(parseInt(e.target.value))}
        />
        <span>{maxSlippage / 100}%</span>
      </div>
    </div>
  );
}
```

## Implementing Privacy Features

### 1. Create Privacy Component

```typescript
// src/components/PrivacyFeatures.tsx
import React, { useState } from 'react';
import { ethers } from 'ethers';

interface PrivacyFeaturesProps {
  hook: any;
  fheToken: any;
}

export function PrivacyFeatures({ hook, fheToken }: PrivacyFeaturesProps) {
  const [encryptedBalance, setEncryptedBalance] = useState<string>('');
  const [privateOrder, setPrivateOrder] = useState({
    tokenIn: '',
    tokenOut: '',
    amountIn: '',
    minAmountOut: '',
    deadline: ''
  });

  const encryptBalance = async (amount: string) => {
    if (!fheToken) return;

    try {
      const encrypted = await fheToken.encryptBalance(ethers.parseEther(amount));
      setEncryptedBalance(encrypted);
      alert('Balance encrypted successfully!');
    } catch (error) {
      console.error('Failed to encrypt balance:', error);
      alert('Failed to encrypt balance. Please try again.');
    }
  };

  const createPrivateOrder = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!hook || !fheToken) {
      alert('Please connect your wallet first');
      return;
    }

    try {
      // Encrypt the order amount
      const encryptedAmount = await fheToken.encryptBalance(
        ethers.parseEther(privateOrder.amountIn)
      );

      // Create private order
      const tx = await hook.createPrivateOrder(
        privateOrder.tokenIn,
        privateOrder.tokenOut,
        encryptedAmount,
        ethers.parseEther(privateOrder.minAmountOut),
        Math.floor(Date.now() / 1000) + parseInt(privateOrder.deadline) * 3600,
        true // Enable privacy
      );

      await tx.wait();
      alert('Private order created successfully!');
      
      // Reset form
      setPrivateOrder({
        tokenIn: '',
        tokenOut: '',
        amountIn: '',
        minAmountOut: '',
        deadline: ''
      });
    } catch (error) {
      console.error('Failed to create private order:', error);
      alert('Failed to create private order. Please try again.');
    }
  };

  return (
    <div className="privacy-features">
      <h2>Privacy Features</h2>
      
      <div className="privacy-section">
        <h3>FHE Balance Encryption</h3>
        <div className="encrypt-balance">
          <input
            type="number"
            placeholder="Amount to encrypt (ETH)"
            onChange={(e) => encryptBalance(e.target.value)}
          />
          {encryptedBalance && (
            <div className="encrypted-result">
              <p>Encrypted Balance:</p>
              <code>{encryptedBalance}</code>
            </div>
          )}
        </div>
      </div>

      <div className="privacy-section">
        <h3>Private Order Creation</h3>
        <form onSubmit={createPrivateOrder} className="private-order-form">
          <div className="form-group">
            <label htmlFor="private-tokenIn">Token In Address:</label>
            <input
              type="text"
              id="private-tokenIn"
              value={privateOrder.tokenIn}
              onChange={(e) => setPrivateOrder({...privateOrder, tokenIn: e.target.value})}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="private-tokenOut">Token Out Address:</label>
            <input
              type="text"
              id="private-tokenOut"
              value={privateOrder.tokenOut}
              onChange={(e) => setPrivateOrder({...privateOrder, tokenOut: e.target.value})}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="private-amountIn">Amount In (ETH):</label>
            <input
              type="number"
              id="private-amountIn"
              value={privateOrder.amountIn}
              onChange={(e) => setPrivateOrder({...privateOrder, amountIn: e.target.value})}
              step="0.001"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="private-minAmountOut">Minimum Amount Out (ETH):</label>
            <input
              type="number"
              id="private-minAmountOut"
              value={privateOrder.minAmountOut}
              onChange={(e) => setPrivateOrder({...privateOrder, minAmountOut: e.target.value})}
              step="0.001"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="private-deadline">Deadline (hours):</label>
            <input
              type="number"
              id="private-deadline"
              value={privateOrder.deadline}
              onChange={(e) => setPrivateOrder({...privateOrder, deadline: e.target.value})}
              min="1"
              required
            />
          </div>

          <button type="submit" className="submit-btn">
            Create Private Order
          </button>
        </form>
      </div>
    </div>
  );
}
```

## Cross-Chain Integration

### 1. Create Cross-Chain Component

```typescript
// src/components/CrossChain.tsx
import React, { useState } from 'react';
import { ethers } from 'ethers';

interface CrossChainProps {
  serviceManager: any;
  taskHook: any;
}

export function CrossChain({ serviceManager, taskHook }: CrossChainProps) {
  const [taskData, setTaskData] = useState({
    tokenIn: '',
    amountIn: '',
    deadline: ''
  });

  const submitL1Task = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!serviceManager) {
      alert('Service manager not connected');
      return;
    }

    try {
      const taskDataEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256', 'uint256'],
        [
          taskData.tokenIn,
          ethers.parseEther(taskData.amountIn),
          Math.floor(Date.now() / 1000) + parseInt(taskData.deadline) * 3600
        ]
      );

      const taskId = ethers.keccak256(ethers.toUtf8Bytes('task-' + Date.now()));
      
      const tx = await serviceManager.submitTask(taskId, taskDataEncoded);
      await tx.wait();
      
      alert('Task submitted to L1 successfully!');
      
      // Reset form
      setTaskData({
        tokenIn: '',
        amountIn: '',
        deadline: ''
      });
    } catch (error) {
      console.error('Failed to submit L1 task:', error);
      alert('Failed to submit L1 task. Please try again.');
    }
  };

  const processL2Task = async (taskId: string) => {
    if (!taskHook) {
      alert('Task hook not connected');
      return;
    }

    try {
      const taskDataEncoded = ethers.AbiCoder.defaultAbiCoder().encode(
        ['address', 'uint256', 'uint256'],
        [
          taskData.tokenIn,
          ethers.parseEther(taskData.amountIn),
          Math.floor(Date.now() / 1000) + parseInt(taskData.deadline) * 3600
        ]
      );

      const tx = await taskHook.processTask(taskId, taskDataEncoded);
      await tx.wait();
      
      alert('Task processed on L2 successfully!');
    } catch (error) {
      console.error('Failed to process L2 task:', error);
      alert('Failed to process L2 task. Please try again.');
    }
  };

  return (
    <div className="cross-chain">
      <h2>Cross-Chain Operations</h2>
      
      <div className="l1-section">
        <h3>L1 Task Submission</h3>
        <form onSubmit={submitL1Task} className="task-form">
          <div className="form-group">
            <label htmlFor="task-tokenIn">Token In Address:</label>
            <input
              type="text"
              id="task-tokenIn"
              value={taskData.tokenIn}
              onChange={(e) => setTaskData({...taskData, tokenIn: e.target.value})}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="task-amountIn">Amount In (ETH):</label>
            <input
              type="number"
              id="task-amountIn"
              value={taskData.amountIn}
              onChange={(e) => setTaskData({...taskData, amountIn: e.target.value})}
              step="0.001"
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="task-deadline">Deadline (hours):</label>
            <input
              type="number"
              id="task-deadline"
              value={taskData.deadline}
              onChange={(e) => setTaskData({...taskData, deadline: e.target.value})}
              min="1"
              required
            />
          </div>

          <button type="submit" className="submit-btn">
            Submit L1 Task
          </button>
        </form>
      </div>

      <div className="l2-section">
        <h3>L2 Task Processing</h3>
        <button 
          onClick={() => processL2Task('task-' + Date.now())}
          className="process-btn"
        >
          Process L2 Task
        </button>
      </div>
    </div>
  );
}
```

## Testing the Application

### 1. Create Test Suite

```typescript
// src/tests/VaultSwapHook.test.ts
import { ethers } from 'ethers';
import { VaultSwapHook } from '../contracts/VaultSwapHook';

describe('VaultSwap Hook Integration', () => {
  let provider: ethers.Provider;
  let signer: ethers.Signer;
  let hook: VaultSwapHook;

  beforeEach(async () => {
    // Set up test environment
    provider = new ethers.JsonRpcProvider('http://localhost:8545');
    signer = await provider.getSigner();
    hook = new VaultSwapHook(process.env.HOOK_ADDRESS!, signer);
  });

  it('should create an order', async () => {
    const tx = await hook.createOrder(
      '0x...', // Token In
      '0x...', // Token Out
      ethers.parseEther('1.0'),
      ethers.parseEther('0.95'),
      Math.floor(Date.now() / 1000) + 3600
    );

    const receipt = await tx.wait();
    expect(receipt.status).toBe(1);
  });

  it('should set MEV protection level', async () => {
    const tx = await hook.setMEVProtectionLevel(5);
    const receipt = await tx.wait();
    expect(receipt.status).toBe(1);
  });

  it('should enable decoy orders', async () => {
    const tx = await hook.enableDecoyOrders(true);
    const receipt = await tx.wait();
    expect(receipt.status).toBe(1);
  });
});
```

### 2. Run Tests

```bash
# Install testing dependencies
pnpm add -D jest @types/jest ts-jest

# Create jest.config.js
cat > jest.config.js << EOF
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.ts', '**/?(*.)+(spec|test).ts'],
  transform: {
    '^.+\\.ts$': 'ts-jest',
  },
};
EOF

# Run tests
pnpm test
```

## Deployment

### 1. Build the Application

```bash
# Build TypeScript
pnpm build

# Build for production
pnpm build:prod
```

### 2. Deploy to Vercel

```bash
# Install Vercel CLI
npm i -g vercel

# Deploy
vercel --prod
```

### 3. Deploy to Netlify

```bash
# Install Netlify CLI
npm i -g netlify-cli

# Deploy
netlify deploy --prod
```

## Conclusion

This tutorial has shown you how to build a complete application using VaultSwap Hook. You've learned how to:

1. **Set up a project** with TypeScript and React
2. **Integrate VaultSwap Hook** for order management
3. **Add MEV protection** features
4. **Implement privacy** with FHE
5. **Handle cross-chain** operations
6. **Test and deploy** your application

### Next Steps

- **Explore Advanced Features**: Check out the [Examples](EXAMPLES.md) for more advanced usage
- **Read the Documentation**: Dive deeper with the [API Reference](API.md)
- **Join the Community**: Get help and share your projects on [Discord](https://discord.gg/vaultswap)

### Resources

- **[VaultSwap Hook Documentation](README.md)**
- **[API Reference](API.md)**
- **[Examples](EXAMPLES.md)**
- **[GitHub Repository](https://github.com/VaultSwap/VaultSwap-Hook)**

---

**Ready to build more?** Check out our [Advanced Examples](EXAMPLES.md) or [API Reference](API.md).

**Have questions?** Visit our [FAQ](FAQ.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

---

*This tutorial is regularly updated. Last updated: January 1, 2024*
