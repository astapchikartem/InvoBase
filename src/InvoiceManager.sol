// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IInvoiceManager} from "./interfaces/IInvoiceManager.sol";

contract InvoiceManager is
    IInvoiceManager,
    UUPSUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    mapping(uint256 => Invoice) private invoices;
    uint256 private nextInvoiceId;

    error UnauthorizedAccess();
    error InvalidStatus();
    error InvoiceExpired();
    error InvalidAmount();
    error InvalidAddress();
    error InvalidDueDate();

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        nextInvoiceId = 1;
    }

    function createInvoice(
        address payer,
        uint256 amount,
        address asset,
        string calldata metadata
    ) external override returns (uint256) {
        if (amount == 0) revert InvalidAmount();
        if (payer == address(0) || asset == address(0)) revert InvalidAddress();

        uint256 invoiceId = nextInvoiceId++;

        invoices[invoiceId] = Invoice({
            id: invoiceId,
            issuer: msg.sender,
            payer: payer,
            amount: amount,
            asset: asset,
            dueDate: 0,
            status: InvoiceStatus.Draft,
            metadata: metadata,
            createdAt: block.timestamp,
            paidAt: 0
        });

        emit InvoiceCreated(invoiceId, msg.sender, payer, amount, asset);

        return invoiceId;
    }

    function issueInvoice(uint256 id, uint256 dueDate) external override {
        Invoice storage invoice = invoices[id];

        if (invoice.issuer != msg.sender) revert UnauthorizedAccess();
        if (invoice.status != InvoiceStatus.Draft) revert InvalidStatus();
        if (dueDate <= block.timestamp) revert InvalidDueDate();

        invoice.status = InvoiceStatus.Issued;
        invoice.dueDate = dueDate;

        emit InvoiceIssued(id, dueDate);
    }

    function payInvoice(uint256 id) external override nonReentrant {
        Invoice storage invoice = invoices[id];

        if (msg.sender != invoice.payer) revert UnauthorizedAccess();
        if (invoice.status != InvoiceStatus.Issued) revert InvalidStatus();

        invoice.status = InvoiceStatus.Paid;
        invoice.paidAt = block.timestamp;

        IERC20(invoice.asset).safeTransferFrom(
            msg.sender,
            invoice.issuer,
            invoice.amount
        );

        emit InvoicePaid(id, block.timestamp);
    }

    function cancelInvoice(uint256 id) external override {
        Invoice storage invoice = invoices[id];

        if (invoice.issuer != msg.sender) revert UnauthorizedAccess();
        if (invoice.status == InvoiceStatus.Paid) revert InvalidStatus();

        invoice.status = InvoiceStatus.Cancelled;

        emit InvoiceCancelled(id);
    }

    function getInvoice(uint256 id) external view override returns (Invoice memory) {
        return invoices[id];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
