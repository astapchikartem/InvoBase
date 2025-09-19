# InvoiceBase API Documentation

## Core Contracts

### InvoiceManager

Main contract for managing invoices.

#### Functions

**createInvoice**
```solidity
function createInvoice(
    address payer,
    uint256 amount,
    address asset,
    string calldata metadata
) external returns (uint256 invoiceId)
```
Creates a new draft invoice.

**issueInvoice**
```solidity
function issueInvoice(uint256 id, uint256 dueDate) external
```
Issues a draft invoice with a due date.

**payInvoice**
```solidity
function payInvoice(uint256 id) external
```
Pays an issued invoice.

**cancelInvoice**
```solidity
function cancelInvoice(uint256 id) external
```
Cancels an unpaid invoice.

**getInvoice**
```solidity
function getInvoice(uint256 id) external view returns (Invoice memory)
```
Gets invoice details.

### InvoiceNFT

NFT receipt contract for paid invoices.

#### Functions

**mint**
```solidity
function mint(
    address to,
    uint256 tokenId,
    uint256 invoiceId,
    address issuer,
    uint256 amount,
    uint256 paidAt
) external
```
Mints a new receipt NFT (only callable by InvoiceManager).

## Events

### InvoiceCreated
```solidity
event InvoiceCreated(
    uint256 indexed id,
    address indexed issuer,
    address indexed payer,
    uint256 amount,
    address asset
)
```

### InvoiceIssued
```solidity
event InvoiceIssued(uint256 indexed id, uint256 dueDate)
```

### InvoicePaid
```solidity
event InvoicePaid(uint256 indexed id, uint256 paidAt)
```

### InvoiceCancelled
```solidity
event InvoiceCancelled(uint256 indexed id)
```

## Error Codes

- `UnauthorizedAccess()`: Caller not authorized
- `InvalidStatus()`: Invalid invoice status for operation
- `InvoiceExpired()`: Invoice past due date
- `InvalidAmount()`: Amount is zero or invalid
- `InvalidAddress()`: Address is zero
- `InvalidDueDate()`: Due date is in the past
