// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IInvoicePayment {
    function isPaid(uint256 invoiceId) external view returns (bool);
    function getRemainingAmount(uint256 invoiceId) external view returns (uint256);
}

contract InvoiceNFTV2 is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    using SafeERC20 for IERC20;

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

    address public paymentProcessor;
    mapping(uint256 => address) public invoiceToken;
    mapping(uint256 => bool) public partialPaymentAllowed;
    mapping(uint256 => string) public invoiceMemo;

    event InvoiceMinted(uint256 indexed tokenId, address indexed issuer, address indexed payer, uint256 amount);
    event StatusChanged(uint256 indexed tokenId, InvoiceStatus oldStatus, InvoiceStatus newStatus);
    event PaymentProcessorSet(address indexed processor);
    event InvoiceTokenSet(uint256 indexed tokenId, address indexed token);
    event PartialPaymentSet(uint256 indexed tokenId, bool allowed);

    error UnauthorizedTransfer();
    error InvalidStatus();
    error Unauthorized();
    error PaymentProcessorNotSet();
    error InvalidToken();
    error InvalidTransition();
    error AlreadyPaid();
    error CannotCancelPaidInvoice();

    function initialize(address initialOwner) public initializer {
        __ERC721_init("InvoBase Invoice", "INVO");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _nextTokenId = 1;
        if (initialOwner != msg.sender) {
            transferOwnership(initialOwner);
        }
    }

    function initializeV2(address _paymentProcessor) public reinitializer(2) {
        paymentProcessor = _paymentProcessor;
        emit PaymentProcessorSet(_paymentProcessor);
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

    function mintWithToken(address payer, uint256 amount, uint256 dueDate, address token, string memory memo)
        external
        returns (uint256)
    {
        if (token == address(0)) revert InvalidToken();

        uint256 tokenId = _nextTokenId++;

        _invoices[tokenId] = Invoice({
            issuer: msg.sender,
            payer: payer,
            amount: amount,
            dueDate: dueDate,
            status: InvoiceStatus.Draft,
            createdAt: block.timestamp
        });

        invoiceToken[tokenId] = token;
        invoiceMemo[tokenId] = memo;

        _mint(msg.sender, tokenId);

        emit InvoiceMinted(tokenId, msg.sender, payer, amount);
        emit InvoiceTokenSet(tokenId, token);

        return tokenId;
    }

    function issue(uint256 tokenId) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (invoice.status != InvoiceStatus.Draft) revert InvalidTransition();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Issued;

        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Issued);
    }

    function setPaymentProcessor(address processor) external onlyOwner {
        paymentProcessor = processor;
        emit PaymentProcessorSet(processor);
    }

    function setPartialPayment(uint256 tokenId, bool allowed) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();

        partialPaymentAllowed[tokenId] = allowed;
        emit PartialPaymentSet(tokenId, allowed);
    }

    function setInvoiceToken(uint256 tokenId, address token) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();

        invoiceToken[tokenId] = token;
        emit InvoiceTokenSet(tokenId, token);
    }

    function pay(uint256 tokenId) external payable {
        if (paymentProcessor == address(0)) revert PaymentProcessorNotSet();
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.status != InvoiceStatus.Issued) revert InvalidStatus();

        (bool success,) =
            paymentProcessor.call{value: msg.value}(abi.encodeWithSignature("payInvoice(uint256)", tokenId));
        require(success, "Payment failed");

        _updateStatusIfPaid(tokenId);
    }

    function payWithToken(uint256 tokenId, uint256 amount) external {
        if (paymentProcessor == address(0)) revert PaymentProcessorNotSet();
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.status != InvoiceStatus.Issued) revert InvalidStatus();

        address token = invoiceToken[tokenId];
        if (token == address(0)) revert InvalidToken();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(paymentProcessor, amount);

        (bool success,) = paymentProcessor.call(
            abi.encodeWithSignature("payInvoiceToken(uint256,address,uint256)", tokenId, token, amount)
        );
        require(success, "Payment failed");

        _updateStatusIfPaid(tokenId);
    }

    function cancel(uint256 tokenId) external {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.issuer != msg.sender) revert Unauthorized();
        if (invoice.status == InvoiceStatus.Paid) revert CannotCancelPaidInvoice();
        if (invoice.status == InvoiceStatus.Cancelled) revert InvalidTransition();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Cancelled;

        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Cancelled);

        if (paymentProcessor != address(0) && oldStatus == InvoiceStatus.Issued) {
            (bool success,) = paymentProcessor.call(abi.encodeWithSignature("refund(uint256)", tokenId));
            // Ignore refund failures if no payment exists
        }
    }

    function getPaymentStatus(uint256 tokenId) external view returns (bool paid, uint256 remaining) {
        if (paymentProcessor == address(0)) {
            return (_invoices[tokenId].status == InvoiceStatus.Paid, _invoices[tokenId].amount);
        }

        IInvoicePayment processor = IInvoicePayment(paymentProcessor);
        paid = processor.isPaid(tokenId);
        remaining = processor.getRemainingAmount(tokenId);
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

    function _updateStatusIfPaid(uint256 tokenId) internal {
        if (paymentProcessor != address(0)) {
            IInvoicePayment processor = IInvoicePayment(paymentProcessor);
            if (processor.isPaid(tokenId)) {
                Invoice storage invoice = _invoices[tokenId];
                InvoiceStatus oldStatus = invoice.status;
                invoice.status = InvoiceStatus.Paid;
                emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Paid);
            }
        }
    }

    function markAsPaid(uint256 tokenId) external {
        if (msg.sender != paymentProcessor) revert Unauthorized();
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.status != InvoiceStatus.Issued) revert InvalidTransition();

        InvoiceStatus oldStatus = invoice.status;
        invoice.status = InvoiceStatus.Paid;
        emit StatusChanged(tokenId, oldStatus, InvoiceStatus.Paid);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
