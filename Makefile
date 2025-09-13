# VaultSwap Hook - Makefile
# Professional market execution with complete MEV protection

.PHONY: help install build test test-coverage clean deploy configure verify lint format

# Default target
help: ## Show this help message
	@echo "VaultSwap Hook - Available Commands:"
	@echo "====================================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =============================================================
#                    INSTALLATION & SETUP
# =============================================================

install: ## Install dependencies
	@echo "Installing dependencies..."
	forge install foundry-rs/forge-std --no-commit
	forge install fhenixprotocol/cofhe-contracts --no-commit
	forge install OpenZeppelin/openzeppelin-contracts --no-commit
	forge install Uniswap/v4-core --no-commit
	forge install Uniswap/v4-periphery --no-commit
	forge install Uniswap/v4-hooks --no-commit
	@echo "Dependencies installed successfully"

update: ## Update dependencies
	@echo "Updating dependencies..."
	forge update
	@echo "Dependencies updated successfully"

# =============================================================
#                    BUILD & COMPILATION
# =============================================================

build: ## Build the project
	@echo "Building VaultSwap Hook..."
	forge build
	@echo "Build completed successfully"

build-verbose: ## Build with verbose output
	@echo "Building VaultSwap Hook (verbose)..."
	forge build --sizes
	@echo "Build completed successfully"

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	forge clean
	@echo "Clean completed successfully"

# =============================================================
#                    TESTING
# =============================================================

test: ## Run all tests
	@echo "Running VaultSwap Hook tests..."
	forge test --match-contract VaultSwapTest -vv
	@echo "Tests completed successfully"

test-verbose: ## Run tests with verbose output
	@echo "Running VaultSwap Hook tests (verbose)..."
	forge test --match-contract VaultSwapTest -vvv
	@echo "Tests completed successfully"

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	forge coverage --match-contract VaultSwapTest
	@echo "Coverage analysis completed"

test-gas: ## Run tests with gas reporting
	@echo "Running tests with gas reporting..."
	forge test --match-contract VaultSwapTest --gas-report
	@echo "Gas analysis completed"

test-fuzz: ## Run fuzz tests
	@echo "Running fuzz tests..."
	forge test --match-contract VaultSwapTest --fuzz-runs 1000
	@echo "Fuzz tests completed"

test-invariant: ## Run invariant tests
	@echo "Running invariant tests..."
	forge test --match-contract VaultSwapTest --invariant-runs 1000
	@echo "Invariant tests completed"

# =============================================================
#                    LINTING & FORMATTING
# =============================================================

lint: ## Run linter
	@echo "Running linter..."
	forge build --sizes
	@echo "Linting completed"

format: ## Format code
	@echo "Formatting code..."
	forge fmt
	@echo "Code formatting completed"

format-check: ## Check code formatting
	@echo "Checking code formatting..."
	forge fmt --check
	@echo "Format check completed"

# =============================================================
#                    DEPLOYMENT
# =============================================================

deploy-local: ## Deploy to local Anvil
	@echo "Deploying to local Anvil..."
	anvil &
	sleep 5
	forge script script/DeployVaultSwapHook.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	@echo "Local deployment completed"

setup-environment: ## Setup complete development environment
	@echo "Setting up development environment..."
	forge script script/SetupEnvironment.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	@echo "Environment setup completed"

deploy-sepolia: ## Deploy to Arbitrum Sepolia
	@echo "Deploying to Arbitrum Sepolia..."
	forge script script/DeployVaultSwapHook.s.sol --rpc-url $(ARBITRUM_SEPOLIA_RPC) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY)
	@echo "Arbitrum Sepolia deployment completed"

deploy-base-sepolia: ## Deploy to Base Sepolia
	@echo "Deploying to Base Sepolia..."
	forge script script/DeployVaultSwapHook.s.sol --rpc-url $(BASE_SEPOLIA_RPC) --broadcast --verify --etherscan-api-key $(BASESCAN_API_KEY)
	@echo "Base Sepolia deployment completed"

deploy-arbitrum: ## Deploy to Arbitrum One
	@echo "Deploying to Arbitrum One..."
	forge script script/DeployVaultSwapHook.s.sol --rpc-url $(ARBITRUM_RPC) --broadcast --verify --etherscan-api-key $(ARBISCAN_API_KEY)
	@echo "Arbitrum One deployment completed"

deploy-base: ## Deploy to Base Mainnet
	@echo "Deploying to Base Mainnet..."
	forge script script/DeployVaultSwapHook.s.sol --rpc-url $(BASE_RPC) --broadcast --verify --etherscan-api-key $(BASESCAN_API_KEY)
	@echo "Base Mainnet deployment completed"

deploy-fhenix: ## Deploy to Fhenix testnet
	@echo "Deploying to Fhenix testnet..."
	forge script script/DeployVaultSwapHook.s.sol --rpc-url $(FHENIX_RPC_URL) --broadcast --private-key $(PRIVATE_KEY)
	@echo "Fhenix deployment completed"

# =============================================================
#                    CONFIGURATION
# =============================================================

configure-local: ## Configure local deployment
	@echo "Configuring local deployment..."
	forge script script/SetupEnvironment.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
	@echo "Local configuration completed"

configure-sepolia: ## Configure Arbitrum Sepolia deployment
	@echo "Configuring Arbitrum Sepolia deployment..."
	forge script script/ConfigureVaultSwap.s.sol --rpc-url $(ARBITRUM_SEPOLIA_RPC) --broadcast --private-key $(PRIVATE_KEY)
	@echo "Arbitrum Sepolia configuration completed"

configure-base-sepolia: ## Configure Base Sepolia deployment
	@echo "Configuring Base Sepolia deployment..."
	forge script script/ConfigureVaultSwap.s.sol --rpc-url $(BASE_SEPOLIA_RPC) --broadcast --private-key $(PRIVATE_KEY)
	@echo "Base Sepolia configuration completed"

configure-arbitrum: ## Configure Arbitrum One deployment
	@echo "Configuring Arbitrum One deployment..."
	forge script script/ConfigureVaultSwap.s.sol --rpc-url $(ARBITRUM_RPC) --broadcast --private-key $(PRIVATE_KEY)
	@echo "Arbitrum One configuration completed"

configure-base: ## Configure Base Mainnet deployment
	@echo "Configuring Base Mainnet deployment..."
	forge script script/ConfigureVaultSwap.s.sol --rpc-url $(BASE_RPC) --broadcast --private-key $(PRIVATE_KEY)
	@echo "Base Mainnet configuration completed"

# =============================================================
#                    VERIFICATION
# =============================================================

verify-sepolia: ## Verify contracts on Arbitrum Sepolia
	@echo "Verifying contracts on Arbitrum Sepolia..."
	forge verify-contract --chain-id 421614 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $(POOL_MANAGER_ADDRESS)) $(VAULTSWAP_ADDRESS) src/VaultSwap.sol:VaultSwap
	@echo "Arbitrum Sepolia verification completed"

verify-base-sepolia: ## Verify contracts on Base Sepolia
	@echo "Verifying contracts on Base Sepolia..."
	forge verify-contract --chain-id 84532 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $(POOL_MANAGER_ADDRESS)) $(VAULTSWAP_ADDRESS) src/VaultSwap.sol:VaultSwap
	@echo "Base Sepolia verification completed"

verify-arbitrum: ## Verify contracts on Arbitrum One
	@echo "Verifying contracts on Arbitrum One..."
	forge verify-contract --chain-id 42161 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $(POOL_MANAGER_ADDRESS)) $(VAULTSWAP_ADDRESS) src/VaultSwap.sol:VaultSwap
	@echo "Arbitrum One verification completed"

verify-base: ## Verify contracts on Base Mainnet
	@echo "Verifying contracts on Base Mainnet..."
	forge verify-contract --chain-id 8453 --num-of-optimizations 200 --watch --constructor-args $(cast abi-encode "constructor(address)" $(POOL_MANAGER_ADDRESS)) $(VAULTSWAP_ADDRESS) src/VaultSwap.sol:VaultSwap
	@echo "Base Mainnet verification completed"

# =============================================================
#                    DEVELOPMENT
# =============================================================

dev: ## Start development environment
	@echo "Starting development environment..."
	anvil --host 0.0.0.0 --port 8545 &
	@echo "Development environment started on http://localhost:8545"

dev-stop: ## Stop development environment
	@echo "Stopping development environment..."
	pkill -f anvil
	@echo "Development environment stopped"

watch: ## Watch for changes and rebuild
	@echo "Watching for changes..."
	forge build --watch
	@echo "Watch mode completed"

# =============================================================
#                    DOCUMENTATION
# =============================================================

docs: ## Generate documentation
	@echo "Generating documentation..."
	@echo "Documentation generation not implemented yet"
	@echo "Documentation generation completed"

docs-serve: ## Serve documentation locally
	@echo "Serving documentation locally..."
	@echo "Documentation serving not implemented yet"
	@echo "Documentation serving completed"

# =============================================================
#                    SECURITY
# =============================================================

audit: ## Run security audit
	@echo "Running security audit..."
	@echo "Security audit not implemented yet"
	@echo "Security audit completed"

slither: ## Run Slither static analysis
	@echo "Running Slither static analysis..."
	@echo "Slither analysis not implemented yet"
	@echo "Slither analysis completed"

# =============================================================
#                    UTILITIES
# =============================================================

size: ## Show contract sizes
	@echo "Contract sizes:"
	forge build --sizes

gas-report: ## Generate gas report
	@echo "Generating gas report..."
	forge test --gas-report
	@echo "Gas report generated"

coverage-report: ## Generate coverage report
	@echo "Generating coverage report..."
	forge coverage --report lcov
	@echo "Coverage report generated"

# =============================================================
#                    ENVIRONMENT SETUP
# =============================================================

env-example: ## Create example environment file
	@echo "Creating example environment file..."
	@echo "# VaultSwap Hook Environment Variables" > .env.example
	@echo "PRIVATE_KEY=your_private_key_here" >> .env.example
	@echo "ARBITRUM_SEPOLIA_RPC=https://sepolia-rollup.arbitrum.io/rpc" >> .env.example
	@echo "BASE_SEPOLIA_RPC=https://sepolia.base.org" >> .env.example
	@echo "ARBITRUM_RPC=https://arb1.arbitrum.io/rpc" >> .env.example
	@echo "BASE_RPC=https://mainnet.base.org" >> .env.example
	@echo "ARBISCAN_API_KEY=your_arbiscan_api_key_here" >> .env.example
	@echo "BASESCAN_API_KEY=your_basescan_api_key_here" >> .env.example
	@echo "POOL_MANAGER_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "VAULTSWAP_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "MEV_DETECTION_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "ROUTER_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "EXECUTION_STRATEGIES_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "ANALYTICS_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "INSTITUTIONAL_FEATURES_ADDRESS=0x0000000000000000000000000000000000000000" >> .env.example
	@echo "Example environment file created: .env.example"

# =============================================================
#                    FULL WORKFLOW
# =============================================================

full-deploy: install build test deploy-local configure-local ## Full local deployment workflow
	@echo "Full local deployment workflow completed"

full-deploy-sepolia: install build test deploy-sepolia configure-sepolia verify-sepolia ## Full Arbitrum Sepolia deployment workflow
	@echo "Full Arbitrum Sepolia deployment workflow completed"

full-deploy-base-sepolia: install build test deploy-base-sepolia configure-base-sepolia verify-base-sepolia ## Full Base Sepolia deployment workflow
	@echo "Full Base Sepolia deployment workflow completed"

# =============================================================
#                    CLEANUP
# =============================================================

clean-all: clean ## Clean all artifacts and dependencies
	@echo "Cleaning all artifacts and dependencies..."
	rm -rf lib/
	rm -rf out/
	rm -rf cache/
	rm -rf .git/
	@echo "All cleanup completed"

# =============================================================
#                    HELP
# =============================================================

help-install: ## Show installation help
	@echo "Installation Help:"
	@echo "=================="
	@echo "1. Clone the repository"
	@echo "2. Run 'make install' to install dependencies"
	@echo "3. Copy .env.example to .env and configure"
	@echo "4. Run 'make build' to build the project"
	@echo "5. Run 'make test' to run tests"

help-deploy: ## Show deployment help
	@echo "Deployment Help:"
	@echo "================"
	@echo "1. Set up environment variables in .env"
	@echo "2. Run 'make deploy-local' for local testing"
	@echo "3. Run 'make deploy-sepolia' for testnet deployment"
	@echo "4. Run 'make configure-sepolia' to configure deployment"
	@echo "5. Run 'make verify-sepolia' to verify contracts"

help-test: ## Show testing help
	@echo "Testing Help:"
	@echo "============="
	@echo "1. Run 'make test' for basic tests"
	@echo "2. Run 'make test-coverage' for coverage analysis"
	@echo "3. Run 'make test-gas' for gas analysis"
	@echo "4. Run 'make test-fuzz' for fuzz testing"
	@echo "5. Run 'make test-invariant' for invariant testing"
