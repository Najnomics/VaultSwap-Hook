# Contributing to VaultSwap Hook

## Overview

Thank you for your interest in contributing to VaultSwap Hook! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Code Style](#code-style)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Community](#community)

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inclusive environment for all contributors. By participating in this project, you agree to:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what's best for the community
- Show empathy towards other community members

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what's best for the community

**Unacceptable behavior includes:**
- Harassment or discrimination
- Trolling or inflammatory comments
- Personal attacks or political discussions
- Spam or off-topic discussions

## Getting Started

### Prerequisites

- **Git**: Version control
- **Node.js**: 18+ with pnpm
- **Foundry**: For Solidity development
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/VaultSwap-Hook.git
   cd VaultSwap-Hook
   ```

3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/VaultSwap/VaultSwap-Hook.git
   ```

## Development Setup

### 1. Install Dependencies

```bash
# Install Node.js dependencies
pnpm install

# Install Foundry dependencies
forge install

# Install AVS dependencies
cd avs
go mod tidy
cd ..
```

### 2. Environment Configuration

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 3. Start Local Development

```bash
# Start Anvil for local testing
anvil

# In another terminal, run tests
forge test

# Run AVS tests
cd avs
go test ./...
cd ..
```

## Contributing Guidelines

### Types of Contributions

We welcome various types of contributions:

- **Bug Fixes**: Fix existing issues
- **Features**: Add new functionality
- **Documentation**: Improve or add documentation
- **Tests**: Add or improve test coverage
- **Performance**: Optimize existing code
- **Security**: Address security vulnerabilities

### Contribution Process

1. **Check Issues**: Look for existing issues or create a new one
2. **Create Branch**: Create a feature branch from `main`
3. **Make Changes**: Implement your changes
4. **Test**: Ensure all tests pass
5. **Document**: Update documentation if needed
6. **Submit PR**: Create a pull request

### Branch Naming

Use descriptive branch names:
- `feature/mev-protection-enhancement`
- `fix/order-execution-bug`
- `docs/api-documentation-update`
- `test/increase-coverage`

## Code Style

### Solidity

Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html):

```solidity
// Use camelCase for function names
function createOrder(address tokenIn, address tokenOut) external {
    // Use descriptive variable names
    uint256 minimumAmountOut = calculateMinimumAmount(tokenIn, tokenOut);
    
    // Use events for important state changes
    emit OrderCreated(orderId, msg.sender, tokenIn, tokenOut);
}

// Use NatSpec comments for public functions
/// @notice Creates a new swap order
/// @param tokenIn The input token address
/// @param tokenOut The output token address
/// @return orderId The unique order identifier
function createOrder(address tokenIn, address tokenOut) external returns (bytes32 orderId);
```

### Go

Follow the [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments):

```go
// Use camelCase for function names
func createOrder(tokenIn, tokenOut common.Address) (common.Hash, error) {
    // Use descriptive variable names
    minimumAmountOut, err := calculateMinimumAmount(tokenIn, tokenOut)
    if err != nil {
        return common.Hash{}, fmt.Errorf("failed to calculate minimum amount: %w", err)
    }
    
    // Use context for cancellation
    ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
    defer cancel()
    
    return submitOrder(ctx, tokenIn, tokenOut, minimumAmountOut)
}
```

### TypeScript/JavaScript

Follow the [TypeScript Style Guide](https://typescript-eslint.io/rules/):

```typescript
// Use camelCase for function names
function createOrder(tokenIn: string, tokenOut: string): Promise<string> {
    // Use descriptive variable names
    const minimumAmountOut = calculateMinimumAmount(tokenIn, tokenOut);
    
    // Use async/await for promises
    try {
        const orderId = await submitOrder(tokenIn, tokenOut, minimumAmountOut);
        return orderId;
    } catch (error) {
        throw new Error(`Failed to create order: ${error.message}`);
    }
}
```

## Testing

### Solidity Tests

```bash
# Run all tests
forge test

# Run specific test file
forge test --match-path test/VaultSwapHook.t.sol

# Run with gas reporting
forge test --gas-report

# Run with coverage
forge coverage --ir-minimum
```

### Go Tests

```bash
# Run all tests
go test ./...

# Run with coverage
go test -cover ./...

# Run specific test
go test -run TestCreateOrder ./cmd
```

### Test Requirements

- **Unit Tests**: Test individual functions
- **Integration Tests**: Test component interactions
- **Fuzz Tests**: Test with random inputs
- **Coverage**: Maintain 90%+ coverage
- **Performance**: Include benchmark tests

### Writing Tests

**Solidity Example:**
```solidity
function testCreateOrder() public {
    // Arrange
    address tokenIn = address(0x1);
    address tokenOut = address(0x2);
    uint256 amountIn = 1e18;
    
    // Act
    bytes32 orderId = hook.createOrder(tokenIn, tokenOut, amountIn, 0, block.timestamp + 3600);
    
    // Assert
    assertTrue(orderId != bytes32(0));
    (address user, address inToken, address outToken, uint256 amount) = hook.getOrder(orderId);
    assertEq(user, address(this));
    assertEq(inToken, tokenIn);
    assertEq(outToken, tokenOut);
    assertEq(amount, amountIn);
}
```

**Go Example:**
```go
func TestCreateOrder(t *testing.T) {
    // Arrange
    tokenIn := common.HexToAddress("0x1")
    tokenOut := common.HexToAddress("0x2")
    amountIn := big.NewInt(1e18)
    
    // Act
    orderId, err := performer.CreateOrder(tokenIn, tokenOut, amountIn)
    
    // Assert
    assert.NoError(t, err)
    assert.NotEqual(t, common.Hash{}, orderId)
    
    order, err := performer.GetOrder(orderId)
    assert.NoError(t, err)
    assert.Equal(t, tokenIn, order.TokenIn)
    assert.Equal(t, tokenOut, order.TokenOut)
    assert.Equal(t, amountIn, order.AmountIn)
}
```

## Pull Request Process

### Before Submitting

1. **Sync with upstream**:
   ```bash
   git fetch upstream
   git checkout main
   git merge upstream/main
   ```

2. **Update your branch**:
   ```bash
   git checkout your-branch
   git rebase main
   ```

3. **Run all tests**:
   ```bash
   forge test
   go test ./...
   pnpm test
   ```

4. **Check code style**:
   ```bash
   forge fmt
   go fmt ./...
   pnpm lint
   ```

### PR Template

Use this template for pull requests:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No breaking changes (or documented)

## Related Issues
Fixes #(issue number)
```

### Review Process

1. **Automated Checks**: CI/CD pipeline runs tests
2. **Code Review**: At least one maintainer reviews
3. **Testing**: Manual testing if needed
4. **Approval**: Maintainer approves the PR
5. **Merge**: PR is merged to main

## Issue Reporting

### Bug Reports

Use this template for bug reports:

```markdown
## Bug Description
Clear description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Environment
- OS: [e.g., macOS 13.0]
- Node.js: [e.g., 18.17.0]
- Foundry: [e.g., 0.2.0]
- Go: [e.g., 1.21.0]

## Additional Context
Any other relevant information
```

### Feature Requests

Use this template for feature requests:

```markdown
## Feature Description
Clear description of the feature

## Use Case
Why is this feature needed?

## Proposed Solution
How should this feature work?

## Alternatives
Other solutions considered

## Additional Context
Any other relevant information
```

## Community

### Getting Help

- **GitHub Discussions**: For questions and discussions
- **Discord**: For real-time chat
- **Email**: For security issues

### Recognition

Contributors are recognized in:
- **CONTRIBUTORS.md**: List of all contributors
- **Release Notes**: Major contributors mentioned
- **Documentation**: Contributors credited

### Maintainers

Current maintainers:
- [@maintainer1](https://github.com/maintainer1)
- [@maintainer2](https://github.com/maintainer2)

## License

By contributing to VaultSwap Hook, you agree that your contributions will be licensed under the same license as the project.

## Security

### Reporting Security Issues

For security vulnerabilities, please:
1. **DO NOT** open a public issue
2. Email security@vaultswap.io
3. Include detailed information about the vulnerability
4. Wait for acknowledgment before public disclosure

### Security Best Practices

- Never commit secrets or private keys
- Use environment variables for sensitive data
- Follow secure coding practices
- Keep dependencies updated

## Questions?

If you have questions about contributing:
- Check existing issues and discussions
- Ask in GitHub Discussions
- Contact maintainers directly

Thank you for contributing to VaultSwap Hook! 🚀
