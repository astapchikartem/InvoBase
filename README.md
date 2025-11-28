# InvoBase

On-chain invoicing protocol for Base network. Each invoice is represented as an NFT with full lifecycle management, transparent settlement tracking, and UUPS upgradeability.

## Overview

InvoBase enables freelancers, teams, DAOs, and businesses to issue, track, and settle invoices entirely on-chain using Base network. Invoices are minted as non-transferable NFTs, ensuring tamper-proof records and transparent payment history.

## Core Features

**Invoice-as-NFT Architecture**
- Each invoice is a unique ERC721 token with embedded metadata
- Non-transferable to prevent invoice trading or manipulation
- Full lifecycle tracking: Draft → Issued → Paid → Cancelled

**On-Chain Settlement**
- Native USDC support for payments
- Transparent payment history indexed on Base
- Designed for Base Pay integration (future)

**Upgradeable Infrastructure**
- UUPS proxy pattern for future enhancements
- Storage-safe upgrades with OpenZeppelin contracts
- Single proxy deployment per network

## Contract Addresses

### Base Mainnet
**InvoiceNFT Proxy:** `0xE8E1563be6e10a764C24A46158f661e53D407771`
[View on Basescan](https://basescan.org/address/0xe8e1563be6e10a764c24a46158f661e53d407771)

### Base Sepolia (Testnet)
**InvoiceNFT Proxy:** `0x59aD7168615DeE3024c4d2719eDAb656ad9cCE9c`
[View on Basescan](https://sepolia.basescan.org/address/0x59ad7168615dee3024c4d2719edab656ad9cce9c)

## Use Cases

- **Freelancers:** Issue invoices directly to clients on Base with USDC settlement
- **DAOs:** Generate invoices for contributors and service providers
- **B2B:** Create transparent invoice trails for business agreements
- **Platforms:** Issue invoices on behalf of users with full auditability

## Technical Stack

- **Solidity:** 0.8.24 with IR optimizer
- **Framework:** Foundry
- **Network:** Base L2 (Mainnet + Sepolia)
- **Standards:** ERC721, UUPS (ERC1967)
- **Dependencies:** OpenZeppelin Contracts Upgradeable v5.0.2

## Development

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with gas report
forge test --gas-report
```

## License

MIT
