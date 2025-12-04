// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IInvoiceNFT {
    struct Invoice {
        address issuer;
        address payer;
        uint256 amount;
        uint256 dueDate;
        uint8 status;
        uint256 createdAt;
    }

    function getInvoice(uint256 tokenId) external view returns (Invoice memory);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract InvoicePayment is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    struct PaymentInfo {
        uint256 invoiceId;
        address token;
        uint256 amountPaid;
        uint256 paidAt;
        address paidBy;
        bytes32 paymentRef;
    }

    IInvoiceNFT public invoiceNFT;

    mapping(uint256 => PaymentInfo) public payments;
    mapping(uint256 => bool) public acceptsPartial;
    mapping(uint256 => uint256) public partialPaid;
    mapping(address => bool) public supportedTokens;

    event InvoicePaymentReceived(
        uint256 indexed invoiceId,
        address indexed payer,
        address token,
        uint256 amount
    );

    event PartialPaymentReceived(
        uint256 indexed invoiceId,
        address indexed payer,
        uint256 amount,
        uint256 remaining
    );

    event PaymentRefunded(
        uint256 indexed invoiceId,
        address indexed recipient,
        uint256 amount
    );

    event ExternalPaymentRecorded(
        uint256 indexed invoiceId,
        bytes32 indexed paymentRef,
        uint256 amount
    );

    event PaymentReleased(
        uint256 indexed invoiceId,
        address indexed recipient,
        uint256 amount
    );

    event TokenSupportChanged(
        address indexed token,
        bool supported
    );

    error InvoiceNotFound();
    error InvoiceAlreadyPaid();
    error InvoiceCancelled();
    error InsufficientPayment();
    error PartialPaymentNotAllowed();
    error TokenNotSupported();
    error RefundFailed();
    error Unauthorized();
    error InvalidPaymentRef();
    error NoPaymentToRelease();
    error InvalidStatus();

    constructor(address _invoiceNFT, address initialOwner) Ownable(initialOwner) {
        invoiceNFT = IInvoiceNFT(_invoiceNFT);
    }

    function setSupportedToken(address token, bool supported) external onlyOwner {
        supportedTokens[token] = supported;
        emit TokenSupportChanged(token, supported);
    }

    function setPartialPaymentAllowed(uint256 invoiceId, bool allowed) external {
        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);
        if (invoice.issuer != msg.sender) revert Unauthorized();
        acceptsPartial[invoiceId] = allowed;
    }

    function payInvoice(uint256 invoiceId) external payable nonReentrant {
        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.amount == 0) revert InvoiceNotFound();
        if (invoice.status == 2) revert InvoiceAlreadyPaid();
        if (invoice.status == 3) revert InvoiceCancelled();
        if (msg.value < invoice.amount) revert InsufficientPayment();

        payments[invoiceId] = PaymentInfo({
            invoiceId: invoiceId,
            token: address(0),
            amountPaid: msg.value,
            paidAt: block.timestamp,
            paidBy: msg.sender,
            paymentRef: bytes32(0)
        });

        emit InvoicePaymentReceived(invoiceId, msg.sender, address(0), msg.value);
    }

    function payInvoiceToken(
        uint256 invoiceId,
        address token,
        uint256 amount
    ) external nonReentrant {
        if (!supportedTokens[token]) revert TokenNotSupported();

        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.amount == 0) revert InvoiceNotFound();
        if (invoice.status == 2) revert InvoiceAlreadyPaid();
        if (invoice.status == 3) revert InvoiceCancelled();
        if (amount < invoice.amount) revert InsufficientPayment();

        payments[invoiceId] = PaymentInfo({
            invoiceId: invoiceId,
            token: token,
            amountPaid: amount,
            paidAt: block.timestamp,
            paidBy: msg.sender,
            paymentRef: bytes32(0)
        });

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        emit InvoicePaymentReceived(invoiceId, msg.sender, token, amount);
    }

    function payInvoicePartial(
        uint256 invoiceId,
        uint256 amount
    ) external payable nonReentrant {
        if (!acceptsPartial[invoiceId]) revert PartialPaymentNotAllowed();

        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.amount == 0) revert InvoiceNotFound();
        if (invoice.status == 2) revert InvoiceAlreadyPaid();
        if (invoice.status == 3) revert InvoiceCancelled();

        uint256 paymentAmount = msg.value > 0 ? msg.value : amount;
        uint256 totalPaid = partialPaid[invoiceId] + paymentAmount;

        if (totalPaid > invoice.amount) revert InsufficientPayment();

        partialPaid[invoiceId] = totalPaid;
        uint256 remaining = invoice.amount - totalPaid;

        if (msg.value > 0) {
            // ETH payment - held in contract
        } else {
            address token = payments[invoiceId].token;
            if (token == address(0)) revert TokenNotSupported();
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        }

        if (remaining == 0) {
            payments[invoiceId] = PaymentInfo({
                invoiceId: invoiceId,
                token: msg.value > 0 ? address(0) : payments[invoiceId].token,
                amountPaid: totalPaid,
                paidAt: block.timestamp,
                paidBy: msg.sender,
                paymentRef: bytes32(0)
            });

            emit InvoicePaymentReceived(
                invoiceId,
                msg.sender,
                msg.value > 0 ? address(0) : payments[invoiceId].token,
                totalPaid
            );
        } else {
            emit PartialPaymentReceived(invoiceId, msg.sender, paymentAmount, remaining);
        }
    }

    function recordExternalPayment(
        uint256 invoiceId,
        bytes32 paymentRef
    ) external {
        if (paymentRef == bytes32(0)) revert InvalidPaymentRef();

        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (invoice.amount == 0) revert InvoiceNotFound();
        if (invoice.status == 2) revert InvoiceAlreadyPaid();
        if (invoice.status == 3) revert InvoiceCancelled();

        payments[invoiceId] = PaymentInfo({
            invoiceId: invoiceId,
            token: address(0),
            amountPaid: invoice.amount,
            paidAt: block.timestamp,
            paidBy: invoice.payer,
            paymentRef: paymentRef
        });

        emit ExternalPaymentRecorded(invoiceId, paymentRef, invoice.amount);
    }

    function releasePayment(uint256 invoiceId) external nonReentrant {
        PaymentInfo memory payment = payments[invoiceId];
        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (payment.amountPaid == 0) revert NoPaymentToRelease();
        if (invoice.status != 2) revert InvalidStatus();

        uint256 releaseAmount = payment.amountPaid;

        if (payment.token == address(0)) {
            (bool success, ) = payable(invoice.issuer).call{value: releaseAmount}("");
            if (!success) revert RefundFailed();
        } else {
            IERC20(payment.token).safeTransfer(invoice.issuer, releaseAmount);
        }

        emit PaymentReleased(invoiceId, invoice.issuer, releaseAmount);
    }

    function refund(uint256 invoiceId) external nonReentrant {
        PaymentInfo memory payment = payments[invoiceId];
        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);

        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (payment.amountPaid == 0) revert InvoiceNotFound();
        if (invoice.status != 3) revert InvalidStatus();

        uint256 refundAmount = payment.amountPaid;
        delete payments[invoiceId];
        delete partialPaid[invoiceId];

        if (payment.token == address(0)) {
            (bool success, ) = payable(payment.paidBy).call{value: refundAmount}("");
            if (!success) revert RefundFailed();
        } else {
            IERC20(payment.token).safeTransfer(payment.paidBy, refundAmount);
        }

        emit PaymentRefunded(invoiceId, payment.paidBy, refundAmount);
    }

    function getPaymentInfo(uint256 invoiceId) external view returns (PaymentInfo memory) {
        return payments[invoiceId];
    }

    function getRemainingAmount(uint256 invoiceId) external view returns (uint256) {
        IInvoiceNFT.Invoice memory invoice = invoiceNFT.getInvoice(invoiceId);
        uint256 paid = partialPaid[invoiceId];

        if (paid >= invoice.amount) return 0;
        return invoice.amount - paid;
    }

    function isPaid(uint256 invoiceId) external view returns (bool) {
        return payments[invoiceId].amountPaid > 0 ||
               partialPaid[invoiceId] >= invoiceNFT.getInvoice(invoiceId).amount;
    }

    receive() external payable {}
}
