// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./PaymentProcessor.sol";

contract PaymentProcessorV2 is PaymentProcessor {
    uint256 public totalPaymentsProcessed;
    uint256 public totalVolumeProcessed;
    
    mapping(address => uint256) public userPaymentCount;
    mapping(address => uint256) public userPaymentVolume;
    mapping(address => uint256) public tokenVolumeProcessed;

    event PaymentStatisticsUpdated(
        address indexed payer,
        uint256 paymentCount,
        uint256 totalVolume
    );

    function version() external pure returns (string memory) {
        return "2.0.0";
    }

    function processPayment(uint256 invoiceId) external payable override whenNotPaused nonReentrant {
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

        totalPaymentsProcessed++;
        totalVolumeProcessed += amount;
        userPaymentCount[msg.sender]++;
        userPaymentVolume[msg.sender] += amount;
        tokenVolumeProcessed[paymentToken] += amount;

        emit PaymentProcessed(invoiceId, msg.sender, paymentToken, amount, fee);
        emit PaymentStatisticsUpdated(msg.sender, userPaymentCount[msg.sender], userPaymentVolume[msg.sender]);
    }

    function getGlobalStatistics() external view returns (
        uint256 totalPayments,
        uint256 totalVolume,
        uint256 averagePayment
    ) {
        uint256 avg = totalPaymentsProcessed > 0 ? totalVolumeProcessed / totalPaymentsProcessed : 0;
        return (totalPaymentsProcessed, totalVolumeProcessed, avg);
    }

    function getUserStatistics(address user) external view returns (
        uint256 paymentCount,
        uint256 paymentVolume,
        uint256 averagePayment
    ) {
        uint256 avg = userPaymentCount[user] > 0 ? userPaymentVolume[user] / userPaymentCount[user] : 0;
        return (userPaymentCount[user], userPaymentVolume[user], avg);
    }

    function getTokenStatistics(address token) external view returns (uint256 volume) {
        return tokenVolumeProcessed[token];
    }

    function batchUpdateTokenSupport(
        address[] calldata tokens,
        bool[] calldata supported
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(tokens.length == supported.length, "Array lengths mismatch");
        
        for (uint256 i = 0; i < tokens.length; i++) {
            supportedTokens[tokens[i]] = supported[i];
            emit TokenSupportUpdated(tokens[i], supported[i]);
        }
    }
}
