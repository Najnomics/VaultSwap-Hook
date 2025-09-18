# VaultSwap Hook Testing Guide

This guide covers testing strategies and best practices for VaultSwap Hook.

## Table of Contents

- [Overview](#overview)
- [Testing Strategy](#testing-strategy)
- [Unit Testing](#unit-testing)
- [Integration Testing](#integration-testing)
- [End-to-End Testing](#end-to-end-testing)
- [Performance Testing](#performance-testing)
- [Security Testing](#security-testing)
- [Test Automation](#test-automation)

## Overview

Testing VaultSwap Hook ensures:
- **Functionality**: All features work as expected
- **Reliability**: System is stable and robust
- **Security**: No vulnerabilities or exploits
- **Performance**: Meets performance requirements
- **Quality**: High-quality, production-ready code

## Testing Strategy

### 1. Testing Pyramid

**Unit Tests (70%)**:
- Test individual functions and methods
- Fast execution
- High coverage
- Isolated testing

**Integration Tests (20%)**:
- Test component interactions
- Medium execution time
- Moderate coverage
- System-level testing

**End-to-End Tests (10%)**:
- Test complete user workflows
- Slow execution
- Low coverage
- Full system testing

### 2. Testing Types

**Functional Testing**:
- Order creation and execution
- MEV protection features
- Privacy features
- Cross-chain operations

**Non-Functional Testing**:
- Performance testing
- Security testing
- Load testing
- Stress testing

**Regression Testing**:
- Ensure existing functionality works
- Prevent new bugs from being introduced
- Maintain system stability

## Unit Testing

### 1. Solidity Unit Tests

**Test Structure**:
```solidity
// test/VaultSwapHook.t.sol
import "forge-std/Test.sol";
import "../src/VaultSwapHook.sol";

contract VaultSwapHookTest is Test {
    VaultSwapHook public hook;
    address public owner;
    address public user;
    
    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");
        
        vm.prank(owner);
        hook = new VaultSwapHook();
    }
    
    function testCreateOrder() public {
        // Test order creation
    }
    
    function testCreateOrderReverts() public {
        // Test order creation failures
    }
}
```

**Test Examples**:
```solidity
function testCreateOrder() public {
    // Arrange
    address tokenIn = makeAddr("tokenIn");
    address tokenOut = makeAddr("tokenOut");
    uint256 amountIn = 1e18;
    uint256 minAmountOut = 95e16;
    uint256 deadline = block.timestamp + 3600;
    
    // Act
    vm.prank(user);
    bytes32 orderId = hook.createOrder(
        tokenIn,
        tokenOut,
        amountIn,
        minAmountOut,
        deadline
    );
    
    // Assert
    assertTrue(orderId != bytes32(0));
    
    (address orderUser, address inToken, address outToken, uint256 amount) = hook.getOrder(orderId);
    assertEq(orderUser, user);
    assertEq(inToken, tokenIn);
    assertEq(outToken, tokenOut);
    assertEq(amount, amountIn);
}

function testCreateOrderRevertsWhenTokenInIsZero() public {
    // Arrange
    address tokenIn = address(0);
    address tokenOut = makeAddr("tokenOut");
    uint256 amountIn = 1e18;
    uint256 minAmountOut = 95e16;
    uint256 deadline = block.timestamp + 3600;
    
    // Act & Assert
    vm.prank(user);
    vm.expectRevert("Invalid tokenIn");
    hook.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
}

function testCreateOrderRevertsWhenAmountInIsZero() public {
    // Arrange
    address tokenIn = makeAddr("tokenIn");
    address tokenOut = makeAddr("tokenOut");
    uint256 amountIn = 0;
    uint256 minAmountOut = 95e16;
    uint256 deadline = block.timestamp + 3600;
    
    // Act & Assert
    vm.prank(user);
    vm.expectRevert("Amount must be positive");
    hook.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
}
```

### 2. Go Unit Tests

**Test Structure**:
```go
// cmd/main_test.go
package main

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

func TestCreateOrder(t *testing.T) {
    // Arrange
    performer := NewVaultSwapPerformer()
    tokenIn := common.HexToAddress("0x1")
    tokenOut := common.HexToAddress("0x2")
    amountIn := big.NewInt(1e18)
    
    // Act
    orderId, err := performer.CreateOrder(tokenIn, tokenOut, amountIn)
    
    // Assert
    assert.NoError(t, err)
    assert.NotEqual(t, common.Hash{}, orderId)
}

func TestCreateOrderWithInvalidInput(t *testing.T) {
    // Arrange
    performer := NewVaultSwapPerformer()
    tokenIn := common.Address{}
    tokenOut := common.HexToAddress("0x2")
    amountIn := big.NewInt(1e18)
    
    // Act
    orderId, err := performer.CreateOrder(tokenIn, tokenOut, amountIn)
    
    // Assert
    assert.Error(t, err)
    assert.Equal(t, common.Hash{}, orderId)
    assert.Contains(t, err.Error(), "invalid tokenIn address")
}
```

**Mock Testing**:
```go
// mocks/mock_performer.go
type MockPerformer struct {
    mock.Mock
}

func (m *MockPerformer) CreateOrder(tokenIn, tokenOut common.Address, amountIn *big.Int) (*big.Int, error) {
    args := m.Called(tokenIn, tokenOut, amountIn)
    return args.Get(0).(*big.Int), args.Error(1)
}

func (m *MockPerformer) ExecuteOrder(orderId common.Hash) error {
    args := m.Called(orderId)
    return args.Error(0)
}

// Test with mock
func TestOrderExecution(t *testing.T) {
    // Arrange
    mockPerformer := new(MockPerformer)
    orderId := common.HexToHash("0x123")
    
    mockPerformer.On("ExecuteOrder", orderId).Return(nil)
    
    // Act
    err := mockPerformer.ExecuteOrder(orderId)
    
    // Assert
    assert.NoError(t, err)
    mockPerformer.AssertExpectations(t)
}
```

### 3. TypeScript Unit Tests

**Test Structure**:
```typescript
// test/VaultSwapHook.test.ts
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { VaultSwapHook } from '../src/VaultSwapHook';
import { ethers } from 'ethers';

describe('VaultSwapHook', () => {
  let hook: VaultSwapHook;
  let mockProvider: ethers.Provider;
  let mockSigner: ethers.Signer;
  
  beforeEach(() => {
    mockProvider = vi.fn() as any;
    mockSigner = vi.fn() as any;
    hook = new VaultSwapHook('0x...', mockSigner);
  });
  
  it('should create an order', async () => {
    // Arrange
    const tokenIn = '0x1';
    const tokenOut = '0x2';
    const amountIn = ethers.parseEther('1.0');
    const minAmountOut = ethers.parseEther('0.95');
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    
    // Act
    const tx = await hook.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
    
    // Assert
    expect(tx).toBeDefined();
    expect(tx.hash).toBeDefined();
  });
  
  it('should revert when tokenIn is zero address', async () => {
    // Arrange
    const tokenIn = ethers.ZeroAddress;
    const tokenOut = '0x2';
    const amountIn = ethers.parseEther('1.0');
    const minAmountOut = ethers.parseEther('0.95');
    const deadline = Math.floor(Date.now() / 1000) + 3600;
    
    // Act & Assert
    await expect(
      hook.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline)
    ).rejects.toThrow('Invalid tokenIn');
  });
});
```

## Integration Testing

### 1. Smart Contract Integration

**Test Contract Interactions**:
```solidity
// test/IntegrationTest.t.sol
contract IntegrationTest is Test {
    VaultSwapHook public hook;
    HybridFHERC20 public fheToken;
    VaultSwapServiceManager public serviceManager;
    
    function setUp() public {
        // Deploy all contracts
        hook = new VaultSwapHook();
        fheToken = new HybridFHERC20();
        serviceManager = new VaultSwapServiceManager();
        
        // Initialize contracts
        hook.initialize(address(fheToken), address(serviceManager));
    }
    
    function testOrderCreationWithFHE() public {
        // Test order creation with FHE token
    }
    
    function testCrossChainTaskSubmission() public {
        // Test cross-chain task submission
    }
}
```

### 2. AVS Integration

**Test AVS Components**:
```go
// integration/avs_test.go
func TestAVSIntegration(t *testing.T) {
    // Arrange
    performer := NewVaultSwapPerformer()
    serviceManager := NewVaultSwapServiceManager()
    
    // Act
    taskID, err := serviceManager.SubmitTask("mev_monitoring", taskData)
    assert.NoError(t, err)
    
    // Process task
    result, err := performer.ProcessTask(taskID)
    assert.NoError(t, err)
    
    // Assert
    assert.NotNil(t, result)
    assert.Equal(t, "completed", result.Status)
}
```

### 3. Cross-Chain Integration

**Test Cross-Chain Operations**:
```go
// integration/crosschain_test.go
func TestCrossChainIntegration(t *testing.T) {
    // Arrange
    l1Client := ethclient.Dial("http://localhost:8545")
    l2Client := ethclient.Dial("http://localhost:8546")
    
    // Act
    // Submit task on L1
    taskID, err := submitL1Task(l1Client)
    assert.NoError(t, err)
    
    // Process task on L2
    result, err := processL2Task(l2Client, taskID)
    assert.NoError(t, err)
    
    // Assert
    assert.NotNil(t, result)
    assert.Equal(t, "completed", result.Status)
}
```

## End-to-End Testing

### 1. Complete Workflow Testing

**Test Full User Journey**:
```typescript
// e2e/FullFlow.test.ts
describe('VaultSwap Hook E2E', () => {
  it('should complete full order workflow', async () => {
    // 1. Connect wallet
    await connectWallet();
    
    // 2. Set MEV protection
    await setMEVProtection(5);
    
    // 3. Create order
    const orderId = await createOrder({
      tokenIn: '0x1',
      tokenOut: '0x2',
      amountIn: '1.0',
      minAmountOut: '0.95',
      deadline: 3600
    });
    
    // 4. Wait for order processing
    await waitForOrderProcessing(orderId);
    
    // 5. Execute order
    const result = await executeOrder(orderId);
    
    // 6. Verify execution
    expect(result.success).toBe(true);
    expect(result.amountOut).toBeGreaterThan(0);
  });
});
```

### 2. Cross-Chain E2E Testing

**Test Cross-Chain Workflow**:
```go
// e2e/crosschain_test.go
func TestCrossChainE2E(t *testing.T) {
    // 1. Start L1 and L2 networks
    l1Network := startL1Network()
    l2Network := startL2Network()
    
    // 2. Deploy contracts
    l1Contracts := deployL1Contracts(l1Network)
    l2Contracts := deployL2Contracts(l2Network)
    
    // 3. Start AVS performer
    performer := startAVSPerformer(l1Contracts, l2Contracts)
    
    // 4. Submit cross-chain task
    taskID, err := submitCrossChainTask(l1Contracts)
    assert.NoError(t, err)
    
    // 5. Wait for task processing
    result, err := waitForTaskCompletion(performer, taskID)
    assert.NoError(t, err)
    
    // 6. Verify cross-chain sync
    assert.Equal(t, "completed", result.Status)
    assert.True(t, result.CrossChainSynced)
}
```

## Performance Testing

### 1. Load Testing

**Test High Volume**:
```go
// performance/load_test.go
func TestHighVolumeOrderProcessing(t *testing.T) {
    performer := NewVaultSwapPerformer()
    
    // Create 1000 orders
    var wg sync.WaitGroup
    for i := 0; i < 1000; i++ {
        wg.Add(1)
        go func(i int) {
            defer wg.Done()
            
            orderID, err := performer.CreateOrder(
                common.HexToAddress(fmt.Sprintf("0x%x", i)),
                common.HexToAddress(fmt.Sprintf("0x%x", i+1)),
                big.NewInt(1e18),
            )
            assert.NoError(t, err)
            assert.NotEqual(t, common.Hash{}, orderID)
        }(i)
    }
    
    wg.Wait()
}
```

### 2. Stress Testing

**Test System Limits**:
```typescript
// performance/stress.test.ts
describe('Stress Testing', () => {
  it('should handle maximum concurrent orders', async () => {
    const maxConcurrent = 100;
    const promises = [];
    
    for (let i = 0; i < maxConcurrent; i++) {
      promises.push(createOrder({
        tokenIn: `0x${i.toString(16).padStart(40, '0')}`,
        tokenOut: `0x${(i + 1).toString(16).padStart(40, '0')}`,
        amountIn: '1.0',
        minAmountOut: '0.95',
        deadline: 3600
      }));
    }
    
    const results = await Promise.allSettled(promises);
    const successful = results.filter(r => r.status === 'fulfilled').length;
    
    expect(successful).toBeGreaterThan(maxConcurrent * 0.9); // 90% success rate
  });
});
```

### 3. Benchmark Testing

**Test Performance Metrics**:
```go
// performance/benchmark_test.go
func BenchmarkOrderCreation(b *testing.B) {
    performer := NewVaultSwapPerformer()
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _, err := performer.CreateOrder(
            common.HexToAddress("0x1"),
            common.HexToAddress("0x2"),
            big.NewInt(1e18),
        )
        if err != nil {
            b.Fatal(err)
        }
    }
}

func BenchmarkOrderExecution(b *testing.B) {
    performer := NewVaultSwapPerformer()
    orderID, _ := performer.CreateOrder(
        common.HexToAddress("0x1"),
        common.HexToAddress("0x2"),
        big.NewInt(1e18),
    )
    
    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        err := performer.ExecuteOrder(orderID)
        if err != nil {
            b.Fatal(err)
        }
    }
}
```

## Security Testing

### 1. Vulnerability Testing

**Test Common Vulnerabilities**:
```solidity
// test/SecurityTest.t.sol
contract SecurityTest is Test {
    function testReentrancyProtection() public {
        // Test reentrancy protection
    }
    
    function testAccessControl() public {
        // Test access control
    }
    
    function testIntegerOverflow() public {
        // Test integer overflow protection
    }
    
    function testFrontRunning() public {
        // Test front-running protection
    }
}
```

### 2. Fuzz Testing

**Test Random Inputs**:
```solidity
// test/FuzzTest.t.sol
contract FuzzTest is Test {
    function testFuzzCreateOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) public {
        // Fuzz test order creation
        vm.assume(tokenIn != address(0));
        vm.assume(tokenOut != address(0));
        vm.assume(amountIn > 0);
        vm.assume(deadline > block.timestamp);
        
        // Test order creation
        bytes32 orderId = hook.createOrder(
            tokenIn,
            tokenOut,
            amountIn,
            minAmountOut,
            deadline
        );
        
        assertTrue(orderId != bytes32(0));
    }
}
```

### 3. Penetration Testing

**Test Attack Vectors**:
```go
// security/penetration_test.go
func TestMEVAttackPrevention(t *testing.T) {
    // Test MEV attack prevention
    performer := NewVaultSwapPerformer()
    
    // Simulate MEV attack
    attackResult := performer.SimulateMEVAttack()
    
    // Verify protection
    assert.False(t, attackResult.Success)
    assert.True(t, attackResult.Protected)
}

func TestPrivacyLeakage(t *testing.T) {
    // Test privacy leakage prevention
    performer := NewVaultSwapPerformer()
    
    // Test privacy features
    privacyResult := performer.TestPrivacyFeatures()
    
    // Verify privacy
    assert.True(t, privacyResult.Encrypted)
    assert.False(t, privacyResult.Leaked)
}
```

## Test Automation

### 1. CI/CD Integration

**GitHub Actions**:
```yaml
# .github/workflows/test.yml
name: Test

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
        cache: 'pnpm'
    
    - name: Install dependencies
      run: pnpm install
    
    - name: Run Solidity tests
      run: forge test
    
    - name: Run Go tests
      run: cd avs && go test ./...
    
    - name: Run TypeScript tests
      run: pnpm test
    
    - name: Run integration tests
      run: pnpm test:integration
    
    - name: Run E2E tests
      run: pnpm test:e2e
```

### 2. Test Coverage

**Coverage Reporting**:
```bash
# Solidity coverage
forge coverage --ir-minimum

# Go coverage
go test -cover ./...

# TypeScript coverage
pnpm test:coverage
```

**Coverage Thresholds**:
- **Unit Tests**: 90%+ coverage
- **Integration Tests**: 80%+ coverage
- **E2E Tests**: 70%+ coverage

### 3. Test Data Management

**Test Fixtures**:
```typescript
// test/fixtures/orders.ts
export const validOrder = {
  tokenIn: '0x1',
  tokenOut: '0x2',
  amountIn: '1.0',
  minAmountOut: '0.95',
  deadline: 3600
};

export const invalidOrder = {
  tokenIn: ethers.ZeroAddress,
  tokenOut: '0x2',
  amountIn: '0',
  minAmountOut: '0.95',
  deadline: 0
};
```

**Test Database**:
```go
// test/database/test_db.go
func setupTestDB() *sql.DB {
    db, err := sql.Open("sqlite3", ":memory:")
    if err != nil {
        log.Fatal(err)
    }
    
    // Create test tables
    createTestTables(db)
    
    // Insert test data
    insertTestData(db)
    
    return db
}
```

## Best Practices

### 1. Testing Best Practices

- **Write tests first** (TDD)
- **Test edge cases** and error conditions
- **Use descriptive test names**
- **Keep tests independent**
- **Mock external dependencies**
- **Test both success and failure paths**

### 2. Test Organization

- **Group related tests**
- **Use consistent naming**
- **Keep tests focused**
- **Avoid test duplication**
- **Use test utilities**

### 3. Test Maintenance

- **Update tests when code changes**
- **Remove obsolete tests**
- **Refactor test code**
- **Monitor test performance**
- **Review test coverage**

---

**Need help with testing?** Check out our [Troubleshooting Guide](TROUBLESHOOTING.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

**Have questions?** Visit our [FAQ](FAQ.md) or [Support](SUPPORT.md) page.

---

*This testing guide is regularly updated. Last updated: January 1, 2024*
