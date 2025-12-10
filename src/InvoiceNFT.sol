// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract InvoiceNFT is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    enum InvoiceStatus {
        Draft,
        Issued,
        Paid,
        Cancelled
    }

    struct Invoice {
        address issuer;
        address payer;
        uint256 amount;
        uint256 dueDate;
        InvoiceStatus status;
        uint256 createdAt;
    }

    mapping(uint256 => Invoice) private _invoices;
    uint256 private _nextTokenId;

    event InvoiceMinted(uint256 indexed tokenId, address indexed issuer, address indexed payer, uint256 amount);
    event StatusChanged(uint256 indexed tokenId, InvoiceStatus oldStatus, InvoiceStatus newStatus);

    error UnauthorizedTransfer();
    error InvalidStatus();
    error Unauthorized();

    function initialize(address initialOwner) public initializer {
        __ERC721_init("InvoBase Invoice", "INVO");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _nextTokenId = 1;
        if (initialOwner != msg.sender) {
            transferOwnership(initialOwner);
        }
    }

    function mint(address payer, uint256 amount, uint256 dueDate) external returns (uint256) {
        uint256 tokenId = _nextTokenId++;

        _invoices[tokenId] = Invoice({
            issuer: msg.sender,
            payer: payer,
            amount: amount,
            dueDate: dueDate,
            status: InvoiceStatus.Draft,
            createdAt: block.timestamp
        });

        _mint(msg.sender, tokenId);

        emit InvoiceMinted(tokenId, msg.sender, payer, amount);

        return tokenId;
    }

    function issue(uint256 tokenId) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (invoice.status != InvoiceStatus.Draft) revert InvalidStatus();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Issued;

        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Issued);
    }

    function markPaid(uint256 tokenId) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender && invoice.payer != msg.sender) revert Unauthorized();
        if (invoice.status != InvoiceStatus.Issued) revert InvalidStatus();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Paid;

        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Paid);
    }

    function cancel(uint256 tokenId) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (invoice.status == InvoiceStatus.Paid) revert InvalidStatus();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Cancelled;

        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Cancelled);
    }

    function getInvoice(uint256 tokenId) external view returns (Invoice memory) {
        return _invoices[tokenId];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        revert UnauthorizedTransfer();
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        revert UnauthorizedTransfer();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
