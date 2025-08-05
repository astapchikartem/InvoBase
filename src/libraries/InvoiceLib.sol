// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "../interfaces/IInvoiceManager.sol";

library InvoiceLib {
    function isOverdue(IInvoiceManager.Invoice memory invoice) internal view returns (bool) {
        return invoice.status == IInvoiceManager.InvoiceStatus.Issued
            && block.timestamp > invoice.dueDate;
    }

    function isPending(IInvoiceManager.Invoice memory invoice) internal pure returns (bool) {
        return invoice.status == IInvoiceManager.InvoiceStatus.Issued;
    }

    function isSettled(IInvoiceManager.Invoice memory invoice) internal pure returns (bool) {
        return invoice.status == IInvoiceManager.InvoiceStatus.Paid
            || invoice.status == IInvoiceManager.InvoiceStatus.Cancelled;
    }

    function calculateLateFee(
        IInvoiceManager.Invoice memory invoice,
        uint256 feePercentage
    ) internal view returns (uint256) {
        if (!isOverdue(invoice)) return 0;

        uint256 daysLate = (block.timestamp - invoice.dueDate) / 1 days;
        return (invoice.amount * feePercentage * daysLate) / 10000;
    }

    function validateInvoice(IInvoiceManager.Invoice memory invoice) internal pure returns (bool) {
        return invoice.issuer != address(0)
            && invoice.payer != address(0)
            && invoice.amount > 0
            && invoice.asset != address(0);
    }

    function getDaysUntilDue(IInvoiceManager.Invoice memory invoice) internal view returns (uint256) {
        if (invoice.dueDate <= block.timestamp) return 0;
        return (invoice.dueDate - block.timestamp) / 1 days;
    }

    function getDaysOverdue(IInvoiceManager.Invoice memory invoice) internal view returns (uint256) {
        if (!isOverdue(invoice)) return 0;
        return (block.timestamp - invoice.dueDate) / 1 days;
    }

    function getPaymentStatus(IInvoiceManager.Invoice memory invoice) internal view returns (string memory) {
        if (invoice.status == IInvoiceManager.InvoiceStatus.Paid) return "PAID";
        if (invoice.status == IInvoiceManager.InvoiceStatus.Cancelled) return "CANCELLED";
        if (invoice.status == IInvoiceManager.InvoiceStatus.Draft) return "DRAFT";
        if (isOverdue(invoice)) return "OVERDUE";
        return "PENDING";
    }
}
