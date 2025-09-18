#!/bin/bash

# VaultSwap Hook - Mainnet Deployment Script
# This script deploys VaultSwap Hook to Ethereum Mainnet

set -e

echo "🚀 Deploying VaultSwap Hook to Ethereum Mainnet..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
else
    echo "❌ No .env file found. Please create one from .env.example"
    exit 1
fi

# Check required environment variables
if [ -z "$MAINNET_RPC_URL" ] || [ -z "$MAINNET_PRIVATE_KEY" ] || [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ Missing required environment variables:"
    echo "   - MAINNET_RPC_URL"
    echo "   - MAINNET_PRIVATE_KEY"
    echo "   - ETHERSCAN_API_KEY"
    exit 1
fi

# Confirmation prompt
echo "⚠️  WARNING: You are about to deploy to Ethereum Mainnet!"
echo "   This will cost real ETH and deploy real contracts."
echo "   Make sure you have tested thoroughly on testnets."
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

echo "📋 Deployment Configuration:"
echo "   Network: Ethereum Mainnet"
echo "   RPC URL: ${MAINNET_RPC_URL:0:30}..."
echo "   Private Key: ${MAINNET_PRIVATE_KEY:0:10}..."

# Build contracts
echo "🔨 Building contracts..."
forge build

# Deploy VaultSwap Hook
echo "📦 Deploying VaultSwap Hook..."
forge script script/DeployVaultSwapHook.s.sol \
    --rpc-url $MAINNET_RPC_URL \
    --private-key $MAINNET_PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $ETHERSCAN_API_KEY

echo "✅ VaultSwap Hook deployed successfully to Ethereum Mainnet!"
echo ""
echo "📊 Contract Addresses:"
echo "   VaultSwap Hook: $(jq -r '.transactions[0].contractAddress' broadcast/DeployVaultSwapHook.s.sol/1/run-latest.json)"
echo ""
echo "🔗 View on Etherscan:"
echo "   https://etherscan.io/address/$(jq -r '.transactions[0].contractAddress' broadcast/DeployVaultSwapHook.s.sol/1/run-latest.json)"
