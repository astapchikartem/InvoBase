// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IInvoiceNFT.sol";

contract PaymentProcessor is 
    AccessControlUpgradeable, 
    UUPSUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable 
{
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IInvoiceNFT public invoiceNFT;
    
    mapping(address => bool) public supportedTokens;
    mapping(uint256 => bool) public processedPayments;
    
    uint256 public platformFee;
    address public feeCollector;

    event PaymentProcessed(
        uint256 indexed invoiceId,
        address indexed payer,
        address indexed paymentToken,
        uint256 amount,
        uint256 fee
    );

    event TokenSupportUpdated(address indexed token, bool supported);
    event FeeUpdated(uint256 newFee);
    event FeeCollectorUpdated(address newCollector);

    error InvoiceNotFound();
    error InvoiceAlreadyPaid();
    error InvalidPaymentAmount();
    error UnsupportedToken();
    error PaymentFailed();
    error InvalidFeeCollector();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address defaultAdmin,
        address _invoiceNFT,
        address _feeCollector
    ) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, defaultAdmin);

        invoiceNFT = IInvoiceNFT(_invoiceNFT);
        feeCollector = _feeCollector;
        platformFee = 25;
        
        supportedTokens[address(0)] = true;
    }

    function processPayment(uint256 invoiceId) external payable virtual whenNotPaused nonReentrant {
        if (processedPayments[invoiceId]) revert InvoiceAlreadyPaid();

        (
            ,
            ,
            address recipient,
            uint256 amount,
            address paymentToken,
            ,
            ,
            uint8 status,
            ,
        ) = invoiceNFT.getInvoice(invoiceId);

        if (status != 0) revert InvoiceAlreadyPaid();
        if (!supportedTokens[paymentToken]) revert UnsupportedToken();

        uint256 fee = (amount * platformFee) / 10000;
        uint256 recipientAmount = amount - fee;

        if (paymentToken == address(0)) {
            if (msg.value != amount) revert InvalidPaymentAmount();
            
            (bool successRecipient, ) = recipient.call{value: recipientAmount}("");
            if (!successRecipient) revert PaymentFailed();
            
            (bool successFee, ) = feeCollector.call{value: fee}("");
            if (!successFee) revert PaymentFailed();
        } else {
            IERC20 token = IERC20(paymentToken);
            
            bool successTransfer = token.transferFrom(msg.sender, recipient, recipientAmount);
            if (!successTransfer) revert PaymentFailed();
            
            bool successFee = token.transferFrom(msg.sender, feeCollector, fee);
            if (!successFee) revert PaymentFailed();
        }

        processedPayments[invoiceId] = true;
        invoiceNFT.markAsPaid(invoiceId);

        emit PaymentProcessed(invoiceId, msg.sender, paymentToken, amount, fee);
    }

    function updateTokenSupport(address token, bool supported) external onlyRole(DEFAULT_ADMIN_ROLE) {
        supportedTokens[token] = supported;
        emit TokenSupportUpdated(token, supported);
    }

    function updatePlatformFee(uint256 newFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newFee <= 1000, "Fee too high");
        platformFee = newFee;
        emit FeeUpdated(newFee);
    }

    function updateFeeCollector(address newCollector) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newCollector == address(0)) revert InvalidFeeCollector();
        feeCollector = newCollector;
        emit FeeCollectorUpdated(newCollector);
    }

    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    receive() external payable {}
}
