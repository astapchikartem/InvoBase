# InvoBase V2

On-chain invoicing protocol with real payment processing on Base network. Each invoice is represented as an NFT with full lifecycle management, escrow-based payments, shareable payment links, and UUPS upgradeability.

## Overview

InvoBase V2 enables freelancers, teams, DAOs, and businesses to issue, track, and settle invoices with **real payment processing** entirely on-chain using Base network. Invoices are minted as non-transferable NFTs, with funds held in escrow until confirmed, ensuring tamper-proof records and transparent payment history.

## Architecture

```
┌──────────────────────────────────────────────────────────┐
│                    InvoiceNFT V2                         │
│                  (UUPS Upgradeable)                      │
├──────────────────────────────────────────────────────────┤
│  Lifecycle: Draft → Issued → Paid → Cancelled            │
│  • mint(payer, amount, dueDate)                          │
│  • mintWithToken(payer, amount, dueDate, token, memo)    │
│  • issue(tokenId)                                        │
│  • cancel(tokenId)                                       │
│  • pay(tokenId) / payWithToken(tokenId, amount)          │
│  • getPaymentStatus(tokenId)                             │
└────────────┬─────────────────────────────────────────────┘
             │
             │ integrates with
             ▼
┌──────────────────────────────────────────────────────────┐
│                  InvoicePayment                          │
│            (Escrow Contract - UUPS Upgradeable)          │
├──────────────────────────────────────────────────────────┤
│  Payment Processing:                                     │
│  • payInvoice(invoiceId) - ETH payment                   │
│  • payInvoiceToken(invoiceId, token, amount)             │
│  • payInvoicePartial(invoiceId, amount)                  │
│  • releasePayment(invoiceId) - issuer claims funds       │
│  • refund(invoiceId) - refund if cancelled               │
│  • recordExternalPayment(invoiceId, ref)                 │
│                                                          │
│  Escrow Model:                                           │
│  • Funds held in contract until release/refund           │
│  • Automatic status updates on payment                   │
│  • Support for ETH and ERC20 tokens (USDC)               │
└────────────┬─────────────────────────────────────────────┘
             │
             │ used by
             ▼
┌──────────────────────────────────────────────────────────┐
│                    PaymentLink                           │
│        (Shareable Payment URLs - UUPS Upgradeable)       │
├──────────────────────────────────────────────────────────┤
│  Link Management:                                        │
│  • generateLink(invoiceId, expiry) → linkId              │
│  • payViaLink(linkId) - pay with ETH                     │
│  • payViaLinkToken(linkId, token, amount)                │
│  • isLinkValid(linkId)                                   │
│                                                          │
│  Features:                                               │
│  • Expiry-based validation                               │
│  • One-time use enforcement                              │
│  • Pay from any address                                  │
└──────────────────────────────────────────────────────────┘
```

## Core Features

**Invoice-as-NFT Architecture**
- Each invoice is a unique ERC721 token with embedded metadata
- Non-transferable to prevent invoice trading or manipulation
- Full lifecycle tracking: Draft → Issued → Paid → Cancelled
- Token-specific invoices with memos

**Real Payment Processing (NEW in V2)**
- Escrow-based payments: funds held in contract until release
- Support for ETH and ERC20 tokens (USDC on Base)
- Partial payment tracking
- Automatic status updates on payment
- Issuer releases funds after confirmation
- Full refund capability for cancelled invoices

**Shareable Payment Links (NEW in V2)**
- Generate unique payment links with expiry dates
- Pay from any address (not just designated payer)
- One-time use enforcement
- Support ETH and token payments
- Perfect for sharing invoices via email/social

**External Payment Recording**
- Record off-chain payments (e.g., Base Pay)
- Link external payment references to invoices
- Maintain complete payment audit trail

**Upgradeable Infrastructure**
- UUPS proxy pattern for all contracts (InvoiceNFT, InvoicePayment, PaymentLink)
- Storage-safe upgrades with OpenZeppelin contracts
- Modular architecture with separate payment contracts

## Contract Addresses

### Base Mainnet (V2 - Live)
- **InvoiceNFT V2 Proxy:** `0xab5B5Be29048339De2Bf79c51c1634adC987deFb` [↗](https://basescan.org/address/0xab5B5Be29048339De2Bf79c51c1634adC987deFb)
- **InvoicePayment Proxy:** `0x9a4F17a4dE62be11738d15b39bb0Dfba88cA9B74` [↗](https://basescan.org/address/0x9a4F17a4dE62be11738d15b39bb0Dfba88cA9B74)
- **PaymentLink Proxy:** `0xDe9aD4eD1909204319AF94605d40CA5886fB97f8` [↗](https://basescan.org/address/0xDe9aD4eD1909204319AF94605d40CA5886fB97f8)
- **USDC Token:** `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`

### Base Sepolia (V2 - Testnet)
- **InvoiceNFT V2 Proxy:** `0x8C49fb4c7512A238D7A6fC9B612A0deFFA4890f5` [↗](https://sepolia.basescan.org/address/0x8C49fb4c7512A238D7A6fC9B612A0deFFA4890f5)
- **InvoicePayment Proxy:** `0x73CBc9E6Ac0b17Ba0b42c9c68Fbb3B9f55485540` [↗](https://sepolia.basescan.org/address/0x73CBc9E6Ac0b17Ba0b42c9c68Fbb3B9f55485540)
- **PaymentLink Proxy:** `0x5C0D87f9a97eF5592c47D7649668b1a2F9a03DcA` [↗](https://sepolia.basescan.org/address/0x5C0D87f9a97eF5592c47D7649668b1a2F9a03DcA)
- **USDC Token:** `0x036CbD53842c5426634e7929541eC2318f3dCF7e`

## Use Cases

- **Freelancers:** Issue invoices with real escrow-based payment processing, generate shareable payment links
- **DAOs:** Pay contributors with automatic escrow and transparent settlement
- **B2B:** Create invoices with USDC payments, track partial payments, automatic release on confirmation
- **Platforms:** Issue invoices with payment links, integrate with external payment systems (Base Pay)

## Technical Stack

- **Solidity:** 0.8.24 with IR optimizer
- **Framework:** Foundry
- **Network:** Base L2 (Mainnet + Sepolia)
- **Standards:** ERC721, UUPS (ERC1967)
- **Dependencies:** OpenZeppelin Contracts Upgradeable v4.9.6

## License

MIT
