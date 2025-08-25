# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in InvoiceBase, please follow these steps:

1. **Do Not** disclose the vulnerability publicly
2. Email security details to: security@invoicebase.io
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

We will respond within 48 hours and work with you to address the issue.

## Security Best Practices

- All contracts use OpenZeppelin's audited libraries
- Reentrancy protection on all state-changing functions
- Access control enforced on sensitive operations
- Input validation on all external calls
- Gas optimization without sacrificing security

## Bug Bounty

We offer rewards for responsibly disclosed security issues. Contact us for details.
