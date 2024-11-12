# Contract Upgrade Guide

## Overview

This guide explains how to upgrade InvoBase smart contracts using the UUPS proxy pattern.

## Why Upgrade?

Reasons to upgrade contracts:
- 🐛 Bug fixes
- ✨ New features
- ⚡ Gas optimizations
- 🔒 Security improvements
- 📊 Enhanced functionality

## Before You Upgrade

### 1. Review Changes

```bash
# View differences between V1 and V2
git diff contracts/InvoiceNFT.sol contracts/InvoiceNFTV2.sol
```

### 2. Run Tests Locally

```bash
# Compile new version
yarn compile

# Run upgrade tests
yarn test test/Upgrade.test.js

# Run all tests
yarn test
```

### 3. Check Storage Layout

Ensure no storage conflicts:
```bash
npx hardhat check
```

## Upgrade Process

### Testnet Upgrade (Base Sepolia)

**Via GitHub Actions** (Recommended):

1. Go to Actions → "Upgrade Base Sepolia Contracts"
2. Click "Run workflow"
3. Enter version number (e.g., "2.0.0")
4. Click "Run workflow"

**Manual**:

```bash
# Set environment variables
export DEPLOYER_PRIVATE_KEY="your_key"
export BASE_SEPOLIA_RPC="rpc_url"
export BASESCAN_API_KEY="api_key"

# Run upgrade
yarn upgrade:sepolia
```

### Mainnet Upgrade (Base Mainnet)

⚠️ **CRITICAL**: Test thoroughly on Sepolia first!

**Via GitHub Actions**:

1. Go to Actions → "Upgrade Base Mainnet Contracts"
2. Click "Run workflow"
3. Enter version number (e.g., "2.0.0")
4. Type "upgrade" in confirmation field
5. Click "Run workflow"

**Manual**:

```bash
# Set environment variables
export DEPLOYER_PRIVATE_KEY="your_key"
export BASE_RPC="rpc_url"
export BASESCAN_API_KEY="api_key"

# Run upgrade
yarn upgrade:mainnet
```

## What Happens During Upgrade

### Step-by-Step

1. **Compile New Version**
   ```
   InvoiceNFTV2.sol → bytecode
   PaymentProcessorV2.sol → bytecode
   ```

2. **Deploy New Implementation**
   ```
   Deploy InvoiceNFTV2 → 0x5678...
   Deploy PaymentProcessorV2 → 0x9ABC...
   ```

3. **Upgrade Proxy**
   ```
   Proxy.upgradeTo(0x5678...)
   Proxy still at 0xABCD... (same address!)
   ```

4. **Verify**
   ```
   Check version() → "2.0.0"
   Check old data → Still exists
   Test new features → Working
   ```

5. **Save Deployment Data**
   ```
   deployments/
   ├── baseSepolia-84532.json (updated)
   └── upgrades/
       └── upgrade-1699999999-baseSepolia.json
   ```

## Post-Upgrade Verification

### 1. Check Version

```javascript
const version = await invoiceNFT.version();
console.log(version); // "2.0.0"
```

### 2. Verify Old Data

```javascript
// Check existing invoice
const invoice = await invoiceNFT.getInvoice(1);
console.log(invoice.creator); // Should still exist

// Check NFT ownership
const owner = await invoiceNFT.ownerOf(1);
console.log(owner); // Should be same as before
```

### 3. Test New Features

```javascript
// V2 feature: Statistics
const stats = await invoiceNFT.getStatistics();
console.log(stats.total); // Shows total invoices

// V2 feature: Batch creation
const tokenIds = await invoiceNFT.batchCreateInvoices(
  recipients, amounts, tokens, descriptions, dueDates
);
```

### 4. Check on Basescan

- Go to proxy address on Basescan
- Verify "Implementation" points to new address
- Check "Read as Proxy" for new functions
- Review upgrade transaction

## Rollback (If Needed)

If issues found, can rollback:

```javascript
// Upgrade back to V1 implementation
const oldImplementation = "0x1234..."; // From deployment file
await proxy.upgradeToAndCall(oldImplementation, "0x");
```

## Common Issues

### Issue 1: Storage Collision

**Symptom**: Data corruption after upgrade
**Cause**: Changed storage layout
**Solution**: Deploy corrected version, rollback immediately

### Issue 2: Initialize Called Twice

**Symptom**: "Initializable: contract is already initialized"
**Cause**: Trying to initialize upgraded contract
**Solution**: Don't call initialize on upgrades (only on initial deploy)

### Issue 3: Access Denied

**Symptom**: "AccessControl: account ... is missing role"
**Cause**: UPGRADER_ROLE not granted
**Solution**: Grant role before upgrade

```solidity
await contract.grantRole(UPGRADER_ROLE, upgrader.address);
```

### Issue 4: Gas Limit Exceeded

**Symptom**: Transaction fails with out of gas
**Cause**: V2 implementation too large
**Solution**: Optimize or split into multiple contracts

## V1 to V2 Changes

### InvoiceNFT V2

**New State Variables**:
```solidity
uint256 public totalInvoicesCreated;
mapping(address => uint256) public userTotalInvoiced;
mapping(InvoiceStatus => uint256) public invoicesByStatus;
```

**New Functions**:
- `version()` - Returns "2.0.0"
- `getStatistics()` - Global statistics
- `getUserStatistics(address)` - User-specific stats
- `batchCreateInvoices(...)` - Create multiple invoices

**Modified Functions**:
- `createInvoice()` - Now tracks statistics
- `markAsPaid()` - Updates status counters
- `cancelInvoice()` - Updates status counters

### PaymentProcessor V2

**New State Variables**:
```solidity
uint256 public totalPaymentsProcessed;
uint256 public totalVolumeProcessed;
mapping(address => uint256) public userPaymentCount;
mapping(address => uint256) public userPaymentVolume;
mapping(address => uint256) public tokenVolumeProcessed;
```

**New Functions**:
- `version()` - Returns "2.0.0"
- `getGlobalStatistics()` - Global payment stats
- `getUserStatistics(address)` - User payment stats
- `getTokenStatistics(address)` - Token-specific volume
- `batchUpdateTokenSupport(...)` - Update multiple tokens

**Modified Functions**:
- `processPayment()` - Now tracks statistics

## Best Practices

### Before Upgrade

1. ✅ Test on testnet for 24-48 hours
2. ✅ Get security audit for major changes
3. ✅ Announce upgrade to users
4. ✅ Prepare rollback plan
5. ✅ Backup deployment data

### During Upgrade

1. ✅ Pause contracts (if possible)
2. ✅ Monitor transaction closely
3. ✅ Have team ready to respond
4. ✅ Verify on Basescan immediately

### After Upgrade

1. ✅ Test all major functions
2. ✅ Monitor for issues (24 hours)
3. ✅ Update documentation
4. ✅ Announce completion
5. ✅ Tag release in Git

## Security Checklist

Before mainnet upgrade:

- [ ] All tests passing
- [ ] No storage layout changes (except additions)
- [ ] Access control properly configured
- [ ] Initializer guards in place
- [ ] No selfdestruct or delegatecall vulnerabilities
- [ ] Reentrancy protection maintained
- [ ] Events properly emitted
- [ ] Gas costs acceptable
- [ ] Basescan verification working
- [ ] Testnet upgrade successful

## Upgrade Timeline

**Recommended Schedule**:

```
Day 1: Deploy V2 to Sepolia
Day 2-3: Test on Sepolia
Day 4: Community review
Day 5: Security audit (if major changes)
Day 6: Fix any issues
Day 7: Deploy to Mainnet
Day 8-14: Monitor closely
```

## Getting Help

If issues during upgrade:

1. Check GitHub Actions logs
2. Review upgrade transaction on Basescan
3. Run local tests to reproduce
4. Check deployment files in `deployments/`
5. Create GitHub issue with details

## References

- [OpenZeppelin Upgrades](https://docs.openzeppelin.com/upgrades-plugins/1.x/)
- [UUPS Pattern](https://eips.ethereum.org/EIPS/eip-1822)
- [Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
- [Proxy Architecture Doc](./PROXY_ARCHITECTURE.md)
