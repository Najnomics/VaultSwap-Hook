# VaultSwap Hook API Reference

## Overview

This document provides comprehensive API reference for the VaultSwap Hook smart contracts.

## Core Contract: VaultSwapHook

### State Variables

```solidity
// Order storage
mapping(bytes32 => EnhancedVaultOrder) public vaultOrders;
mapping(address => bytes32) public userActiveOrders;

// System configuration
uint256 public constant MAX_MEV_LEVEL = 5;
uint256 public constant MIN_ORDER_AMOUNT = 1000; // Minimum 1000 wei
```

### Structs

#### EnhancedVaultOrder

```solidity
struct EnhancedVaultOrder {
    // Core parameters
    euint128 amountIn;           // Encrypted input amount
    euint128 minAmountOut;       // Encrypted minimum output
    euint8 direction;            // Encrypted swap direction
    euint64 deadline;            // Encrypted deadline
    
    // MEV protection
    euint32 mevProtectionLevel;  // Protection level (1-5)
    euint128 decoyAmount;        // Decoy order amount
    euint64 executionWindow;     // Execution timing window
    euint8 stealthMode;          // Stealth execution mode
    
    // Routing
    euint8 routingStrategy;      // Routing strategy
    euint32 maxPools;            // Max pools to use
    euint128 minPoolLiquidity;   // Min pool liquidity
    euint64 gasOptimization;     // Gas optimization level
    
    // Execution
    euint8 executionAlgorithm;   // Execution algorithm
    euint128 maxMarketImpact;    // Max market impact
    euint64 complianceFlags;     // Compliance settings
    euint32 performanceTarget;   // Performance target
    
    // Metadata
    address owner;               // Order owner
    uint256 timestamp;           // Creation timestamp
    bool isActive;               // Order active status
}
```

### Events

```solidity
event VaultOrderSubmitted(
    bytes32 indexed orderId,
    address indexed owner,
    PoolId indexed poolId
);

event VaultOrderCancelled(
    bytes32 indexed orderId,
    address indexed owner
);

event VaultOrderExecuted(
    bytes32 indexed orderId,
    address indexed owner,
    uint256 amountIn,
    uint256 amountOut
);

event MEVDetected(
    bytes32 indexed orderId,
    uint8 attackType,
    uint256 timestamp
);

event DecoyOrderDeployed(
    bytes32 indexed orderId,
    uint256 decoyCount
);
```

### Core Functions

#### submitVaultOrder

```solidity
function submitVaultOrder(
    PoolKey calldata key,
    euint128 amountIn,
    euint128 minAmountOut,
    euint8 direction,
    euint64 deadline,
    euint32 mevProtectionLevel
) external returns (bytes32 orderId)
```

**Description**: Submit a new vault order with enhanced protection and routing.

**Parameters**:
- `key`: Pool key for the target pool
- `amountIn`: Encrypted input amount
- `minAmountOut`: Encrypted minimum output amount
- `direction`: Encrypted swap direction (0 = token0→token1, 1 = token1→token0)
- `deadline`: Encrypted execution deadline
- `mevProtectionLevel`: MEV protection level (1-5)

**Returns**: Unique order ID

**Requirements**:
- Amount must be greater than minimum
- Deadline must be in the future
- MEV level must be valid (1-5)
- User must have sufficient balance

#### cancelVaultOrder

```solidity
function cancelVaultOrder(bytes32 orderId) external returns (bool success)
```

**Description**: Cancel an active vault order.

**Parameters**:
- `orderId`: Order ID to cancel

**Returns**: Success status

**Requirements**:
- Order must exist and be active
- Only order owner can cancel
- Order must not be in execution

#### hasActiveOrder

```solidity
function hasActiveOrder(address user) external view returns (bool)
```

**Description**: Check if user has an active order.

**Parameters**:
- `user`: User address to check

**Returns**: True if user has active order

### Hook Functions

#### beforeSwap

```solidity
function beforeSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata hookData
) external override returns (bytes4)
```

**Description**: Hook called before swap execution.

**Processing**:
1. MEV detection and protection
2. Intelligent routing optimization
3. Execution strategy application

#### afterSwap

```solidity
function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata hookData
) external override returns (bytes4)
```

**Description**: Hook called after swap execution.

**Processing**:
1. Execution analytics update
2. Quality validation
3. Compliance reporting

## Library: MEVProtection

### Constants

```solidity
uint8 public constant BASIC_PROTECTION = 1;
uint8 public constant ENHANCED_PROTECTION = 2;
uint8 public constant ADVANCED_PROTECTION = 3;
uint8 public constant MAXIMUM_PROTECTION = 4;
uint8 public constant ULTIMATE_PROTECTION = 5;

uint8[6] public constant DECOY_COUNTS = [0, 2, 3, 5, 8, 12];
uint32[6] public constant EXECUTION_DELAYS = [0, 30, 60, 120, 300, 600];
uint32[6] public constant GAS_THRESHOLDS = [0, 20, 15, 10, 5, 2];
```

### Functions

#### detectMEV

```solidity
function detectMEV(
    PoolKey memory key,
    SwapParams memory params,
    uint8 protectionLevel
) internal view returns (bool detected, string memory reason)
```

**Description**: Detect potential MEV attacks.

**Parameters**:
- `key`: Pool key
- `params`: Swap parameters
- `protectionLevel`: Current protection level

**Returns**: Detection result and reason

#### applyProtection

```solidity
function applyProtection(
    PoolKey memory key,
    SwapParams memory params,
    uint8 protectionLevel
) internal returns (bool protected)
```

**Description**: Apply MEV protection based on level.

**Parameters**:
- `key`: Pool key
- `params`: Swap parameters
- `protectionLevel`: Protection level to apply

**Returns**: Protection success status

#### getProtectionLevelName

```solidity
function getProtectionLevelName(uint8 level) internal pure returns (string memory)
```

**Description**: Get human-readable protection level name.

**Parameters**:
- `level`: Protection level (1-5)

**Returns**: Level name ("Basic", "Enhanced", etc.)

## Library: ExecutionStrategies

### Constants

```solidity
uint8 public constant TWAP_EXECUTION = 1;
uint8 public constant VWAP_EXECUTION = 2;
uint8 public constant OPPORTUNISTIC_EXECUTION = 3;
uint8 public constant IMMEDIATE_EXECUTION = 4;

uint8[5] public constant FRAGMENT_COUNTS = [0, 10, 8, 5, 1];
uint256[5] public constant TIME_INTERVALS = [0, 300, 180, 60, 0];
```

### Functions

#### isValidStrategy

```solidity
function isValidStrategy(uint8 strategy) internal pure returns (bool)
```

**Description**: Check if execution strategy is valid.

**Parameters**:
- `strategy`: Strategy ID to validate

**Returns**: True if valid strategy

#### getStrategyName

```solidity
function getStrategyName(uint8 strategy) internal pure returns (string memory)
```

**Description**: Get strategy name.

**Parameters**:
- `strategy`: Strategy ID

**Returns**: Strategy name

#### getFragmentCount

```solidity
function getFragmentCount(uint8 strategy) internal pure returns (uint256)
```

**Description**: Get number of fragments for strategy.

**Parameters**:
- `strategy`: Strategy ID

**Returns**: Fragment count

## Library: IntelligentRouter

### Constants

```solidity
uint8 public constant SINGLE_POOL_STRATEGY = 1;
uint8 public constant MULTI_POOL_SPLIT_STRATEGY = 2;
uint8 public constant DYNAMIC_ROUTING_STRATEGY = 3;
uint8 public constant LIQUIDITY_OPTIMIZED_STRATEGY = 4;

uint256[5] public constant MAX_POOLS = [0, 1, 5, 10, 8];
uint256[5] public constant MIN_LIQUIDITY = [0, 1 ether, 5 ether, 10 ether, 50 ether];
```

### Functions

#### isValidStrategy

```solidity
function isValidStrategy(uint8 strategy) internal pure returns (bool)
```

**Description**: Check if routing strategy is valid.

#### getStrategyName

```solidity
function getStrategyName(uint8 strategy) internal pure returns (string memory)
```

**Description**: Get routing strategy name.

#### getMaxPools

```solidity
function getMaxPools(uint8 strategy) internal pure returns (uint256)
```

**Description**: Get maximum pools for strategy.

#### getMinLiquidity

```solidity
function getMinLiquidity(uint8 strategy) internal pure returns (uint256)
```

**Description**: Get minimum liquidity requirement for strategy.

## Library: ExecutionAnalytics

### Functions

#### calculateSlippageScore

```solidity
function calculateSlippageScore(
    uint256 expectedOutput,
    uint256 actualOutput
) internal pure returns (uint256 score)
```

**Description**: Calculate slippage quality score (0-100).

**Parameters**:
- `expectedOutput`: Expected output amount
- `actualOutput`: Actual output amount

**Returns**: Slippage score (100 = perfect)

#### calculateTimingScore

```solidity
function calculateTimingScore(
    uint256 targetTime,
    uint256 actualTime
) internal pure returns (uint256 score)
```

**Description**: Calculate timing quality score (0-100).

**Parameters**:
- `targetTime`: Target execution time
- `actualTime`: Actual execution time

**Returns**: Timing score (100 = perfect)

#### calculateGasEfficiencyScore

```solidity
function calculateGasEfficiencyScore(
    uint256 estimatedGas,
    uint256 actualGas
) internal pure returns (uint256 score)
```

**Description**: Calculate gas efficiency score (0-100).

**Parameters**:
- `estimatedGas`: Estimated gas usage
- `actualGas`: Actual gas usage

**Returns**: Gas efficiency score (100 = perfect)

#### calculateOverallScore

```solidity
function calculateOverallScore(
    uint256 slippageScore,
    uint256 timingScore,
    uint256 gasScore,
    uint256 impactScore
) internal pure returns (uint256 score)
```

**Description**: Calculate overall execution quality score.

**Parameters**:
- `slippageScore`: Slippage quality score
- `timingScore`: Timing quality score
- `gasScore`: Gas efficiency score
- `impactScore`: Market impact score

**Returns**: Weighted overall score (0-100)

## Library: FHEPermissions

### Functions

#### grantOrderCreationPermissions

```solidity
function grantOrderCreationPermissions(
    euint128 amountIn,
    euint128 minAmountOut,
    euint64 deadline,
    euint32 mevProtectionLevel,
    address user,
    address contractAddr
) internal
```

**Description**: Grant comprehensive permissions for order creation.

#### grantBidPermissions

```solidity
function grantBidPermissions(
    euint128 bidAmount,
    euint128 allocation,
    euint128 currentPrice,
    address bidder,
    address token,
    address contractAddr
) internal
```

**Description**: Grant permissions for bid operations.

#### grantEnhancedVaultPermissions

```solidity
function grantEnhancedVaultPermissions(
    euint128 amountIn,
    euint128 minAmountOut,
    euint8 direction,
    euint64 deadline,
    euint32 mevProtectionLevel,
    euint8 routingStrategy,
    euint8 executionAlgorithm,
    euint128 maxMarketImpact,
    address user,
    address contractAddr
) internal
```

**Description**: Grant all permissions for enhanced vault order.

## Library: VaultSwapLib

### Functions

#### validateOrderParams

```solidity
function validateOrderParams(
    uint256 amountIn,
    uint256 minAmountOut,
    uint256 deadline
) internal view returns (bool valid)
```

**Description**: Validate order parameters.

**Parameters**:
- `amountIn`: Input amount
- `minAmountOut`: Minimum output amount
- `deadline`: Execution deadline

**Returns**: True if parameters are valid

#### calculateSwapAmount

```solidity
function calculateSwapAmount(
    uint256 totalAmount,
    uint256 fragmentIndex,
    uint256 totalFragments
) internal pure returns (uint256 swapAmount)
```

**Description**: Calculate swap amount for order fragment.

**Parameters**:
- `totalAmount`: Total order amount
- `fragmentIndex`: Current fragment index (1-based)
- `totalFragments`: Total number of fragments

**Returns**: Amount to swap for this fragment

#### calculateExecutionScore

```solidity
function calculateExecutionScore(
    uint256 expectedOutput,
    uint256 actualOutput,
    uint256 targetTime,
    uint256 actualTime,
    uint256 gasUsed
) internal pure returns (uint256 score)
```

**Description**: Calculate overall execution score.

**Parameters**:
- `expectedOutput`: Expected output amount
- `actualOutput`: Actual output amount
- `targetTime`: Target execution time
- `actualTime`: Actual execution time
- `gasUsed`: Gas consumed

**Returns**: Execution quality score (0-100)

## Error Codes

```solidity
error InvalidAmount();
error InvalidDeadline();
error InvalidMEVLevel();
error InsufficientBalance();
error OrderNotFound();
error OrderNotActive();
error NotOrderOwner();
error MEVDetected(uint8 attackType);
error ExecutionFailed();
error InvalidStrategy();
error InvalidPool();
```

## Usage Examples

### Basic Order Submission

```typescript
// Encrypt parameters
const encryptedAmount = await fhe.encrypt(parseEther("1.0"));
const encryptedMinOut = await fhe.encrypt(parseEther("0.95"));
const encryptedDirection = await fhe.encrypt(0); // 0 = buy, 1 = sell
const encryptedDeadline = await fhe.encrypt(Date.now() + 3600000); // 1 hour
const encryptedMEVLevel = await fhe.encrypt(3); // Advanced protection

// Submit order
const orderId = await vaultSwapHook.submitVaultOrder(
    poolKey,
    encryptedAmount,
    encryptedMinOut,
    encryptedDirection,
    encryptedDeadline,
    encryptedMEVLevel
);
```

### Order Cancellation

```typescript
const success = await vaultSwapHook.cancelVaultOrder(orderId);
```

### Check Active Order

```typescript
const hasOrder = await vaultSwapHook.hasActiveOrder(userAddress);
```

## Gas Costs

| Operation | Gas Cost | Notes |
|-----------|----------|-------|
| Submit Order | ~200,000 | Base cost + MEV protection |
| Cancel Order | ~50,000 | Simple state update |
| Execute Order | ~150,000 | Varies by strategy |
| MEV Protection | +50,000 per level | Additional protection cost |
| Multi-Pool Routing | +30,000 per pool | Additional routing cost |

## Rate Limits

- Maximum 1 active order per user
- Maximum 5 pools per routing strategy
- Maximum 12 decoy orders (Ultimate protection)
- Maximum 600-second execution delay

## Security Considerations

1. **FHE Security**: All sensitive data encrypted
2. **Access Control**: Strict permission management
3. **MEV Protection**: Multi-vector attack detection
4. **Gas Limits**: Protection against DoS attacks
5. **Input Validation**: Comprehensive parameter validation

This API reference provides complete documentation for integrating with the VaultSwap Hook system.