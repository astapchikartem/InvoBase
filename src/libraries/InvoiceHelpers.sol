// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "../interfaces/IInvoiceManager.sol";

library InvoiceHelpers {
    function formatInvoiceId(uint256 id) internal pure returns (string memory) {
        return string(abi.encodePacked("INV-", _toString(id)));
    }

    function calculateDaysUntilDue(
        IInvoiceManager.Invoice memory invoice
    ) internal view returns (uint256) {
        if (invoice.dueDate <= block.timestamp) return 0;
        return (invoice.dueDate - block.timestamp) / 1 days;
    }

    function isPayable(IInvoiceManager.Invoice memory invoice) internal view returns (bool) {
        return invoice.status == IInvoiceManager.InvoiceStatus.Issued
            && block.timestamp <= invoice.dueDate;
    }

    function hashInvoiceData(
        IInvoiceManager.Invoice memory invoice
    ) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                invoice.id,
                invoice.issuer,
                invoice.payer,
                invoice.amount,
                invoice.asset,
                invoice.metadata
            )
        );
    }

    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
