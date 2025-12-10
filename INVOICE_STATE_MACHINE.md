# Invoice State Machine Documentation

## Overview

InvoBase V2 implements a strict state machine for invoice lifecycles. This document describes all possible states, transitions, and the rules governing them.

## States

| State | Value | Description |
|-------|-------|-------------|
| **Draft** | 0 | Invoice created but not yet published. Issuer can still modify terms. |
| **Issued** | 1 | Invoice published and ready for payment. Terms are locked. |
| **Paid** | 2 | Invoice fully paid. Immutable final state. |
| **Cancelled** | 3 | Invoice cancelled by issuer. Can trigger refunds if partially paid. |

## State Diagram

```
┌─────────┐
│  Draft  │
└────┬────┘
     │ issue()
     ▼
┌─────────┐        ┌──────────┐
│ Issued  │───────▶│   Paid   │
└────┬────┘ pay    └──────────┘
     │              (FINAL)
     │ cancel()
     ▼
┌──────────┐
│Cancelled │
└──────────┘
  (FINAL)
```

## State Transitions

### 1. Draft → Issued

**Who can trigger:** Invoice issuer only

**Function:** `InvoiceNFTV2.issue(tokenId)`

**Requirements:**
- Invoice must be in `Draft` state
- Caller must be the invoice issuer

**Effect:**
- Changes status to `Issued`
- Locks invoice terms (amount, token, partial payment flag)
- Invoice becomes payable

**Example:**
```solidity
// Issuer creates invoice
uint256 tokenId = nft.mint(payerAddress, 1000e6, dueDate);

// Set terms (only possible in Draft state)
nft.setPartialPayment(tokenId, true);
nft.setInvoiceToken(tokenId, usdcAddress);

// Publish invoice
nft.issue(tokenId);
```

---

### 2. Issued → Paid

**Who can trigger:**
- Any address (via payment processor)
- Invoice issuer (via external payment recording)

**Functions:**
- `InvoicePayment.payInvoice(invoiceId)` - Full ETH payment
- `InvoicePayment.payInvoiceToken(invoiceId, token, amount)` - Full ERC20 payment
- `InvoicePayment.payInvoicePartial(invoiceId, amount)` - Partial payment
- `InvoicePayment.recordExternalPayment(invoiceId, paymentRef)` - Record off-chain payment (Base Pay, etc.)

**Requirements:**
- Invoice must be in `Issued` state
- Payment amount must match invoice amount exactly (or complete partial payments to 100%)
- For token payments, token must be supported
- Overpayments are rejected to protect payer

**Effect:**
- Changes status to `Paid`
- Funds transferred to issuer (or held in escrow for partial payments)
- Invoice becomes immutable
- Cannot be cancelled

**Payment Flows:**

#### Full Payment (ETH)
```solidity
// Payer pays invoice
payment.payInvoice{value: 1 ether}(tokenId);
// ✓ Funds sent directly to issuer
// ✓ Invoice marked as Paid
```

#### Full Payment (ERC20)
```solidity
// Payer approves and pays
usdc.approve(address(payment), 1000e6);
payment.payInvoiceToken(tokenId, address(usdc), 1000e6);
// ✓ Tokens sent directly to issuer
// ✓ Invoice marked as Paid
```

#### Partial Payments
```solidity
// Issuer enables partial payments (only in Draft state)
nft.setPartialPayment(tokenId, true);
nft.issue(tokenId);

// Payer makes multiple payments
payment.payInvoicePartial{value: 0}(tokenId, 500e6);  // 50%
payment.payInvoicePartial{value: 0}(tokenId, 500e6);  // 50%
// ✓ Partial payments held in contract
// ✓ On final payment, full amount sent to issuer
// ✓ Invoice marked as Paid
```

#### External Payment (Base Pay)
```solidity
// Issuer records external payment
bytes32 paymentRef = keccak256("BASE_PAY_TX_HASH");
payment.recordExternalPayment(tokenId, paymentRef);
// ✓ No on-chain funds transferred
// ✓ Invoice marked as Paid
// ✓ Payment reference stored for verification
```

---

### 3. Draft → Cancelled

**Who can trigger:** Invoice issuer only

**Function:** `InvoiceNFTV2.cancel(tokenId)`

**Requirements:**
- Invoice must be in `Draft` state
- Caller must be the invoice issuer

**Effect:**
- Changes status to `Cancelled`
- No refunds (invoice was never paid)

**Example:**
```solidity
// Issuer cancels draft invoice
nft.cancel(tokenId);
```

---

### 4. Issued → Cancelled

**Who can trigger:** Invoice issuer only

**Function:** `InvoiceNFTV2.cancel(tokenId)`

**Requirements:**
- Invoice must be in `Issued` state
- Caller must be the invoice issuer
- Invoice must NOT be fully paid

**Effect:**
- Changes status to `Cancelled`
- If partial payments exist, issuer must call `refund()` to return funds

**Partial Payment Refund Flow:**
```solidity
// Payer made partial payment
payment.payInvoicePartial{value: 0}(tokenId, 500e6);

// Issuer cancels and refunds
nft.cancel(tokenId);
payment.refund(tokenId);
// ✓ Partial payment returned to payer
// ✓ Invoice in Cancelled state
```

---

## Forbidden Transitions

### ❌ Paid → Any State

Once an invoice is marked as **Paid**, it becomes immutable. No transitions are allowed.

**Blocked actions:**
- Cannot cancel paid invoice: `revert CannotCancelPaidInvoice()`
- Cannot mark as paid again: `revert AlreadyPaid()`

---

### ❌ Cancelled → Issued

Once cancelled, an invoice cannot be re-issued.

**Why:** Prevents invoice manipulation and maintains audit trail integrity.

---

### ❌ Draft → Paid (Direct)

Invoices cannot be paid before being issued.

**Why:** Ensures all invoice terms are locked before accepting payment.

**Blocked actions:**
- Payment on Draft invoice: `revert InvoiceNotIssued()`

---

### ❌ Cancelled → Paid

Cancelled invoices cannot accept payment.

**Blocked actions:**
- Payment on Cancelled invoice: `revert InvoiceCancelled()`

---

## Authorization Rules

| Action | Who Can Execute | State Requirement |
|--------|-----------------|-------------------|
| `mint()` | Anyone | N/A (creates Draft) |
| `issue()` | Issuer only | Draft |
| `setPartialPayment()` | Issuer only | Draft |
| `setInvoiceToken()` | Issuer only | Draft |
| `pay()` / `payInvoiceToken()` | Anyone | Issued |
| `payInvoicePartial()` | Anyone | Issued + partial payments enabled |
| `recordExternalPayment()` | Issuer only | Issued |
| `markAsPaid()` | Payment processor only | Issued |
| `cancel()` | Issuer only | Draft or Issued (not Paid) |
| `refund()` | Issuer only | Cancelled |

---

## Edge Cases & Protections

### 1. Overpayment Protection

**Problem:** Payer accidentally sends more than invoice amount.

**Solution:** Transactions revert with `Overpayment()` error.

```solidity
// Invoice amount: 1 ETH
payment.payInvoice{value: 1.5 ether}(tokenId);
// ❌ Reverts with Overpayment()
```

---

### 2. Double Payment Prevention

**Problem:** Invoice paid twice (e.g., external payment recorded after on-chain payment).

**Solution:**
- Once marked as Paid, all payment functions revert
- `recordExternalPayment()` checks for existing payment

```solidity
payment.payInvoice{value: 1 ether}(tokenId);
// ✓ Invoice now Paid

payment.recordExternalPayment(tokenId, paymentRef);
// ❌ Reverts with InvoiceAlreadyPaid()
```

---

### 3. Parameter Modification Lock

**Problem:** Issuer changes invoice terms after publishing.

**Solution:** `setPartialPayment()` and `setInvoiceToken()` only work in Draft state.

```solidity
nft.issue(tokenId);
nft.setInvoiceToken(tokenId, newToken);
// ❌ Reverts with CannotModifyIssuedInvoice()
```

---

### 4. Partial Payment Refunds

**Problem:** Invoice cancelled after payer made partial payments.

**Solution:** Issuer must call `refund()` to return funds.

```solidity
// Payer made 500 USDC partial payment
payment.payInvoicePartial{value: 0}(tokenId, 500e6);

// Issuer cancels
nft.cancel(tokenId);

// Issuer refunds
payment.refund(tokenId);
// ✓ 500 USDC returned to payer
```

---

### 5. External Payment Verification

**Problem:** No on-chain proof of off-chain payment.

**Solution:** Payment reference (`paymentRef`) stored on-chain for audit.

```solidity
bytes32 paymentRef = keccak256("BASE_PAY_TX_HASH");
payment.recordExternalPayment(tokenId, paymentRef);

// Retrieve payment info
PaymentInfo memory info = payment.getPaymentInfo(tokenId);
// info.paymentRef == keccak256("BASE_PAY_TX_HASH")
```

---

## Integration Guidelines

### For Payers

1. **Check invoice status** before paying:
   ```solidity
   Invoice memory invoice = nft.getInvoice(tokenId);
   require(invoice.status == 1, "Invoice not issued");
   ```

2. **Verify payment amount** matches invoice:
   ```solidity
   require(msg.value == invoice.amount, "Incorrect amount");
   ```

3. **Use payment links** for safer payments (automatic validation).

---

### For Issuers

1. **Set all terms before issuing:**
   ```solidity
   uint256 tokenId = nft.mint(payer, amount, dueDate);
   nft.setPartialPayment(tokenId, true);
   nft.setInvoiceToken(tokenId, usdcAddress);
   nft.issue(tokenId);  // Terms now locked
   ```

2. **Always refund partial payments** when cancelling:
   ```solidity
   nft.cancel(tokenId);
   if (payment.partialPaid(tokenId) > 0) {
       payment.refund(tokenId);
   }
   ```

3. **Record external payments** with unique payment references:
   ```solidity
   bytes32 paymentRef = keccak256(abi.encodePacked("BASE_PAY_", txHash));
   payment.recordExternalPayment(tokenId, paymentRef);
   ```

---

### For Integrators (dApps)

1. **Display current state** clearly to users
2. **Show available actions** based on state and caller role
3. **Validate transitions** before submitting transactions
4. **Handle reverts gracefully** with user-friendly error messages

**Example State-Based UI:**

```typescript
const invoice = await nft.getInvoice(tokenId);

switch (invoice.status) {
  case 0: // Draft
    if (isIssuer) show ["Edit Terms", "Issue", "Cancel"];
    break;
  case 1: // Issued
    if (isPayer) show ["Pay Invoice"];
    if (isIssuer) show ["Cancel", "Record External Payment"];
    break;
  case 2: // Paid
    show ["View Payment Details"];
    break;
  case 3: // Cancelled
    if (isIssuer && partialPaid > 0) show ["Refund Partial Payments"];
    break;
}
```

---

## Upgrade Considerations

InvoBase V2 uses UUPS upgradeable proxies. Future upgrades may:

- Add new states (e.g., `Disputed`, `Overdue`)
- Add new transition paths (e.g., `Paid → Disputed`)
- Extend validation rules

**Upgrade safety rules:**
1. Never change existing state values (0, 1, 2, 3)
2. Never remove existing transitions
3. Always maintain backward compatibility for external integrations

---

## Summary

The InvoBase V2 state machine ensures:

✅ **Predictable lifecycle** - Clear state transitions with no ambiguity
✅ **Protected payments** - Overpayment rejection, double-payment prevention
✅ **Term immutability** - Invoice terms locked after issuance
✅ **Proper refunds** - Partial payment refunds on cancellation
✅ **Audit trail** - All transitions and payments recorded on-chain

For questions or integration support, see [`README.md`](./README.md) or visit the InvoBase documentation.
