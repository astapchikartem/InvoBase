// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployInvoiceNFTV2 is Script {
    function run() external returns (
        address proxyAddress,
        address implementationAddress,
        address paymentProcessorAddress,
        address paymentLinkAddress
    ) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy InvoiceNFTV2 implementation
        implementationAddress = address(new InvoiceNFTV2());
        console.log("InvoiceNFTV2 implementation deployed at:", implementationAddress);

        // Deploy proxy with initialize
        bytes memory initData = abi.encodeCall(InvoiceNFTV2.initialize, (deployer));
        proxyAddress = address(new ERC1967Proxy(implementationAddress, initData));
        console.log("InvoiceNFTV2 proxy deployed at:", proxyAddress);

        // Deploy InvoicePayment processor
        paymentProcessorAddress = address(new InvoicePayment(proxyAddress, deployer));
        console.log("InvoicePayment deployed at:", paymentProcessorAddress);

        // Initialize V2 with payment processor
        InvoiceNFTV2 nftV2 = InvoiceNFTV2(proxyAddress);
        nftV2.initializeV2(paymentProcessorAddress);
        console.log("InvoiceNFTV2 initialized with payment processor");

        // Deploy PaymentLink
        paymentLinkAddress = address(new PaymentLink(
            paymentProcessorAddress,
            proxyAddress,
            deployer
        ));
        console.log("PaymentLink deployed at:", paymentLinkAddress);

        // Set up supported tokens
        InvoicePayment paymentProcessor = InvoicePayment(payable(paymentProcessorAddress));

        // USDC on Base mainnet
        address usdcBase = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        paymentProcessor.setSupportedToken(usdcBase, true);
        console.log("USDC token support enabled:", usdcBase);

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("InvoiceNFTV2 Proxy:", proxyAddress);
        console.log("InvoiceNFTV2 Implementation:", implementationAddress);
        console.log("InvoicePayment Processor:", paymentProcessorAddress);
        console.log("PaymentLink:", paymentLinkAddress);
        console.log("Owner:", deployer);

        return (proxyAddress, implementationAddress, paymentProcessorAddress, paymentLinkAddress);
    }
}
