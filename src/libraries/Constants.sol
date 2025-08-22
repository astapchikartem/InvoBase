// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Constants {
    // Invoice limits
    uint256 constant MAX_INVOICE_AMOUNT = 1_000_000_000 * 1e6;
    uint256 constant MIN_INVOICE_AMOUNT = 1 * 1e6;
    uint256 constant MAX_DUE_DATE_OFFSET = 365 days;
    uint256 constant MIN_DUE_DATE_OFFSET = 1 days;

    // Fee configuration
    uint256 constant DEFAULT_LATE_FEE_PERCENTAGE = 500; // 5% in basis points
    uint256 constant MAX_LATE_FEE_PERCENTAGE = 2000; // 20% max
    uint256 constant PLATFORM_FEE_BPS = 25; // 0.25%

    // Operational limits
    uint256 constant MAX_BATCH_SIZE = 100;
    uint256 constant MAX_METADATA_LENGTH = 1000;
    uint256 constant GAS_BUFFER = 50000;

    // Token addresses - Base network
    address constant USDC_BASE_MAINNET = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant USDC_BASE_SEPOLIA = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
    address constant WETH_BASE_MAINNET = 0x4200000000000000000000000000000000000006;
    address constant WETH_BASE_SEPOLIA = 0x4200000000000000000000000000000000000006;
}
