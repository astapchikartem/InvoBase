// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";

/// @title InteractInvoice
/// @notice Script for interacting with deployed invoice contracts
contract InteractInvoice is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address invoiceManagerAddress = vm.envAddress("INVOICE_MANAGER_ADDRESS");

        InvoiceManager manager = InvoiceManager(invoiceManagerAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Example: Get invoice details
        uint256 invoiceId = 1;
        try manager.getInvoice(invoiceId) returns (
            IInvoiceManager.Invoice memory invoice
        ) {
            console.log("Invoice ID:", invoice.id);
            console.log("Amount:", invoice.amount);
            console.log("Status:", uint256(invoice.status));
        } catch {
            console.log("Invoice not found");
        }

        vm.stopBroadcast();
    }
}
