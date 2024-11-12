# Proxy Architecture Explained

## Understanding UUPS Proxies

InvoBase uses **UUPS (Universal Upgradeable Proxy Standard)** pattern for all smart contracts.

### How Many Contracts per Proxy?

**Simple Answer**: 1 Proxy = 1 Implementation Contract (at a time)

```
┌─────────────────────────────┐
│    Proxy Contract           │  ← Permanent address (never changes)
│    Address: 0xABCD...       │
└──────────┬──────────────────┘
           │ delegatecall
           ▼
┌─────────────────────────────┐
│  Implementation V1          │  ← Can be upgraded
│  Address: 0x1234...         │
└─────────────────────────────┘
           │ upgrade
           ▼
┌─────────────────────────────┐
│  Implementation V2          │  ← New version
│  Address: 0x5678...         │
└─────────────────────────────┘
```

### InvoBase Architecture

We have **2 separate proxy contracts**:

```
1. InvoiceNFT Proxy (0xAAAA...)
   └─→ InvoiceNFT Implementation V1 (0x1111...)
       Can upgrade to →
       └─→ InvoiceNFT Implementation V2 (0x2222...)

2. PaymentProcessor Proxy (0xBBBB...)
   └─→ PaymentProcessor Implementation V1 (0x3333...)
       Can upgrade to →
       └─→ PaymentProcessor Implementation V2 (0x4444...)
```

## How Proxy Works

### 1. User Interaction

```solidity
// User calls proxy address
invoiceNFT.createInvoice(...)
   ↓
Proxy (0xABCD...)
   ↓ delegatecall
Implementation V1 (0x1234...)
   ↓ executes with proxy's storage
Result returned to user
```

### 2. Storage Location

**Critical**: Storage lives in **Proxy**, not Implementation

```
Proxy Contract
├─ Storage Slot 0: _nextTokenId
├─ Storage Slot 1: _invoices mapping
├─ Storage Slot 2: _creatorInvoices mapping
└─ ...

Implementation Contract
└─ Only logic (functions), NO storage data
```

### 3. Upgrade Process

```
Step 1: Deploy new implementation
┌─────────────────────┐
│ InvoiceNFTV2.sol    │
│ (new logic)         │
└─────────────────────┘
          │ deploy
          ▼
┌─────────────────────┐
│ 0x5678... (V2)      │
└─────────────────────┘

Step 2: Upgrade proxy
┌─────────────────────┐
│ Proxy 0xABCD...     │
│ (same address!)     │
└──────┬──────────────┘
       │ now points to
       ▼
┌─────────────────────┐
│ 0x5678... (V2)      │
└─────────────────────┘

Step 3: Users call same address
User → 0xABCD... → delegatecall → 0x5678... (V2 logic)
```

## Why Multiple Proxies?

### Separation of Concerns

Each contract has its own proxy because:

1. **Different Logic**: InvoiceNFT handles NFTs, PaymentProcessor handles payments
2. **Independent Upgrades**: Upgrade one without affecting the other
3. **Clear Responsibilities**: Each proxy manages its own storage
4. **Security**: Isolated upgrade permissions

### Could We Use One Proxy?

**Technically yes**, but it's a **bad practice**:

```
❌ BAD: One proxy for everything
┌─────────────────────────────┐
│   Monolithic Proxy          │
│   (all logic in one)        │
└─────────────────────────────┘
Problems:
- Huge contract (gas limits)
- Can't upgrade parts independently
- Complex storage layout
- Higher risk of bugs
```

```
✅ GOOD: Separate proxies
┌──────────────┐  ┌──────────────┐
│ Invoice NFT  │  │  Payment     │
│   Proxy      │  │  Processor   │
└──────────────┘  └──────────────┘
Benefits:
- Modular upgrades
- Clear separation
- Lower complexity
- Easier auditing
```

## Upgrade Mechanics

### V1 to V2 Upgrade

**What Changes**:
```solidity
// V1
contract InvoiceNFT {
    uint256 private _nextTokenId;
    mapping(uint256 => Invoice) private _invoices;
    
    function createInvoice(...) external { }
}

// V2 (adds new features)
contract InvoiceNFTV2 is InvoiceNFT {
    // ✅ Add new storage variables
    uint256 public totalInvoicesCreated;
    mapping(address => uint256) public userStats;
    
    // ✅ Override existing functions
    function createInvoice(...) external override { }
    
    // ✅ Add new functions
    function getStatistics() external view { }
}
```

**What Stays Same**:
- Proxy address (0xABCD...)
- Existing storage data
- User balances/NFTs
- Access control roles

### Storage Safety

**Critical Rules**:
1. ✅ **Can ADD** new variables at the end
2. ❌ **Cannot REMOVE** old variables
3. ❌ **Cannot CHANGE** variable order
4. ❌ **Cannot CHANGE** variable types

```solidity
// ✅ SAFE
contract V1 {
    uint256 a;
    uint256 b;
}

contract V2 is V1 {
    uint256 c;  // Added at end
}

// ❌ UNSAFE
contract V2Bad is V1 {
    uint256 c;
    uint256 a;  // Changed order!
    uint256 b;
}
```

## Upgrade Authorization

### Who Can Upgrade?

Only accounts with `UPGRADER_ROLE`:

```solidity
function _authorizeUpgrade(address newImplementation) 
    internal 
    override 
    onlyRole(UPGRADER_ROLE) 
{
    // Only UPGRADER_ROLE can call
}
```

### Current Setup

**Initial Deployment**:
- Deployer has all roles
- Deployer can upgrade contracts

**Production Best Practice**:
```
1. Transfer UPGRADER_ROLE to multi-sig wallet
2. Require multiple approvals for upgrades
3. Add timelock (24-48 hours delay)
4. Community governance for major changes
```

## Testing Upgrades

### Before Upgrade

```bash
# 1. Deploy V1
yarn deploy:sepolia

# 2. Create test data (invoices, payments)
# ...

# 3. Compile V2
yarn compile

# 4. Run upgrade tests
yarn test test/Upgrade.test.js

# 5. Upgrade
yarn upgrade:sepolia
```

### Verify After Upgrade

```javascript
// 1. Check version
const version = await contract.version();
console.log(version); // "2.0.0"

// 2. Check old data still exists
const invoice = await contract.getInvoice(1);
console.log(invoice); // Old invoice intact

// 3. Test new features
const stats = await contract.getStatistics();
console.log(stats); // New feature works
```

## Common Questions

### Q: Can I call multiple implementations?
**A**: No. Proxy points to ONE implementation at a time.

### Q: What happens to old implementation?
**A**: Still exists on blockchain, but proxy no longer uses it.

### Q: Can I rollback an upgrade?
**A**: Yes! Upgrade proxy back to old implementation address.

### Q: Do users need to do anything?
**A**: No! They keep using same proxy address.

### Q: Is upgrade instant?
**A**: Yes, takes effect in single transaction.

### Q: Can I upgrade during active use?
**A**: Technically yes, but best to pause first.

## Upgrade Strategies

### Strategy 1: Direct Upgrade
```
V1 → V2 (immediate)
```
**Pros**: Fast
**Cons**: Risky if bugs

### Strategy 2: Testnet First
```
Testnet: V1 → V2 (test for days/weeks)
Mainnet: V1 → V2 (after verification)
```
**Pros**: Safer
**Cons**: Takes time

### Strategy 3: Gradual Rollout
```
1. Deploy V2 alongside V1
2. Migrate users gradually
3. Deprecate V1 after full migration
```
**Pros**: Safest
**Cons**: Complex

## Security Considerations

### 1. Storage Collision
```solidity
// ❌ BAD: Direct storage in V2
contract V2 {
    uint256 newVar = 123;  // Could collide!
}

// ✅ GOOD: Proper inheritance
contract V2 is V1 {
    uint256 newVar;  // Safe, after V1 vars
}
```

### 2. Delegatecall Security
- Implementation can't selfdestruct
- Implementation can't use constructor
- Use initializers instead

### 3. Upgrade Protection
```solidity
/// @custom:oz-upgrades-unsafe-allow constructor
constructor() {
    _disableInitializers();  // Prevent init on implementation
}
```

## Gas Costs

### Proxy Call Overhead
- Additional ~2,000 gas per call
- Worth it for upgradability
- Users pay same address forever

### Upgrade Costs
```
Operation                 Gas Cost
Deploy V2 Implementation  ~2M gas
Upgrade Proxy            ~30K gas
Total                    ~2.03M gas
```

On Base (low fees): ~$0.40 total

## References

- [OpenZeppelin Proxy Docs](https://docs.openzeppelin.com/contracts/4.x/api/proxy)
- [EIP-1822: UUPS](https://eips.ethereum.org/EIPS/eip-1822)
- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)
