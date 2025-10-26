# Deployment Guide

## Prerequisites

- Foundry installed
- RPC endpoint for Base (Mainnet or Sepolia)
- Private key with ETH for gas
- Basescan API key for verification

## Environment Setup

Create `.env` file:

```bash
BASE_MAINNET_RPC=https://mainnet.base.org
BASE_SEPOLIA_RPC=https://sepolia.base.org
BASESCAN_API_KEY=your_api_key
PRIVATE_KEY=your_private_key
```

## Deployment Steps

### 1. Deploy to Testnet (Base Sepolia)

```bash
# Deploy all contracts
forge script script/DeployAll.s.sol --rpc-url base_sepolia --broadcast --verify

# Or deploy individual contracts
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast
```

### 2. Verify Contracts

```bash
forge script script/VerifyContracts.s.sol --rpc-url base_sepolia
```

### 3. Test Deployment

```bash
# Interact with deployed contracts
forge script script/InteractInvoice.s.sol --rpc-url base_sepolia --broadcast
```

### 4. Deploy to Mainnet

**⚠️ Double-check all parameters before mainnet deployment!**

```bash
forge script script/DeployAll.s.sol --rpc-url base_mainnet --broadcast --verify --slow
```

## Post-Deployment

1. Save deployed addresses
2. Transfer ownership to multisig
3. Update frontend configuration
4. Monitor initial transactions

## Upgrade Process

```bash
# Deploy new implementation and upgrade
forge script script/ManageUpgrade.s.sol --rpc-url base_mainnet --broadcast
```

## Emergency Procedures

In case of critical issues:

1. Pause contract (if pausable)
2. Notify users
3. Prepare and test fix
4. Deploy upgrade
5. Resume operations

## Gas Optimization Tips

- Use `--optimize` flag with Foundry
- Set high optimizer runs for frequently called functions
- Enable IR-based compiler for production
- Test gas usage before mainnet deployment

```bash
forge test --gas-report
```
