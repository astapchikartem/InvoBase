// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInvoiceManager {
    enum InvoiceStatus {
        Draft,
        Issued,
        Paid,
        Cancelled
    }

    struct Invoice {
        uint256 id;
        address issuer;
        address payer;
        uint256 amount;
        address asset;
        uint256 dueDate;
        InvoiceStatus status;
        string metadata;
        uint256 createdAt;
        uint256 paidAt;
    }

    event InvoiceCreated(
        uint256 indexed id,
        address indexed issuer,
        address indexed payer,
        uint256 amount,
        address asset
    );

    event InvoiceIssued(uint256 indexed id, uint256 dueDate);
    event InvoicePaid(uint256 indexed id, uint256 paidAt);
    event InvoiceCancelled(uint256 indexed id);

    function createInvoice(
        address payer,
        uint256 amount,
        address asset,
        string calldata metadata
    ) external returns (uint256);

    function issueInvoice(uint256 id, uint256 dueDate) external;
    function payInvoice(uint256 id) external;
    function cancelInvoice(uint256 id) external;
    function getInvoice(uint256 id) external view returns (Invoice memory);
}
