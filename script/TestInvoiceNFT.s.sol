// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TestInvoiceNFT is Script {
    function run() external {
        address testPayer = address(0x1234567890123456789012345678901234567890);
        uint256 testAmount = 1000e6;
        uint256 testDueDate = block.timestamp + 30 days;

        address owner = address(this);

        InvoiceNFT implementation = new InvoiceNFT();
        bytes memory initData = abi.encodeCall(InvoiceNFT.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        InvoiceNFT nft = InvoiceNFT(address(proxy));

        uint256 tokenId = nft.mint(testPayer, testAmount, testDueDate);
        console.log("Minted invoice NFT:", tokenId);

        InvoiceNFT.Invoice memory invoice = nft.getInvoice(tokenId);
        console.log("Issuer:", invoice.issuer);
        console.log("Payer:", invoice.payer);
        console.log("Amount:", invoice.amount);
        console.log("Status:", uint256(invoice.status));

        nft.issue(tokenId);
        console.log("Invoice issued");

        invoice = nft.getInvoice(tokenId);
        console.log("New status:", uint256(invoice.status));

        console.log("All tests passed");
    }
}
