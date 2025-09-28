// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IRecurringInvoices
/// @notice Interface for recurring invoice management
interface IRecurringInvoices {
    struct RecurringInvoice {
        uint256 id;
        address issuer;
        address payer;
        uint256 amount;
        address asset;
        uint256 interval;
        uint256 startDate;
        uint256 endDate;
        uint256 executionCount;
        uint256 maxExecutions;
        bool active;
    }

    /// @notice Creates a new recurring invoice
    /// @param payer Address of the payer
    /// @param amount Amount per payment
    /// @param asset Payment token address
    /// @param interval Time between payments
    /// @param maxExecutions Maximum number of payments
    /// @return recurringId ID of the created recurring invoice
    function createRecurring(
        address payer,
        uint256 amount,
        address asset,
        uint256 interval,
        uint256 maxExecutions
    ) external returns (uint256 recurringId);

    /// @notice Executes a payment for a recurring invoice
    /// @param recurringId ID of the recurring invoice
    function executePayment(uint256 recurringId) external;

    /// @notice Cancels a recurring invoice
    /// @param recurringId ID of the recurring invoice
    function cancelRecurring(uint256 recurringId) external;
}
