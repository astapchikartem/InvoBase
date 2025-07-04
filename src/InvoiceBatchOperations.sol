// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "./interfaces/IInvoiceManager.sol";

contract InvoiceBatchOperations {
    IInvoiceManager public immutable invoiceManager;

    struct BatchInvoiceParams {
        address payer;
        uint256 amount;
        address asset;
        string metadata;
    }

    event BatchCreated(uint256[] invoiceIds, address indexed issuer);

    constructor(address _invoiceManager) {
        invoiceManager = IInvoiceManager(_invoiceManager);
    }

    function createBatch(
        BatchInvoiceParams[] calldata params
    ) external returns (uint256[] memory) {
        uint256[] memory invoiceIds = new uint256[](params.length);

        for (uint256 i = 0; i < params.length; i++) {
            invoiceIds[i] = invoiceManager.createInvoice(
                params[i].payer,
                params[i].amount,
                params[i].asset,
                params[i].metadata
            );
        }

        emit BatchCreated(invoiceIds, msg.sender);

        return invoiceIds;
    }

    function issueBatch(uint256[] calldata ids, uint256[] calldata dueDates) external {
        require(ids.length == dueDates.length, "Length mismatch");

        for (uint256 i = 0; i < ids.length; i++) {
            invoiceManager.issueInvoice(ids[i], dueDates[i]);
        }
    }

    function cancelBatch(uint256[] calldata ids) external {
        for (uint256 i = 0; i < ids.length; i++) {
            invoiceManager.cancelInvoice(ids[i]);
        }
    }
}
