#!/bin/bash

# VaultSwap Hook - Testnet Deployment Script
# This script deploys VaultSwap Hook to Sepolia testnet

set -e

echo "🚀 Deploying VaultSwap Hook to Sepolia Testnet..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
else
    echo "❌ No .env file found. Please create one from .env.example"
    exit 1
fi

# Check required environment variables
if [ -z "$SEPOLIA_RPC_URL" ] || [ -z "$SEPOLIA_PRIVATE_KEY" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ Missing required environment variables:"
    echo "   - SEPOLIA_RPC_URL"
    echo "   - SEPOLIA_PRIVATE_KEY"
    echo "   - ETHERSCAN_API_KEY"
    exit 1
fi

echo "📋 Deployment Configuration:"
echo "   Network: Sepolia Testnet"
echo "   RPC URL: ${SEPOLIA_RPC_URL:0:30}..."
echo "   Private Key: ${SEPOLIA_PRIVATE_KEY:0:10}..."

# Build contracts
echo "🔨 Building contracts..."
forge build

# Deploy VaultSwap Hook
echo "📦 Deploying VaultSwap Hook..."
forge script script/DeployVaultSwapHook.s.sol \
    --rpc-url $SEPOLIA_RPC_URL \
    --private-key $SEPOLIA_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

echo "✅ VaultSwap Hook deployed successfully to Sepolia!"
echo ""
echo "📊 Contract Addresses:"
echo "   VaultSwap Hook: $(jq -r '.transactions[0].contractAddress' broadcast/DeployVaultSwapHook.s.sol/11155111/run-latest.json)"
echo ""
echo "🔗 View on Etherscan:"
echo "   https://sepolia.etherscan.io/address/$(jq -r '.transactions[0].contractAddress' broadcast/DeployVaultSwapHook.s.sol/11155111/run-latest.json)"
