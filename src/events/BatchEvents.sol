// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title BatchEvents
/// @notice Events for batch operations
library BatchEvents {
    event BatchInvoicesCreated(uint256[] invoiceIds, address indexed issuer);
    event BatchInvoicesIssued(uint256[] invoiceIds, address indexed issuer);
    event BatchInvoicesPaid(uint256[] invoiceIds, address indexed payer, uint256 totalAmount);
    event BatchInvoicesCancelled(uint256[] invoiceIds, address indexed issuer);
}
