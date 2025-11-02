// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IInvoiceDisputes
/// @notice Interface for invoice dispute resolution
interface IInvoiceDisputes {
    enum DisputeStatus {
        Open,
        UnderReview,
        Resolved,
        Rejected
    }

    struct Dispute {
        uint256 id;
        uint256 invoiceId;
        address initiator;
        string reason;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
        bool resolved;
    }

    event DisputeCreated(uint256 indexed disputeId, uint256 indexed invoiceId, address indexed initiator);
    event DisputeResolved(uint256 indexed disputeId, bool inFavorOfInitiator);
    event DisputeRejected(uint256 indexed disputeId);

    /// @notice Creates a new dispute for an invoice
    /// @param invoiceId ID of the disputed invoice
    /// @param reason Reason for the dispute
    /// @return disputeId ID of the created dispute
    function createDispute(uint256 invoiceId, string calldata reason)
        external
        returns (uint256 disputeId);

    /// @notice Resolves a dispute
    /// @param disputeId ID of the dispute
    /// @param inFavorOfInitiator Resolution outcome
    /// @param resolution Resolution details
    function resolveDispute(uint256 disputeId, bool inFavorOfInitiator, string calldata resolution)
        external;

    /// @notice Gets dispute details
    /// @param disputeId ID of the dispute
    /// @return Dispute data
    function getDispute(uint256 disputeId) external view returns (Dispute memory);
}
