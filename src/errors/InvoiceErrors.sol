// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title InvoiceErrors
/// @notice Centralized error definitions for the invoice system
library InvoiceErrors {
    error UnauthorizedAccess();
    error InvalidStatus();
    error InvoiceExpired();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidDueDate();
    error InvoiceNotFound();
    error PaymentFailed();
    error InsufficientBalance();
    error ZeroAmount();
}
