# Architecture Documentation

## Overview

InvoiceBase is a decentralized invoicing system built on the Base network, designed to enable trustless invoice creation, tracking, and settlement.

## Core Components

### InvoiceManager
The main contract responsible for invoice lifecycle management. Implements UUPS upgradeable pattern for future improvements.

**Key Responsibilities:**
- Invoice creation and issuance
- Payment processing
- Invoice cancellation
- State management

### InvoiceNFT
ERC721-based NFT contract that mints receipt tokens upon successful payment. These NFTs serve as immutable proof of payment.

**Features:**
- On-chain metadata
- Base64-encoded JSON
- Immutable payment records

### InvoiceFactory
Factory contract for deploying isolated InvoiceManager instances for different organizations or use cases.

### Libraries

#### InvoiceLib
Core business logic library containing:
- Status checks (overdue, pending, settled)
- Late fee calculations
- Validation functions
- Date utilities

#### Constants
Centralized configuration values:
- Amount limits
- Fee percentages
- Token addresses
- Network-specific settings

## Data Flow

```
1. Issuer creates draft invoice
   ↓
2. Issuer issues invoice with due date
   ↓
3. Payer pays invoice
   ↓
4. Payment processed via ERC20 transfer
   ↓
5. Receipt NFT minted to payer
```

## Security Considerations

- Reentrancy protection on all state-changing functions
- Access control enforcement
- Input validation
- Upgradeable contracts with UUPS pattern
- OpenZeppelin audited libraries

## Upgrade Process

1. Deploy new implementation contract
2. Call `upgradeTo()` on proxy (owner only)
3. New logic takes effect immediately
4. Storage layout preserved

## Gas Optimization

- Storage packing for frequently accessed data
- IR-based compiler optimization
- Minimal external calls
- Efficient loop implementations
