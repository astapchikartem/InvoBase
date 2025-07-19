// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceLib} from "../src/libraries/InvoiceLib.sol";
import {IInvoiceManager} from "../src/interfaces/IInvoiceManager.sol";

contract InvoiceLibTest is Test {
    using InvoiceLib for IInvoiceManager.Invoice;

    function testIsOverdue() public {
        IInvoiceManager.Invoice memory invoice = IInvoiceManager.Invoice({
            id: 1,
            issuer: address(0x1),
            payer: address(0x2),
            amount: 1000e6,
            asset: address(0x3),
            dueDate: block.timestamp - 1 days,
            status: IInvoiceManager.InvoiceStatus.Issued,
            metadata: "",
            createdAt: block.timestamp - 2 days,
            paidAt: 0
        });

        assertTrue(InvoiceLib.isOverdue(invoice));
    }

    function testCalculateLateFee() public {
        IInvoiceManager.Invoice memory invoice = IInvoiceManager.Invoice({
            id: 1,
            issuer: address(0x1),
            payer: address(0x2),
            amount: 1000e6,
            asset: address(0x3),
            dueDate: block.timestamp - 10 days,
            status: IInvoiceManager.InvoiceStatus.Issued,
            metadata: "",
            createdAt: block.timestamp - 11 days,
            paidAt: 0
        });

        uint256 fee = InvoiceLib.calculateLateFee(invoice, 500);
        assertGt(fee, 0);
    }

    function testValidateInvoice() public {
        IInvoiceManager.Invoice memory validInvoice = IInvoiceManager.Invoice({
            id: 1,
            issuer: address(0x1),
            payer: address(0x2),
            amount: 1000e6,
            asset: address(0x3),
            dueDate: block.timestamp + 30 days,
            status: IInvoiceManager.InvoiceStatus.Draft,
            metadata: "",
            createdAt: block.timestamp,
            paidAt: 0
        });

        assertTrue(InvoiceLib.validateInvoice(validInvoice));
    }
}
