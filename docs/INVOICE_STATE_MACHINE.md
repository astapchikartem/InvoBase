# Invoice State Machine

## Overview

InvoBase invoices follow a strict state machine with clear transitions and validation rules. This document defines the complete invoice lifecycle for developers and integrators.

## States

### Draft (0)
- **Description**: Invoice created but not yet published
- **When**: After calling `mint()` or `mintWithToken()`
- **Characteristics**:
  - Cannot receive payments
  - Can be modified by issuer
  - Can be cancelled or issued

### Issued (1)
- **Description**: Invoice published and ready for payment
- **When**: After calling `issue()` on a Draft invoice
- **Characteristics**:
  - Available for payment
  - Can receive full or partial payments (if enabled)
  - Can be cancelled by issuer (triggers refund if payments exist)
  - Cannot be modified

### Paid (2)
- **Description**: Invoice fully paid
- **When**: Automatically set when full payment is received
- **Characteristics**:
  - Payment completed
  - Cannot be cancelled
  - Cannot receive additional payments
  - Funds available for release to issuer

### Cancelled (3)
- **Description**: Invoice cancelled by issuer
- **When**: Issuer calls `cancel()` on Draft or Issued invoice
- **Characteristics**:
  - Cannot receive payments
  - Cannot transition to any other state
  - If payments existed, they are refunded automatically

## State Transitions

### Valid Transitions

```
Draft → Issued
  Trigger: issuer.issue(tokenId)
  Who: Issuer only
  Conditions: status == Draft
  Effects: Invoice becomes payable

Issued → Paid
  Trigger: Full payment received (automatic)
  Who: Payment contract callback
  Conditions: Full payment confirmed
  Effects: Invoice marked as complete, funds held in escrow

Draft → Cancelled
  Trigger: issuer.cancel(tokenId)
  Who: Issuer only
  Conditions: status == Draft, no payments made
  Effects: Invoice invalidated, no refunds needed

Issued → Cancelled
  Trigger: issuer.cancel(tokenId)
  Who: Issuer only
  Conditions: status == Issued
  Effects: Invoice invalidated, automatic refund if payments exist
```

### Forbidden Transitions

```
Paid → Cancelled
  Reason: Cannot cancel a completed payment
  Error: CannotCancelPaidInvoice

Cancelled → Issued
  Reason: One-way cancellation (prevents abuse)
  Error: InvalidTransition

Cancelled → Paid
  Reason: Invalid state
  Error: InvalidTransition

Issued → Issued
  Reason: Already in target state
  Error: InvalidTransition
```

## Payment Flows

### Full Payment (ETH)

1. Invoice in **Issued** state
2. Payer calls `InvoicePayment.payInvoice(tokenId)` with exact amount
3. Payment contract validates amount (rejects underpayment/overpayment)
4. Payment contract calls `InvoiceNFT.markAsPaid(tokenId)`
5. Invoice transitions to **Paid** state
6. Funds held in escrow until `releasePayment()` called

### Full Payment (ERC-20)

1. Invoice in **Issued** state with token address set
2. Payer approves token transfer
3. Payer calls `InvoicePayment.payInvoiceToken(tokenId, token, amount)`
4. Payment contract validates token support and amount
5. Payment contract calls `InvoiceNFT.markAsPaid(tokenId)`
6. Invoice transitions to **Paid** state
7. Tokens held in escrow until `releasePayment()` called

### Partial Payments

1. Issuer enables partial payments: `InvoiceNFT.setPartialPayment(tokenId, true)`
2. Invoice in **Issued** state
3. Payer calls `InvoicePayment.payInvoicePartial(tokenId, amount)` multiple times
4. Each payment adds to running total
5. When total reaches invoice amount:
   - Payment contract calls `InvoiceNFT.markAsPaid(tokenId)`
   - Invoice transitions to **Paid** state
6. Overpayments are rejected (strict mode)

### External Payments (Base Pay, off-chain)

1. Invoice in **Issued** state
2. Payment received off-chain (e.g., via Base Pay)
3. Issuer calls `InvoicePayment.recordExternalPayment(tokenId, paymentRef)`
4. Payment contract calls `InvoiceNFT.markAsPaid(tokenId)`
5. Invoice transitions to **Paid** state
6. `paymentRef` stored for audit trail

### Payment via Link

1. Issuer generates payment link: `PaymentLink.generateLink(tokenId, expiry)`
2. Anyone with link can pay before expiry
3. Link calls `InvoicePayment.payInvoice()` or `payInvoiceToken()`
4. Same flow as direct payment
5. Link marked as used after successful payment

## Cancellation with Refund

### Cancelling Draft Invoice
- No payments possible in Draft state
- Simple status transition
- No refund needed

### Cancelling Issued Invoice
1. Invoice in **Issued** state (with or without payments)
2. Issuer calls `InvoiceNFT.cancel(tokenId)`
3. Status transitions to **Cancelled**
4. If payments exist:
   - NFT contract calls `InvoicePayment.refund(tokenId)`
   - Funds returned to payer
   - Partial payments fully refunded

## Edge Cases Handled

### Overpayments
- **Behavior**: Rejected with `Overpayment` error
- **Reason**: Prevents accidents and simplifies accounting
- **Alternative**: Payer must send exact amount

### Multiple Payment Attempts
- **Behavior**: Second payment rejected with `InvoiceAlreadyPaid`
- **Protection**: `isPaid()` check before processing

### Cancel During Payment (Race Condition)
- **Protection**: State checked in both contracts
- **Result**: One transaction succeeds, other reverts

### Partial Payments Exceeding Total
- **Behavior**: Rejected with `Overpayment` error
- **Protection**: Running total checked before accepting

### External Payment Without Proof
- **Protection**: Only issuer can record external payments
- **Audit**: `paymentRef` required and stored on-chain

## Integration Guide

### For Issuers

```solidity
// 1. Create invoice
uint256 tokenId = nft.mint(payerAddress, amount, dueDate);

// 2. Optionally enable partial payments
nft.setPartialPayment(tokenId, true);

// 3. Publish invoice
nft.issue(tokenId);

// 4. After payment, release funds
payment.releasePayment(tokenId);

// OR cancel if needed
nft.cancel(tokenId); // Auto-refunds if payments exist
```

### For Payers

```solidity
// Pay with ETH
payment.payInvoice{value: exactAmount}(tokenId);

// Pay with ERC-20
token.approve(address(payment), amount);
payment.payInvoiceToken(tokenId, tokenAddress, amount);

// Partial payment (if enabled)
payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
```

### For Payment Link Users

```solidity
// Pay via link with ETH
paymentLink.payViaLink{value: amount}(linkId);

// Pay via link with token
token.approve(address(paymentLink), amount);
paymentLink.payViaLinkToken(linkId, tokenAddress, amount);
```

## State Query Methods

```solidity
// Get full invoice details
Invoice memory invoice = nft.getInvoice(tokenId);
uint8 status = invoice.status; // 0=Draft, 1=Issued, 2=Paid, 3=Cancelled

// Check payment status
(bool paid, uint256 remaining) = nft.getPaymentStatus(tokenId);

// Check remaining amount (for partial payments)
uint256 remaining = payment.getRemainingAmount(tokenId);

// Check if fully paid
bool paid = payment.isPaid(tokenId);
```

## Error Reference

| Error | When | Resolution |
|-------|------|-----------|
| `InvalidTransition` | Attempting forbidden state change | Check current state before transition |
| `CannotCancelPaidInvoice` | Trying to cancel Paid invoice | Paid invoices are final |
| `Overpayment` | Sending more than required | Send exact invoice amount |
| `InsufficientPayment` | Sending less than required | Send full amount or use partial payments |
| `InvoiceAlreadyPaid` | Paying twice | Check `isPaid()` before payment |
| `PartialPaymentNotAllowed` | Partial pay not enabled | Issuer must enable via `setPartialPayment()` |
| `Unauthorized` | Wrong caller | Check issuer/payer requirements |

## Security Considerations

1. **No Transfers**: Invoice NFTs cannot be transferred (soulbound to issuer)
2. **Strict Overpayment Protection**: Exact amounts required
3. **Atomic Callbacks**: Payment → Status update is atomic
4. **Reentrancy Protection**: All payment methods use `nonReentrant`
5. **Single Payment Source**: All payments go through InvoicePayment contract
6. **Audit Trail**: All state changes emit events with full details

## Contract Addresses

### Base Mainnet
- InvoiceNFTV2: `TBD`
- InvoicePayment: `TBD`
- PaymentLink: `TBD`

### Base Sepolia
- InvoiceNFTV2: `TBD`
- InvoicePayment: `TBD`
- PaymentLink: `TBD`

## Changelog

### V2 Lifecycle Improvements (Block 1)
- Added `markAsPaid()` callback for automatic status sync
- Strict state transition validation with `InvalidTransition` error
- Overpayment protection (rejects excess payments)
- Automatic refund on cancellation
- Unified partial payment flag (stored in NFT contract)
- Fixed PaymentLink atomicity (CEI pattern)
- Comprehensive edge case handling

---

**Questions?** File an issue at https://github.com/astapchikartem/InvoBase/issues
