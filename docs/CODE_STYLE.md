# VaultSwap Hook Code Style Guide

This guide establishes coding standards and best practices for the VaultSwap Hook project.

## Table of Contents

- [Overview](#overview)
- [Solidity Style](#solidity-style)
- [Go Style](#go-style)
- [TypeScript/JavaScript Style](#typescriptjavascript-style)
- [Documentation Style](#documentation-style)
- [Testing Style](#testing-style)
- [Git Style](#git-style)

## Overview

This code style guide ensures:
- **Consistency**: Uniform code across the project
- **Readability**: Easy to read and understand code
- **Maintainability**: Easy to maintain and modify
- **Quality**: High-quality, production-ready code
- **Collaboration**: Smooth collaboration between developers

## Solidity Style

### 1. General Formatting

**Indentation**: Use 4 spaces (no tabs)
```solidity
contract VaultSwapHook {
    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external returns (bytes32) {
        // Implementation
    }
}
```

**Line Length**: Maximum 120 characters
```solidity
// Good
function createOrder(
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
) external returns (bytes32);

// Bad
function createOrder(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint256 deadline) external returns (bytes32);
```

**Spacing**: Use spaces around operators and after commas
```solidity
// Good
uint256 totalAmount = amountIn + amountOut;
mapping(address => uint256) balances;

// Bad
uint256 totalAmount=amountIn+amountOut;
mapping(address=>uint256)balances;
```

### 2. Naming Conventions

**Contracts**: PascalCase
```solidity
contract VaultSwapHook { }
contract HybridFHERC20 { }
contract VaultSwapServiceManager { }
```

**Functions**: camelCase
```solidity
function createOrder() external { }
function executeOrder() external { }
function setMEVProtectionLevel() external { }
```

**Variables**: camelCase
```solidity
uint256 orderId;
address tokenIn;
bool isExecuted;
```

**Constants**: UPPER_SNAKE_CASE
```solidity
uint256 constant MAX_SLIPPAGE = 10000; // 100%
uint256 constant MIN_ORDER_AMOUNT = 1e18;
bytes32 constant ORDER_CREATED_EVENT = keccak256("OrderCreated(bytes32,address,address,address,uint256,uint256,uint256)");
```

**Events**: PascalCase
```solidity
event OrderCreated(
    bytes32 indexed orderId,
    address indexed user,
    address tokenIn,
    address tokenOut,
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
);
```

### 3. Function Structure

**Function Order**:
1. Constructor
2. External functions
3. Public functions
4. Internal functions
5. Private functions
6. Modifiers
7. Events

```solidity
contract VaultSwapHook {
    // 1. State variables
    address public owner;
    uint256 public orderCount;
    
    // 2. Constructor
    constructor(address _owner) {
        owner = _owner;
    }
    
    // 3. External functions
    function createOrder(...) external returns (bytes32) { }
    function executeOrder(...) external { }
    
    // 4. Public functions
    function getOrder(...) public view returns (...) { }
    
    // 5. Internal functions
    function _validateOrder(...) internal view { }
    
    // 6. Private functions
    function _calculateAmount(...) private pure returns (uint256) { }
    
    // 7. Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // 8. Events
    event OrderCreated(...);
}
```

### 4. Error Handling

**Use Custom Errors** (Solidity 0.8.4+):
```solidity
// Define custom errors
error HookNotInitialized();
error InvalidOrder();
error OrderExpired();
error InsufficientBalance();
error Unauthorized();

// Use custom errors
function createOrder(...) external {
    if (!initialized) revert HookNotInitialized();
    if (amountIn == 0) revert InvalidOrder();
    if (deadline <= block.timestamp) revert OrderExpired();
    if (balance < amountIn) revert InsufficientBalance();
}
```

**Use require for Input Validation**:
```solidity
function createOrder(...) external {
    require(tokenIn != address(0), "Invalid tokenIn");
    require(tokenOut != address(0), "Invalid tokenOut");
    require(amountIn > 0, "Amount must be positive");
    require(deadline > block.timestamp, "Deadline must be in future");
}
```

### 5. Documentation

**NatSpec Comments**:
```solidity
/// @title VaultSwap Hook
/// @notice Main hook contract for MEV protection and privacy
/// @author VaultSwap Team
contract VaultSwapHook {
    /// @notice Creates a new swap order
    /// @param tokenIn The input token address
    /// @param tokenOut The output token address
    /// @param amountIn The input amount
    /// @param minAmountOut The minimum output amount
    /// @param deadline The order expiration timestamp
    /// @return orderId The unique order identifier
    /// @dev The order will be executed by the AVS system
    function createOrder(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline
    ) external returns (bytes32 orderId) {
        // Implementation
    }
}
```

## Go Style

### 1. General Formatting

**Indentation**: Use tabs (not spaces)
```go
func createOrder(tokenIn, tokenOut common.Address, amountIn *big.Int) (*big.Int, error) {
    // Implementation
    return orderId, nil
}
```

**Line Length**: Maximum 120 characters
```go
// Good
func createOrder(
    tokenIn, tokenOut common.Address,
    amountIn *big.Int,
    minAmountOut *big.Int,
    deadline *big.Int,
) (*big.Int, error) {
    // Implementation
}

// Bad
func createOrder(tokenIn, tokenOut common.Address, amountIn *big.Int, minAmountOut *big.Int, deadline *big.Int) (*big.Int, error) {
    // Implementation
}
```

**Spacing**: Use spaces around operators and after commas
```go
// Good
totalAmount := new(big.Int).Add(amountIn, amountOut)
result := calculateAmount(a, b, c)

// Bad
totalAmount:=new(big.Int).Add(amountIn,amountOut)
result:=calculateAmount(a,b,c)
```

### 2. Naming Conventions

**Packages**: lowercase, single word
```go
package vaultswap
package performer
package contracts
```

**Types**: PascalCase
```go
type VaultSwapPerformer struct { }
type Order struct { }
type TaskType string
```

**Functions**: camelCase
```go
func createOrder() error { }
func executeOrder() error { }
func setMEVProtectionLevel() error { }
```

**Variables**: camelCase
```go
var orderId common.Hash
var tokenIn common.Address
var isExecuted bool
```

**Constants**: UPPER_SNAKE_CASE
```go
const (
    MAX_SLIPPAGE = 10000 // 100%
    MIN_ORDER_AMOUNT = "1000000000000000000" // 1 ETH
    DEFAULT_TIMEOUT = 30 * time.Second
)
```

### 3. Function Structure

**Function Order**:
1. Constructor/New functions
2. Public methods
3. Private methods
4. Helper functions

```go
type VaultSwapPerformer struct {
    // Fields
}

// 1. Constructor
func NewVaultSwapPerformer() *VaultSwapPerformer {
    return &VaultSwapPerformer{}
}

// 2. Public methods
func (p *VaultSwapPerformer) CreateOrder(...) error { }
func (p *VaultSwapPerformer) ExecuteOrder(...) error { }

// 3. Private methods
func (p *VaultSwapPerformer) validateOrder(...) error { }
func (p *VaultSwapPerformer) processOrder(...) error { }

// 4. Helper functions
func calculateAmount(...) *big.Int { }
func formatAddress(...) string { }
```

### 4. Error Handling

**Use Wrapped Errors**:
```go
func createOrder(tokenIn, tokenOut common.Address, amountIn *big.Int) (*big.Int, error) {
    if err := validateOrder(tokenIn, tokenOut, amountIn); err != nil {
        return nil, fmt.Errorf("failed to validate order: %w", err)
    }
    
    orderId, err := submitOrder(tokenIn, tokenOut, amountIn)
    if err != nil {
        return nil, fmt.Errorf("failed to submit order: %w", err)
    }
    
    return orderId, nil
}
```

**Use Custom Error Types**:
```go
type OrderError struct {
    Code    string
    Message string
    Err     error
}

func (e *OrderError) Error() string {
    if e.Err != nil {
        return fmt.Sprintf("%s: %s (%v)", e.Code, e.Message, e.Err)
    }
    return fmt.Sprintf("%s: %s", e.Code, e.Message)
}

func (e *OrderError) Unwrap() error {
    return e.Err
}
```

### 5. Documentation

**Package Documentation**:
```go
// Package vaultswap provides the VaultSwap Hook implementation
// for MEV protection and privacy-preserving trading.
//
// This package includes:
// - Smart contract integration
// - AVS task processing
// - Cross-chain communication
// - MEV protection strategies
package vaultswap
```

**Function Documentation**:
```go
// CreateOrder creates a new swap order with the specified parameters.
//
// Parameters:
//   - tokenIn: The input token address
//   - tokenOut: The output token address
//   - amountIn: The input amount
//   - minAmountOut: The minimum output amount
//   - deadline: The order expiration timestamp
//
// Returns:
//   - orderId: The unique order identifier
//   - error: Any error that occurred during order creation
//
// Example:
//   orderId, err := performer.CreateOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline)
//   if err != nil {
//       log.Fatal(err)
//   }
func (p *VaultSwapPerformer) CreateOrder(
    tokenIn, tokenOut common.Address,
    amountIn, minAmountOut *big.Int,
    deadline *big.Int,
) (*big.Int, error) {
    // Implementation
}
```

## TypeScript/JavaScript Style

### 1. General Formatting

**Indentation**: Use 2 spaces
```typescript
function createOrder(
  tokenIn: string,
  tokenOut: string,
  amountIn: string,
  minAmountOut: string,
  deadline: number
): Promise<string> {
  // Implementation
}
```

**Line Length**: Maximum 100 characters
```typescript
// Good
function createOrder(
  tokenIn: string,
  tokenOut: string,
  amountIn: string,
  minAmountOut: string,
  deadline: number
): Promise<string> {
  // Implementation
}

// Bad
function createOrder(tokenIn: string, tokenOut: string, amountIn: string, minAmountOut: string, deadline: number): Promise<string> {
  // Implementation
}
```

**Spacing**: Use spaces around operators and after commas
```typescript
// Good
const totalAmount = amountIn + amountOut;
const result = calculateAmount(a, b, c);

// Bad
const totalAmount=amountIn+amountOut;
const result=calculateAmount(a,b,c);
```

### 2. Naming Conventions

**Files**: kebab-case
```
vaultswap-hook.ts
order-manager.ts
mev-protection.ts
```

**Classes**: PascalCase
```typescript
class VaultSwapHook { }
class OrderManager { }
class MEVProtection { }
```

**Functions**: camelCase
```typescript
function createOrder() { }
function executeOrder() { }
function setMEVProtectionLevel() { }
```

**Variables**: camelCase
```typescript
const orderId: string;
const tokenIn: string;
const isExecuted: boolean;
```

**Constants**: UPPER_SNAKE_CASE
```typescript
const MAX_SLIPPAGE = 10000; // 100%
const MIN_ORDER_AMOUNT = "1000000000000000000"; // 1 ETH
const DEFAULT_TIMEOUT = 30000; // 30 seconds
```

**Interfaces**: PascalCase with 'I' prefix
```typescript
interface IOrder {
  id: string;
  tokenIn: string;
  tokenOut: string;
  amountIn: string;
  minAmountOut: string;
  deadline: number;
}
```

### 3. Type Definitions

**Use Explicit Types**:
```typescript
interface Order {
  id: string;
  user: string;
  tokenIn: string;
  tokenOut: string;
  amountIn: string;
  minAmountOut: string;
  deadline: number;
  executed: boolean;
  cancelled: boolean;
}

type OrderStatus = 'pending' | 'executed' | 'cancelled';
type TaskType = 'mev_monitoring' | 'order_creation' | 'order_execution' | 'cross_chain_sync';
```

**Use Enums for Constants**:
```typescript
enum OrderStatus {
  PENDING = 'pending',
  EXECUTED = 'executed',
  CANCELLED = 'cancelled'
}

enum TaskType {
  MEV_MONITORING = 'mev_monitoring',
  ORDER_CREATION = 'order_creation',
  ORDER_EXECUTION = 'order_execution',
  CROSS_CHAIN_SYNC = 'cross_chain_sync'
}
```

### 4. Error Handling

**Use Custom Error Classes**:
```typescript
class VaultSwapError extends Error {
  constructor(
    message: string,
    public code: string,
    public details?: any
  ) {
    super(message);
    this.name = 'VaultSwapError';
  }
}

class OrderError extends VaultSwapError {
  constructor(message: string, details?: any) {
    super(message, 'ORDER_ERROR', details);
    this.name = 'OrderError';
  }
}
```

**Use Try-Catch for Async Operations**:
```typescript
async function createOrder(
  tokenIn: string,
  tokenOut: string,
  amountIn: string,
  minAmountOut: string,
  deadline: number
): Promise<string> {
  try {
    const tx = await hook.createOrder(
      tokenIn,
      tokenOut,
      ethers.parseEther(amountIn),
      ethers.parseEther(minAmountOut),
      deadline
    );
    
    const receipt = await tx.wait();
    return receipt.logs[0].args.orderId;
  } catch (error) {
    if (error instanceof OrderError) {
      throw error;
    }
    throw new OrderError('Failed to create order', { originalError: error });
  }
}
```

### 5. Documentation

**JSDoc Comments**:
```typescript
/**
 * Creates a new swap order with the specified parameters.
 * 
 * @param tokenIn - The input token address
 * @param tokenOut - The output token address
 * @param amountIn - The input amount in wei
 * @param minAmountOut - The minimum output amount in wei
 * @param deadline - The order expiration timestamp
 * @returns Promise that resolves to the order ID
 * @throws {OrderError} When order creation fails
 * 
 * @example
 * ```typescript
 * const orderId = await createOrder(
 *   '0x...',
 *   '0x...',
 *   '1000000000000000000',
 *   '950000000000000000',
 *   Math.floor(Date.now() / 1000) + 3600
 * );
 * ```
 */
async function createOrder(
  tokenIn: string,
  tokenOut: string,
  amountIn: string,
  minAmountOut: string,
  deadline: number
): Promise<string> {
  // Implementation
}
```

## Documentation Style

### 1. Markdown Formatting

**Headers**: Use # for main headers, ## for sections
```markdown
# VaultSwap Hook Documentation

## Installation

### Prerequisites
```

**Code Blocks**: Use language-specific syntax highlighting
```markdown
```solidity
contract VaultSwapHook {
    function createOrder(...) external returns (bytes32) {
        // Implementation
    }
}
```

**Lists**: Use consistent formatting
```markdown
- **Item 1**: Description
- **Item 2**: Description
  - Sub-item 1
  - Sub-item 2
```

### 2. Documentation Structure

**File Structure**:
```
docs/
├── README.md
├── INSTALLATION.md
├── CONFIGURATION.md
├── API.md
├── EXAMPLES.md
├── TROUBLESHOOTING.md
└── CONTRIBUTING.md
```

**Content Structure**:
1. Title
2. Table of Contents
3. Overview
4. Prerequisites
5. Step-by-step instructions
6. Examples
7. Troubleshooting
8. References

### 3. Writing Guidelines

**Use Clear Language**:
- Write in simple, clear English
- Avoid jargon and technical terms when possible
- Use active voice
- Be concise but complete

**Use Consistent Formatting**:
- Use consistent heading levels
- Use consistent code block formatting
- Use consistent list formatting
- Use consistent link formatting

**Include Examples**:
- Provide code examples
- Include screenshots when helpful
- Show expected output
- Include error cases

## Testing Style

### 1. Test Structure

**Test File Organization**:
```
tests/
├── unit/
│   ├── VaultSwapHook.test.ts
│   ├── OrderManager.test.ts
│   └── MEVProtection.test.ts
├── integration/
│   ├── CrossChain.test.ts
│   └── AVS.test.ts
└── e2e/
    └── FullFlow.test.ts
```

**Test Function Naming**:
```typescript
// Good
describe('VaultSwapHook', () => {
  describe('createOrder', () => {
    it('should create an order with valid parameters', () => { });
    it('should revert when tokenIn is zero address', () => { });
    it('should revert when amountIn is zero', () => { });
  });
});

// Bad
describe('VaultSwapHook', () => {
  it('test1', () => { });
  it('test2', () => { });
});
```

### 2. Test Content

**Arrange-Act-Assert Pattern**:
```typescript
it('should create an order with valid parameters', async () => {
  // Arrange
  const tokenIn = '0x...';
  const tokenOut = '0x...';
  const amountIn = ethers.parseEther('1.0');
  const minAmountOut = ethers.parseEther('0.95');
  const deadline = Math.floor(Date.now() / 1000) + 3600;
  
  // Act
  const tx = await hook.createOrder(tokenIn, tokenOut, amountIn, minAmountOut, deadline);
  const receipt = await tx.wait();
  
  // Assert
  expect(receipt.status).toBe(1);
  expect(receipt.logs).toHaveLength(1);
  expect(receipt.logs[0].event).toBe('OrderCreated');
});
```

**Use Descriptive Test Names**:
```typescript
// Good
it('should revert when creating order with zero address tokenIn', () => { });
it('should emit OrderCreated event when order is created successfully', () => { });
it('should update order count when new order is created', () => { });

// Bad
it('should work', () => { });
it('should fail', () => { });
it('should do something', () => { });
```

## Git Style

### 1. Commit Messages

**Format**: `<type>(<scope>): <description>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Build process or auxiliary tool changes

**Examples**:
```bash
feat(hook): add MEV protection level setting
fix(order): resolve order execution timeout issue
docs(api): update API documentation
style(solidity): format contract code
refactor(avs): improve task processing logic
test(hook): add unit tests for order creation
chore(deps): update dependencies
```

### 2. Branch Naming

**Format**: `<type>/<description>`

**Examples**:
```bash
feature/mev-protection-enhancement
fix/order-execution-bug
docs/api-documentation-update
test/increase-coverage
refactor/avs-task-processing
```

### 3. Pull Request Guidelines

**Title**: Use commit message format
**Description**: Include:
- What changes were made
- Why changes were made
- How to test the changes
- Any breaking changes
- Related issues

**Example**:
```markdown
## Description
Add MEV protection level setting to VaultSwapHook contract

## Changes
- Add `setMEVProtectionLevel` function
- Add `getMEVProtectionLevel` function
- Add `MEVProtectionLevelSet` event
- Add access control for protection level setting

## Testing
- Unit tests for new functions
- Integration tests for MEV protection
- Manual testing on testnet

## Breaking Changes
None

## Related Issues
Fixes #123
```

## Tools and Automation

### 1. Code Formatting

**Solidity**: Use `forge fmt`
```bash
forge fmt
```

**Go**: Use `gofmt` and `goimports`
```bash
gofmt -w .
goimports -w .
```

**TypeScript/JavaScript**: Use `prettier`
```bash
prettier --write "src/**/*.{ts,js,json}"
```

### 2. Linting

**Solidity**: Use `solhint`
```bash
solhint "contracts/**/*.sol"
```

**Go**: Use `golangci-lint`
```bash
golangci-lint run
```

**TypeScript/JavaScript**: Use `eslint`
```bash
eslint "src/**/*.{ts,js}"
```

### 3. Pre-commit Hooks

**Setup**:
```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install
```

**Configuration** (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: local
    hooks:
      - id: forge-fmt
        name: Forge Format
        entry: forge fmt
        language: system
        files: \.sol$
      
      - id: go-fmt
        name: Go Format
        entry: gofmt -w
        language: system
        files: \.go$
      
      - id: prettier
        name: Prettier
        entry: prettier --write
        language: system
        files: \.(ts|js|json)$
```

## Best Practices

### 1. General Best Practices

- **Follow the style guide consistently**
- **Use meaningful names for variables and functions**
- **Write self-documenting code**
- **Add comments for complex logic**
- **Keep functions small and focused**
- **Use consistent error handling**
- **Write comprehensive tests**

### 2. Security Best Practices

- **Validate all inputs**
- **Use access controls appropriately**
- **Handle errors gracefully**
- **Avoid reentrancy vulnerabilities**
- **Use secure random number generation**
- **Follow the principle of least privilege**

### 3. Performance Best Practices

- **Optimize gas usage in smart contracts**
- **Use efficient data structures**
- **Minimize external calls**
- **Use batch operations when possible**
- **Cache frequently accessed data**
- **Monitor performance metrics**

---

**Need help with code style?** Check out our [Contributing Guide](CONTRIBUTING.md) or join our [Discord](https://discord.gg/vaultswap).

**Want to contribute?** See our [Contributing Guide](CONTRIBUTING.md).

**Have questions?** Visit our [FAQ](FAQ.md) or [Support](SUPPORT.md) page.

---

*This code style guide is regularly updated. Last updated: January 1, 2024*
