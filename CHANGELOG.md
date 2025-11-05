# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Core invoice management functionality
- UUPS upgradeable proxy pattern
- NFT receipt minting on payment
- Batch operations support
- Recurring invoice support
- Dispute resolution system
- Comprehensive test suite with fuzz testing
- Integration tests for full workflow
- Gas optimization utilities
- Deployment and upgrade scripts
- Detailed documentation (API, Architecture, Deployment, Security)
- CI/CD with GitHub Actions
- Solhint and Prettier configurations

### Changed
- Optimized compiler settings for production
- Expanded constants library with additional configuration
- Enhanced README with testing commands

### Fixed
- Removed expiry check to allow late payments
- Added proper validation for all inputs
- Fixed reentrancy protection on payment functions

### Security
- Reentrancy guards on all state-changing functions
- Access control on sensitive operations
- Input validation across all contracts
- Comprehensive security testing

## [1.0.0] - Initial Release

### Added
- Initial project structure
- Basic invoice creation and payment
- OpenZeppelin integration
- Foundry setup
