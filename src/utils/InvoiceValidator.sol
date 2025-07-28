// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title InvoiceValidator
/// @notice Utility functions for validating invoice parameters
library InvoiceValidator {
    error InvalidAmount();
    error InvalidAddress();
    error InvalidDueDate();
    error InvalidMetadata();

    /// @notice Validates invoice amount is greater than zero
    /// @param amount The amount to validate
    function validateAmount(uint256 amount) internal pure {
        if (amount == 0) revert InvalidAmount();
    }

    /// @notice Validates an address is not zero
    /// @param addr The address to validate
    function validateAddress(address addr) internal pure {
        if (addr == address(0)) revert InvalidAddress();
    }

    /// @notice Validates due date is in the future
    /// @param dueDate The due date timestamp to validate
    function validateDueDate(uint256 dueDate) internal view {
        if (dueDate <= block.timestamp) revert InvalidDueDate();
    }

    /// @notice Validates metadata is not empty
    /// @param metadata The metadata string to validate
    function validateMetadata(string calldata metadata) internal pure {
        if (bytes(metadata).length == 0) revert InvalidMetadata();
    }
}
