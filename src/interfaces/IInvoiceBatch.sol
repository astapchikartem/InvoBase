// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IInvoiceBatch
/// @notice Interface for batch invoice operations
interface IInvoiceBatch {
    struct BatchInvoice {
        address payer;
        uint256 amount;
        address asset;
        string metadata;
    }

    /// @notice Creates multiple invoices in a single transaction
    /// @param invoices Array of invoice data
    /// @return invoiceIds Array of created invoice IDs
    function createBatch(BatchInvoice[] calldata invoices)
        external
        returns (uint256[] memory invoiceIds);

    /// @notice Issues multiple invoices in a single transaction
    /// @param ids Array of invoice IDs
    /// @param dueDates Array of due dates
    function issueBatch(uint256[] calldata ids, uint256[] calldata dueDates) external;

    /// @notice Pays multiple invoices in a single transaction
    /// @param ids Array of invoice IDs to pay
    function payBatch(uint256[] calldata ids) external;

    /// @notice Cancels multiple invoices in a single transaction
    /// @param ids Array of invoice IDs to cancel
    function cancelBatch(uint256[] calldata ids) external;
}
