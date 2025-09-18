# VaultSwap Hook Installation Guide

This guide will help you install and set up VaultSwap Hook on your system.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation Methods](#installation-methods)
- [Configuration](#configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **Operating System**: macOS, Linux, or Windows
- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free space
- **Network**: Stable internet connection

### Required Software

- **Node.js**: 18+ with pnpm
- **Foundry**: Latest version
- **Go**: 1.21+ (for AVS components)
- **Docker**: For local development
- **Git**: For version control

## Installation Methods

### Method 1: Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/VaultSwap/VaultSwap-Hook.git
cd VaultSwap-Hook

# Run the installation script
./scripts/install.sh
```

### Method 2: Manual Install

#### 1. Install Node.js and pnpm

**macOS (using Homebrew):**
```bash
# Install Node.js
brew install node

# Install pnpm
npm install -g pnpm
```

**Linux (Ubuntu/Debian):**
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install pnpm
npm install -g pnpm
```

**Windows:**
```bash
# Download and install Node.js from https://nodejs.org/
# Then install pnpm
npm install -g pnpm
```

#### 2. Install Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash

# Restart your shell or run:
source ~/.bashrc

# Install the latest version
foundryup
```

#### 3. Install Go

**macOS (using Homebrew):**
```bash
brew install go
```

**Linux:**
```bash
# Download and install Go from https://golang.org/dl/
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
```

**Windows:**
```bash
# Download and install Go from https://golang.org/dl/
```

#### 4. Install Docker

**macOS:**
```bash
# Download Docker Desktop from https://www.docker.com/products/docker-desktop
```

**Linux:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**Windows:**
```bash
# Download Docker Desktop from https://www.docker.com/products/docker-desktop
```

#### 5. Install Project Dependencies

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

### Method 3: Docker Install

#### 1. Create Dockerfile

```dockerfile
# Dockerfile
FROM node:18-alpine

# Install system dependencies
RUN apk add --no-cache git curl

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
RUN /root/.foundry/bin/foundryup

# Install Go
RUN apk add --no-cache go

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./
COPY avs/go.mod avs/go.sum ./avs/

# Install dependencies
RUN npm install -g pnpm
RUN pnpm install
RUN cd avs && go mod download

# Copy source code
COPY . .

# Build the project
RUN forge build
RUN cd avs && go build -o bin/vaultswap-performer cmd/main.go

# Expose ports
EXPOSE 3000 8545 8546

# Start the application
CMD ["pnpm", "start"]
```

#### 2. Build and Run

```bash
# Build the Docker image
docker build -t vaultswap-hook .

# Run the container
docker run -p 3000:3000 -p 8545:8545 -p 8546:8546 vaultswap-hook
```

## Configuration

### 1. Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Edit environment variables
nano .env
```

### 2. Configure Environment Variables

```bash
# RPC URLs
L1_RPC_URL=http://localhost:8545
L2_RPC_URL=http://localhost:8546

# Private keys (for testing only)
L1_PRIVATE_KEY=0x...
L2_PRIVATE_KEY=0x...

# Contract addresses (will be set after deployment)
HOOK_ADDRESS=0x...
FHE_TOKEN_ADDRESS=0x...
SERVICE_MANAGER_ADDRESS=0x...
TASK_HOOK_ADDRESS=0x...

# AVS configuration
AVS_PRIVATE_KEY=0x...
AVS_RPC_URL=http://localhost:8545

# Network configuration
CHAIN_ID=1
GAS_PRICE=20000000000
GAS_LIMIT=1000000

# Security settings
ENABLE_MEV_PROTECTION=true
MEV_PROTECTION_LEVEL=5
ENABLE_DECOY_ORDERS=true
MAX_SLIPPAGE=300

# Privacy settings
ENABLE_FHE=true
FHE_KEY_PATH=./keys/fhe.key
PRIVATE_KEY_PATH=./keys/private.key

# Monitoring
ENABLE_MONITORING=true
LOG_LEVEL=info
METRICS_PORT=9090
```

## Verification

### 1. Check Installation

```bash
# Check Node.js version
node --version
# Should output: v18.x.x or higher

# Check pnpm version
pnpm --version
# Should output: 8.x.x or higher

# Check Foundry version
forge --version
# Should output: forge 0.2.x

# Check Go version
go version
# Should output: go version go1.21.x

# Check Docker version
docker --version
# Should output: Docker version 24.x.x
```

### 2. Verify Dependencies

```bash
# Check Node.js dependencies
pnpm list

# Check Foundry dependencies
forge install

# Check Go dependencies
cd avs
go mod verify
cd ..
```

### 3. Run Tests

```bash
# Run Solidity tests
forge test

# Run Go tests
cd avs
go test ./...
cd ..

# Run integration tests
pnpm test
```

### 4. Build Project

```bash
# Build smart contracts
forge build

# Build AVS performer
cd avs
go build -o bin/vaultswap-performer cmd/main.go
cd ..

# Build frontend
pnpm build
```

## Troubleshooting

### Common Issues

#### 1. Node.js Version Issues

**Problem**: Node.js version is too old
```bash
# Update Node.js
# macOS
brew upgrade node

# Linux
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Windows: Download from https://nodejs.org/
```

#### 2. Foundry Installation Issues

**Problem**: Foundry not found
```bash
# Reinstall Foundry
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
```

#### 3. Go Module Issues

**Problem**: Go modules not downloading
```bash
# Set Go proxy
export GOPROXY=https://proxy.golang.org,direct

# Clean module cache
go clean -modcache

# Download modules
cd avs
go mod download
cd ..
```

#### 4. Docker Issues

**Problem**: Docker not running
```bash
# Start Docker service
# macOS: Start Docker Desktop
# Linux
sudo systemctl start docker

# Windows: Start Docker Desktop
```

#### 5. Permission Issues

**Problem**: Permission denied errors
```bash
# Fix file permissions
chmod +x scripts/*.sh

# Fix directory permissions
chmod 755 .
```

### Debug Commands

```bash
# Check system resources
free -h
df -h

# Check network connectivity
ping google.com

# Check port availability
netstat -tulpn | grep :8545

# Check logs
tail -f logs/vaultswap.log
```

### Getting Help

- **GitHub Issues**: Report issues on GitHub
- **Discord**: Get help on Discord
- **Documentation**: Check the documentation
- **FAQ**: Read the FAQ

## Next Steps

### 1. Deploy Contracts

```bash
# Deploy to Anvil
./scripts/deploy-anvil.sh

# Deploy to testnet
./scripts/deploy-testnet.sh
```

### 2. Start Development

```bash
# Start Anvil
anvil

# Start AVS performer
cd avs
go run cmd/main.go
```

### 3. Run Tests

```bash
# Run all tests
forge test
go test ./...
pnpm test
```

### 4. Build Application

```bash
# Build everything
forge build
cd avs && go build -o bin/vaultswap-performer cmd/main.go
pnpm build
```

## Uninstallation

### Remove Dependencies

```bash
# Remove Node.js dependencies
rm -rf node_modules pnpm-lock.yaml

# Remove Foundry dependencies
rm -rf lib

# Remove Go dependencies
cd avs
go clean -modcache
cd ..
```

### Remove Installation

```bash
# Remove project directory
rm -rf VaultSwap-Hook

# Remove global packages (optional)
npm uninstall -g pnpm
```

## Support

### Installation Support

- **GitHub Issues**: Report installation issues
- **Discord**: Get help with installation
- **Email**: Contact support for complex issues

### Documentation

- **[Getting Started](GETTING_STARTED.md)** - Next steps after installation
- **[Configuration](CONFIGURATION.md)** - Configuration options
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions

---

**Installation complete?** Check out our [Getting Started Guide](GETTING_STARTED.md) or [Quick Start Guide](QUICKSTART.md).

**Having issues?** Visit our [Troubleshooting Guide](TROUBLESHOOTING.md) or join our [Discord](https://discord.gg/vaultswap).

**Ready to deploy?** See our [Deployment Guide](DEPLOYMENT.md).

---

*This installation guide is regularly updated. Last updated: January 1, 2024*