// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IInvoicePaymentForLink {
    function payInvoice(uint256 invoiceId) external payable;
    function payInvoiceToken(uint256 invoiceId, address token, uint256 amount) external;
}

interface IInvoiceNFTForLink {
    struct Invoice {
        address issuer;
        address payer;
        uint256 amount;
        uint256 dueDate;
        uint8 status;
        uint256 createdAt;
    }

    function getInvoice(uint256 tokenId) external view returns (Invoice memory);
}

contract PaymentLink is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct PaymentLink {
        uint256 invoiceId;
        bytes32 linkId;
        uint256 expiry;
        bool used;
    }

    IInvoicePaymentForLink public paymentProcessor;
    IInvoiceNFTForLink public invoiceNFT;

    mapping(bytes32 => PaymentLink) public links;
    mapping(uint256 => bytes32) public invoiceToLink;
    uint256 private _nonce;

    event LinkGenerated(
        uint256 indexed invoiceId,
        bytes32 indexed linkId,
        uint256 expiry
    );

    event LinkPaymentReceived(
        bytes32 indexed linkId,
        uint256 indexed invoiceId,
        address indexed payer,
        uint256 amount
    );

    event LinkPaymentWithTokenReceived(
        bytes32 indexed linkId,
        uint256 indexed invoiceId,
        address indexed payer,
        address token,
        uint256 amount
    );

    error LinkExpired();
    error LinkAlreadyUsed();
    error LinkNotFound();
    error InsufficientPayment();
    error Unauthorized();

    constructor(
        address _paymentProcessor,
        address _invoiceNFT,
        address initialOwner
    ) Ownable(initialOwner) {
        paymentProcessor = IInvoicePaymentForLink(_paymentProcessor);
        invoiceNFT = IInvoiceNFTForLink(_invoiceNFT);
    }

    function generateLink(
        uint256 invoiceId,
        uint256 expiry
    ) external returns (bytes32 linkId) {
        IInvoiceNFTForLink.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);
        if (invoice.issuer != msg.sender) revert Unauthorized();

        linkId = keccak256(abi.encodePacked(invoiceId, msg.sender, block.timestamp, _nonce++));

        links[linkId] = PaymentLink({
            invoiceId: invoiceId,
            linkId: linkId,
            expiry: expiry,
            used: false
        });

        invoiceToLink[invoiceId] = linkId;

        emit LinkGenerated(invoiceId, linkId, expiry);

        return linkId;
    }

    function payViaLink(bytes32 linkId) external payable nonReentrant {
        PaymentLink storage link = links[linkId];

        if (link.linkId == bytes32(0)) revert LinkNotFound();
        if (link.used) revert LinkAlreadyUsed();
        if (block.timestamp > link.expiry) revert LinkExpired();

        IInvoiceNFTForLink.Invoice memory invoice = invoiceNFT.getInvoice(link.invoiceId);
        if (msg.value < invoice.amount) revert InsufficientPayment();

        link.used = true;

        paymentProcessor.payInvoice{value: msg.value}(link.invoiceId);

        emit LinkPaymentReceived(linkId, link.invoiceId, msg.sender, msg.value);
    }

    function payViaLinkToken(
        bytes32 linkId,
        address token,
        uint256 amount
    ) external nonReentrant {
        PaymentLink storage link = links[linkId];

        if (link.linkId == bytes32(0)) revert LinkNotFound();
        if (link.used) revert LinkAlreadyUsed();
        if (block.timestamp > link.expiry) revert LinkExpired();

        IInvoiceNFTForLink.Invoice memory invoice = invoiceNFT.getInvoice(link.invoiceId);
        if (amount < invoice.amount) revert InsufficientPayment();

        link.used = true;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(address(paymentProcessor), amount);

        paymentProcessor.payInvoiceToken(link.invoiceId, token, amount);

        emit LinkPaymentWithTokenReceived(linkId, link.invoiceId, msg.sender, token, amount);
    }

    function isLinkValid(bytes32 linkId) external view returns (bool) {
        PaymentLink memory link = links[linkId];

        if (link.linkId == bytes32(0)) return false;
        if (link.used) return false;
        if (block.timestamp > link.expiry) return false;

        return true;
    }

    function getLink(bytes32 linkId) external view returns (PaymentLink memory) {
        return links[linkId];
    }

    function getLinkByInvoice(uint256 invoiceId) external view returns (PaymentLink memory) {
        bytes32 linkId = invoiceToLink[invoiceId];
        return links[linkId];
    }

    receive() external payable {}
}
