// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "../interfaces/IInvoiceManager.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBasePay {
    function processPayment(address from, address to, uint256 amount, address token) external;
}

contract BasePayIntegration {
    IInvoiceManager public immutable invoiceManager;
    IBasePay public basePay;
    bool public useBasePay;

    event BasePayEnabled(address indexed basePay);
    event BasePayDisabled();
    event PaymentProcessedViaBasePay(
        uint256 indexed invoiceId,
        address indexed payer,
        address indexed issuer,
        uint256 amount
    );

    constructor(address _invoiceManager) {
        invoiceManager = IInvoiceManager(_invoiceManager);
    }

    function enableBasePay(address _basePay) external {
        basePay = IBasePay(_basePay);
        useBasePay = true;
        emit BasePayEnabled(_basePay);
    }

    function disableBasePay() external {
        useBasePay = false;
        emit BasePayDisabled();
    }

    function payInvoiceViaBasePay(uint256 invoiceId) external {
        require(useBasePay, "BasePay not enabled");

        IInvoiceManager.Invoice memory invoice = invoiceManager.getInvoice(invoiceId);
        require(
            invoice.status == IInvoiceManager.InvoiceStatus.Issued,
            "Invoice not issued"
        );

        basePay.processPayment(msg.sender, invoice.issuer, invoice.amount, invoice.asset);

        emit PaymentProcessedViaBasePay(invoiceId, msg.sender, invoice.issuer, invoice.amount);
    }

    function validateBasePaySetup() external view returns (bool) {
        return useBasePay && address(basePay) != address(0);
    }
}
