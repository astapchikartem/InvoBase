# InvoBase Architecture

## System Overview

InvoBase is a decentralized NFT-based invoicing system built on Base L2. The architecture follows modern Web3 patterns with upgradeable smart contracts, comprehensive access control, and seamless Base Pay integration.

## Smart Contract Architecture

### Contract Hierarchy

```
┌─────────────────────────────────────┐
│         ERC1967 Proxy               │
│    (Upgradeable Proxy Pattern)      │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│       InvoiceNFT (ERC-721)          │
│  - Invoice Creation & Management    │
│  - NFT Minting & Ownership          │
│  - Status Tracking                  │
└──────────────┬──────────────────────┘
               │
               │ References
               │
               ▼
┌─────────────────────────────────────┐
│      PaymentProcessor               │
│  - Payment Processing               │
│  - Multi-token Support              │
│  - Fee Collection                   │
│  - Base Pay Integration             │
└─────────────────────────────────────┘
```

### InvoiceNFT Contract

**Purpose**: Manages invoice lifecycle as ERC-721 NFTs

**Key Features**:
- ERC-721 compliant invoice NFTs
- UUPS upgradeable pattern
- Role-based access control
- Pausable for emergency stops
- Reentrancy protection

**Storage Layout**:
```solidity
struct Invoice {
    uint256 id;           // Unique invoice ID
    address creator;      // Invoice creator
    address recipient;    // Payment recipient  
    uint256 amount;       // Invoice amount
    address paymentToken; // Payment token (address(0) for ETH)
    string description;   // Invoice details
    uint256 dueDate;      // Payment deadline
    InvoiceStatus status; // Current status
    uint256 createdAt;    // Creation timestamp
    uint256 paidAt;       // Payment timestamp
}

enum InvoiceStatus {
    Pending,   // Awaiting payment
    Paid,      // Payment completed
    Cancelled, // Cancelled by creator
    Overdue    // Past due date
}
```

**Access Control Roles**:
- `DEFAULT_ADMIN_ROLE`: Full administrative access
- `MINTER_ROLE`: Can mark invoices as paid
- `UPGRADER_ROLE`: Can upgrade contract implementation
- `PAUSER_ROLE`: Can pause/unpause contract

### PaymentProcessor Contract

**Purpose**: Handles invoice payments with fee collection

**Key Features**:
- Multi-token payment support (ETH, ERC-20)
- Platform fee mechanism (0.25% default)
- Reentrancy guards
- UUPS upgradeable
- Base Pay integration ready

**Payment Flow**:
```
User Payment → PaymentProcessor
    ├─→ Platform Fee (0.25%) → Fee Collector
    ├─→ Payment Amount (99.75%) → Invoice Recipient
    └─→ Mark Invoice as Paid → InvoiceNFT
```

**Supported Tokens**:
- ETH (native)
- USDC, USDT, DAI (ERC-20)
- Any ERC-20 token approved by admin

## Upgrade Mechanism

### UUPS Pattern

InvoBase uses OpenZeppelin's UUPS (Universal Upgradeable Proxy Standard) for contract upgrades:

**Advantages**:
- Lower deployment costs (logic in implementation)
- Reduced attack surface (no proxy admin)
- Granular access control
- Gas-efficient upgrades

**Upgrade Process**:
1. Deploy new implementation contract
2. Call `upgradeToAndCall()` with UPGRADER_ROLE
3. Proxy automatically delegates to new implementation
4. Storage layout preserved

**Safety Mechanisms**:
- Storage layout validation
- Initializer guards
- Access control on upgrades
- Storage gap for future variables

## Security Features

### 1. Access Control
- Role-based permissions (OpenZeppelin AccessControl)
- Multi-signature wallet recommended for production
- Separate roles for different operations

### 2. Reentrancy Protection
- ReentrancyGuard on all payment functions
- Checks-effects-interactions pattern
- State updates before external calls

### 3. Pausability
- Emergency pause mechanism
- Restricted to PAUSER_ROLE
- Prevents operations during incidents

### 4. Input Validation
- Custom errors for gas efficiency
- Comprehensive parameter checks
- Zero-address validations

### 5. Safe Math
- Solidity 0.8.24 (built-in overflow checks)
- Explicit arithmetic for fee calculations

## Data Flow

### Invoice Creation
```
User → InvoiceNFT.createInvoice()
    ├─→ Validate inputs
    ├─→ Create Invoice struct
    ├─→ Mint NFT to creator
    ├─→ Store in mappings
    └─→ Emit InvoiceCreated event
```

### Payment Processing
```
Payer → PaymentProcessor.processPayment()
    ├─→ Validate invoice exists & unpaid
    ├─→ Check token support
    ├─→ Calculate fees
    ├─→ Transfer tokens
    │   ├─→ To recipient (99.75%)
    │   └─→ To fee collector (0.25%)
    ├─→ Mark invoice as paid
    └─→ Emit PaymentProcessed event
```

## Integration Points

### Base Ecosystem

1. **Base Pay**: Payment processing integration
2. **Basescan**: Contract verification and monitoring
3. **Base RPC**: Network connectivity
4. **Coinbase Wallet**: Primary wallet integration

### Frontend Integration

```javascript
// Web3 Setup
import { createPublicClient, createWalletClient } from 'viem'
import { base, baseSepolia } from 'viem/chains'

// Contract Interaction
const invoiceNFT = getContract({
  address: INVOICE_NFT_ADDRESS,
  abi: InvoiceNFTABI,
  walletClient
})

// Create Invoice
const hash = await invoiceNFT.write.createInvoice([
  recipient,
  amount,
  paymentToken,
  description,
  dueDate
])
```

## Event Architecture

### Critical Events

**InvoiceNFT**:
- `InvoiceCreated(tokenId, creator, recipient, amount, token)`
- `InvoicePaid(tokenId, payer, amount, paidAt)`
- `InvoiceCancelled(tokenId, canceller)`

**PaymentProcessor**:
- `PaymentProcessed(invoiceId, payer, token, amount, fee)`
- `TokenSupportUpdated(token, supported)`
- `FeeUpdated(newFee)`

### Event Indexing

Events are indexed for:
- Invoice tracking
- Payment history
- Analytics dashboard
- User activity feeds

## Gas Optimization

1. **Storage Packing**: Struct fields ordered by size
2. **Custom Errors**: More gas-efficient than strings
3. **Batch Operations**: Support for multiple invoices
4. **Mapping Usage**: O(1) lookups instead of arrays
5. **UUPS Pattern**: Lower deployment costs

## Future Enhancements

### Planned Features
- [ ] Recurring invoices
- [ ] Partial payments
- [ ] Invoice templates
- [ ] Multi-currency conversion (via Uniswap)
- [ ] Invoice factoring/selling
- [ ] Escrow mechanism
- [ ] Dispute resolution

### Scalability
- Layer 2 (Base) provides low fees and high throughput
- Can support thousands of invoices daily
- Optimized for batch operations

## Testing Strategy

### Unit Tests
- Individual function testing
- Edge case coverage
- Error condition validation

### Integration Tests
- End-to-end workflows
- Multi-contract interactions
- Payment scenarios

### Security Tests
- Reentrancy attempts
- Access control bypass
- Integer overflow/underflow
- Front-running scenarios

## Deployment Strategy

1. **Testnet Deployment**: Base Sepolia for testing
2. **Security Audit**: Third-party review
3. **Mainnet Deployment**: Base Mainnet production
4. **Monitoring**: Real-time event tracking
5. **Gradual Rollout**: Phased feature activation

## Monitoring & Maintenance

### On-chain Monitoring
- Contract events via Basescan
- Transaction success rates
- Gas usage patterns
- Error frequencies

### Off-chain Monitoring
- Frontend uptime
- RPC endpoint health
- Database sync status
- User activity metrics

## References

- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Base Documentation](https://docs.base.org/)
- [ERC-721 Standard](https://eips.ethereum.org/EIPS/eip-721)
- [UUPS Proxy Pattern](https://eips.ethereum.org/EIPS/eip-1822)
