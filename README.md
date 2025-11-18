# InvoBase

On-chain invoicing engine built for Base network. Create, track, and settle invoices using upgradeable smart contracts and USDC payments.

## Features

- Structured invoice creation with issuer, payer, amount, and metadata
- State machine workflow: Draft → Issued → Paid → Cancelled
- Role-based access control for invoice management
- Base Pay integration for seamless USDC settlements
- Upgradeable architecture with UUPS proxy pattern
- NFT/SBT invoice receipts

## Tech Stack

- Solidity 0.8.24
- Foundry
- OpenZeppelin Upgradeable Contracts
- Base L2

## Setup

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test

# Run tests with gas report
forge test --gas-report

# Generate coverage report
forge coverage
```

## Deployment

Requires environment variables:
- `BASE_SEPOLIA_RPC`
- `BASE_MAINNET_RPC`
- `BASESCAN_API_KEY`
- `DEPLOYER_PRIVATE_KEY`

## Security

This project undergoes automated security scanning with Slither and Mythril. For security concerns, please contact the maintainers.

## Contributing

Contributions are welcome! Please ensure all tests pass and follow the coding standards.

## License

MIT
