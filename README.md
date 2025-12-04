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
│  Lifecycle: Draft → Issued → Paid → Cancelled           │
│  • mint(payer, amount, dueDate)                         │
│  • mintWithToken(payer, amount, dueDate, token, memo)  │
│  • issue(tokenId)                                       │
│  • cancel(tokenId)                                      │
│  • pay(tokenId) / payWithToken(tokenId, amount)        │
│  • getPaymentStatus(tokenId)                           │
└────────────┬─────────────────────────────────────────────┘
             │
             │ integrates with
             ▼
┌──────────────────────────────────────────────────────────┐
│                  InvoicePayment                          │
│                  (Escrow Contract)                       │
├──────────────────────────────────────────────────────────┤
│  Payment Processing:                                     │
│  • payInvoice(invoiceId) - ETH payment                  │
│  • payInvoiceToken(invoiceId, token, amount)           │
│  • payInvoicePartial(invoiceId, amount)                │
│  • releasePayment(invoiceId) - issuer claims funds     │
│  • refund(invoiceId) - refund if cancelled             │
│  • recordExternalPayment(invoiceId, ref)               │
│                                                          │
│  Escrow Model:                                          │
│  • Funds held in contract until release/refund         │
│  • Automatic status updates on payment                 │
│  • Support for ETH and ERC20 tokens (USDC)             │
└────────────┬─────────────────────────────────────────────┘
             │
             │ used by
             ▼
┌──────────────────────────────────────────────────────────┐
│                    PaymentLink                           │
│              (Shareable Payment URLs)                    │
├──────────────────────────────────────────────────────────┤
│  Link Management:                                        │
│  • generateLink(invoiceId, expiry) → linkId            │
│  • payViaLink(linkId) - pay with ETH                   │
│  • payViaLinkToken(linkId, token, amount)              │
│  • isLinkValid(linkId)                                 │
│                                                          │
│  Features:                                              │
│  • Expiry-based validation                             │
│  • One-time use enforcement                            │
│  • Pay from any address                                │
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
- UUPS proxy pattern for InvoiceNFT
- Storage-safe upgrades with OpenZeppelin contracts
- Modular architecture with separate payment contracts

## Contract Addresses

### Base Mainnet (V2 - Live)
- **InvoiceNFT V2 Proxy:** `0xE8E1563be6e10a764C24A46158f661e53D407771` [↗](https://basescan.org/address/0xe8e1563be6e10a764c24a46158f661e53d407771)
- **InvoicePayment:** `0x7b80808915e58D56E7bB8b12bc860d9BA5029c20` [↗](https://basescan.org/address/0x7b80808915e58d56e7bb8b12bc860d9ba5029c20)
- **PaymentLink:** `0x0374A00b3bA4143B5e1992f38CC5405c0AaEBC7f` [↗](https://basescan.org/address/0x0374a00b3ba4143b5e1992f38cc5405c0aaebc7f)
- **USDC Token:** `0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913`

### Base Sepolia (V2 - Testnet)
- **InvoiceNFT V2 Proxy:** `0x59aD7168615DeE3024c4d2719eDAb656ad9cCE9c` [↗](https://sepolia.basescan.org/address/0x59ad7168615dee3024c4d2719edab656ad9cce9c)
- **InvoicePayment:** `0x775d86D38c6C41a096839f1B0d803B6373d18B82` [↗](https://sepolia.basescan.org/address/0x775d86d38c6c41a096839f1b0d803b6373d18b82)
- **PaymentLink:** `0xeb13D023920f335B7B4639eCbAB3D479C53825d8` [↗](https://sepolia.basescan.org/address/0xeb13d023920f335b7b4639ecbab3d479c53825d8)
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
- **Dependencies:** OpenZeppelin Contracts Upgradeable v5.0.2

## License

MIT
