#!/bin/bash

# VaultSwap Hook - Anvil Deployment Script
# This script deploys VaultSwap Hook to a local Anvil node

set -e

echo "🚀 Deploying VaultSwap Hook to Anvil..."

# Check if Anvil is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo "❌ Anvil is not running. Please start Anvil first:"
    echo "   anvil"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
else
    echo "⚠️  No .env file found. Using default values."
fi

# Set default values
RPC_URL=${ANVIL_RPC_URL:-http://localhost:8545}
PRIVATE_KEY=${ANVIL_PRIVATE_KEY:-0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80}

echo "📋 Deployment Configuration:"
echo "   RPC URL: $RPC_URL"
echo "   Private Key: ${PRIVATE_KEY:0:10}..."

# Build contracts
echo "🔨 Building contracts..."
forge build

# Deploy VaultSwap Hook
echo "📦 Deploying VaultSwap Hook..."
forge script script/DeployVaultSwapHookSimple.s.sol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --skip-simulation

echo "✅ VaultSwap Hook deployed successfully to Anvil!"
echo ""
echo "📊 Contract Addresses:"
echo "   VaultSwap Hook: $(jq -r '.transactions[0].contractAddress' broadcast/DeployVaultSwapHookSimple.s.sol/31337/run-latest.json)"
echo ""
echo "🔗 You can now interact with the contracts using:"
echo "   cast call <CONTRACT_ADDRESS> <FUNCTION_SIGNATURE> --rpc-url $RPC_URL"
