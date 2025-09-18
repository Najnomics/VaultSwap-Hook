# -----------------------------------------------------------------------------
# This Makefile is used for building the VaultSwap AVS application.
#
# It contains basic targets for building the application, installing dependencies,
# and building a Docker container.
#
# Modify each target as needed to suit your application's requirements.
# -----------------------------------------------------------------------------

GO = $(shell which go)
OUT = ./bin

build: deps
	@mkdir -p $(OUT) || true
	@echo "Building VaultSwap Performer binary..."
	go build -o $(OUT)/performer ./cmd/main.go

build-contracts:
	@echo "Building VaultSwap contracts..."
	cd contracts && forge build

deps:
	GOPRIVATE=github.com/Layr-Labs/* go mod tidy

build/container:
	./.hourglass/scripts/buildContainer.sh

test: test-go test-forge

test-go::
	go test ./... -v -p 1

test-forge:
	cd contracts && forge test

clean:
	rm -rf $(OUT)
	cd contracts && forge clean

deploy-l1:
	@echo "Deploying VaultSwap L1 contracts..."
	cd contracts && forge script script/DeployVaultSwapL1Contracts.s.sol:DeployVaultSwapL1Contracts --rpc-url $(L1_RPC) --broadcast --verify

deploy-l2:
	@echo "Deploying VaultSwap L2 contracts..."
	cd contracts && forge script script/DeployVaultSwapL2Contracts.s.sol:DeployVaultSwapL2Contracts --rpc-url $(L2_RPC) --broadcast --verify

verify-deployment:
	@echo "Verifying VaultSwap deployment..."
	cd contracts && forge script script/DeployVaultSwapL1Contracts.s.sol:DeployVaultSwapL1Contracts --rpc-url $(L1_RPC) --verify-deployment $(SERVICE_MANAGER_ADDRESS)

.PHONY: build build-contracts deps test test-go test-forge clean deploy-l1 deploy-l2 verify-deployment