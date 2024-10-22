// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract InvoiceNFT is 
    ERC721Upgradeable, 
    AccessControlUpgradeable, 
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    struct Invoice {
        uint256 id;
        address creator;
        address recipient;
        uint256 amount;
        address paymentToken;
        string description;
        uint256 dueDate;
        InvoiceStatus status;
        uint256 createdAt;
        uint256 paidAt;
    }

    enum InvoiceStatus {
        Pending,
        Paid,
        Cancelled,
        Overdue
    }

    uint256 internal _nextTokenId;
    
    mapping(uint256 => Invoice) internal _invoices;
    mapping(address => uint256[]) internal _creatorInvoices;
    mapping(address => uint256[]) internal _recipientInvoices;

    event InvoiceCreated(
        uint256 indexed tokenId,
        address indexed creator,
        address indexed recipient,
        uint256 amount,
        address paymentToken
    );

    event InvoicePaid(
        uint256 indexed tokenId,
        address indexed payer,
        uint256 amount,
        uint256 paidAt
    );

    event InvoiceCancelled(uint256 indexed tokenId, address indexed canceller);

    error InvalidAmount();
    error InvalidRecipient();
    error InvalidDueDate();
    error InvoiceNotPending();
    error UnauthorizedAccess();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin) public initializer {
        __ERC721_init("InvoBase Invoice", "INVB");
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(MINTER_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);

        _nextTokenId = 1;
    }

    function createInvoice(
        address recipient,
        uint256 amount,
        address paymentToken,
        string memory description,
        uint256 dueDate
    ) external virtual whenNotPaused nonReentrant returns (uint256) {
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

        _safeMint(msg.sender, tokenId);

        emit InvoiceCreated(tokenId, msg.sender, recipient, amount, paymentToken);

        return tokenId;
    }

    function markAsPaid(uint256 tokenId) external virtual onlyRole(MINTER_ROLE) {
        Invoice storage invoice = _invoices[tokenId];
        if (invoice.status != InvoiceStatus.Pending) revert InvoiceNotPending();

        invoice.status = InvoiceStatus.Paid;
        invoice.paidAt = block.timestamp;

        emit InvoicePaid(tokenId, invoice.recipient, invoice.amount, block.timestamp);
    }

    function cancelInvoice(uint256 tokenId) external virtual {
        Invoice storage invoice = _invoices[tokenId];
        if (msg.sender != invoice.creator && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert UnauthorizedAccess();
        }
        if (invoice.status != InvoiceStatus.Pending) revert InvoiceNotPending();

        invoice.status = InvoiceStatus.Cancelled;

        emit InvoiceCancelled(tokenId, msg.sender);
    }

    function getInvoice(uint256 tokenId) external view returns (Invoice memory) {
        return _invoices[tokenId];
    }

    function getCreatorInvoices(address creator) external view returns (uint256[] memory) {
        return _creatorInvoices[creator];
    }

    function getRecipientInvoices(address recipient) external view returns (uint256[] memory) {
        return _recipientInvoices[recipient];
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
