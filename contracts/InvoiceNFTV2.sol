// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./InvoiceNFT.sol";

contract InvoiceNFTV2 is InvoiceNFT {
    uint256 public totalInvoicesCreated;
    
    mapping(address => uint256) public userTotalInvoiced;
    mapping(InvoiceStatus => uint256) public invoicesByStatus;

    event InvoiceStatisticsUpdated(
        address indexed user,
        uint256 totalAmount,
        uint256 invoiceCount
    );

    function version() external pure returns (string memory) {
        return "2.0.0";
    }

    function createInvoice(
        address recipient,
        uint256 amount,
        address paymentToken,
        string memory description,
        uint256 dueDate
    ) external override whenNotPaused nonReentrant returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (recipient == address(0)) revert InvalidRecipient();
        if (dueDate <= block.timestamp) revert InvalidDueDate();

        uint256 tokenId = _nextTokenId++;

        Invoice storage invoice = _invoices[tokenId];
        invoice.id = tokenId;
        invoice.creator = msg.sender;
        invoice.recipient = recipient;
        invoice.amount = amount;
        invoice.paymentToken = paymentToken;
        invoice.description = description;
        invoice.dueDate = dueDate;
        invoice.status = InvoiceStatus.Pending;
        invoice.createdAt = block.timestamp;

        _creatorInvoices[msg.sender].push(tokenId);
        _recipientInvoices[recipient].push(tokenId);

        totalInvoicesCreated++;
        userTotalInvoiced[msg.sender] += amount;
        invoicesByStatus[InvoiceStatus.Pending]++;

        _safeMint(msg.sender, tokenId);

        emit InvoiceCreated(tokenId, msg.sender, recipient, amount, paymentToken);
        emit InvoiceStatisticsUpdated(msg.sender, userTotalInvoiced[msg.sender], _creatorInvoices[msg.sender].length);

        return tokenId;
    }

    function markAsPaid(uint256 tokenId) external override onlyRole(MINTER_ROLE) {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.status != InvoiceStatus.Pending) revert InvoiceNotPending();

        invoicesByStatus[InvoiceStatus.Pending]--;
        invoicesByStatus[InvoiceStatus.Paid]++;

        invoice.status = InvoiceStatus.Paid;
        invoice.paidAt = block.timestamp;

        emit InvoicePaid(tokenId, invoice.recipient, invoice.amount, block.timestamp);
    }

    function cancelInvoice(uint256 tokenId) external override {
        Invoice storage invoice = _invoices[tokenId];
        if (msg.sender != invoice.creator && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        if (invoice.status != InvoiceStatus.Pending) revert InvoiceNotPending();

        invoicesByStatus[InvoiceStatus.Pending]--;
        invoicesByStatus[InvoiceStatus.Cancelled]++;

        invoice.status = InvoiceStatus.Cancelled;

        emit InvoiceCancelled(tokenId, msg.sender);
    }

    function getStatistics() external view returns (
        uint256 total,
        uint256 pending,
        uint256 paid,
        uint256 cancelled
    ) {
        return (
            totalInvoicesCreated,
            invoicesByStatus[InvoiceStatus.Pending],
            invoicesByStatus[InvoiceStatus.Paid],
            invoicesByStatus[InvoiceStatus.Cancelled]
        );
    }

    function getUserStatistics(address user) external view returns (
        uint256 totalAmount,
        uint256 invoiceCount
    ) {
        return (
            userTotalInvoiced[user],
            _creatorInvoices[user].length
        );
    }

    function batchCreateInvoices(
        address[] calldata recipients,
        uint256[] calldata amounts,
        address[] calldata paymentTokens,
        string[] calldata descriptions,
        uint256[] calldata dueDates
    ) external whenNotPaused nonReentrant returns (uint256[] memory) {
        require(
            recipients.length == amounts.length &&
            amounts.length == paymentTokens.length &&
            paymentTokens.length == descriptions.length &&
            descriptions.length == dueDates.length,
            "Array lengths mismatch"
        );

        uint256[] memory tokenIds = new uint256[](recipients.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            if (amounts[i] == 0) revert InvalidAmount();
            if (recipients[i] == address(0)) revert InvalidRecipient();
            if (dueDates[i] <= block.timestamp) revert InvalidDueDate();

            uint256 tokenId = _nextTokenId++;

            Invoice storage invoice = _invoices[tokenId];
            invoice.id = tokenId;
            invoice.creator = msg.sender;
            invoice.recipient = recipients[i];
            invoice.amount = amounts[i];
            invoice.paymentToken = paymentTokens[i];
            invoice.description = descriptions[i];
            invoice.dueDate = dueDates[i];
            invoice.status = InvoiceStatus.Pending;
            invoice.createdAt = block.timestamp;

            _creatorInvoices[msg.sender].push(tokenId);
            _recipientInvoices[recipients[i]].push(tokenId);

            totalInvoicesCreated++;
            userTotalInvoiced[msg.sender] += amounts[i];
            invoicesByStatus[InvoiceStatus.Pending]++;

            _safeMint(msg.sender, tokenId);

            emit InvoiceCreated(tokenId, msg.sender, recipients[i], amounts[i], paymentTokens[i]);
            
            tokenIds[i] = tokenId;
        }

        emit InvoiceStatisticsUpdated(msg.sender, userTotalInvoiced[msg.sender], _creatorInvoices[msg.sender].length);

        return tokenIds;
    }
}
