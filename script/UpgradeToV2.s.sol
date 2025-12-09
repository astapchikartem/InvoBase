// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract UpgradeToV2Sepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing proxy address from deployment file
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia.json");
        string memory json = vm.readFile(path);
        address proxyAddress = json.readAddress(".proxy");

        console.log("=== Upgrading to V2 on Base Sepolia ===");
        console.log("Existing Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new V2 implementation
        InvoiceNFTV2 implementationV2 = new InvoiceNFTV2();
        console.log("V2 Implementation deployed:", address(implementationV2));

        // Upgrade proxy to V2
        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(implementationV2), "");
        console.log("Proxy upgraded to V2");

        // Deploy InvoicePayment
        InvoicePayment paymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("InvoicePayment deployed:", address(paymentProcessor));

        // Initialize V2 with payment processor
        proxy.initializeV2(address(paymentProcessor));
        console.log("V2 initialized with payment processor");

        // Deploy PaymentLink
        PaymentLink paymentLink = new PaymentLink(address(paymentProcessor), proxyAddress, deployer);
        console.log("PaymentLink deployed:", address(paymentLink));

        // Set supported tokens
        address usdcSepolia = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // USDC on Base Sepolia
        paymentProcessor.setSupportedToken(usdcSepolia, true);
        console.log("USDC Sepolia support enabled:", usdcSepolia);

        vm.stopBroadcast();

        console.log("\n=== Upgrade Complete ===");
        console.log("Proxy:", proxyAddress);
        console.log("V2 Implementation:", address(implementationV2));
        console.log("Payment Processor:", address(paymentProcessor));
        console.log("Payment Link:", address(paymentLink));

        _saveUpgrade(
            "base-sepolia",
            proxyAddress,
            address(implementationV2),
            address(paymentProcessor),
            address(paymentLink),
            deployer
        );
    }

    function _saveUpgrade(
        string memory network,
        address proxy,
        address implementationV2,
        address paymentProcessor,
        address paymentLink,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-v2.json");

        string memory json = "upgrade";
        json.serialize("network", network);
        json.serialize("proxy", proxy);
        json.serialize("implementationV2", implementationV2);
        json.serialize("paymentProcessor", paymentProcessor);
        json.serialize("paymentLink", paymentLink);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}

contract UpgradeToV2Mainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Existing proxy on mainnet
        address proxyAddress = 0xE8E1563be6e10a764C24A46158f661e53D407771;

        console.log("=== Upgrading to V2 on Base Mainnet ===");
        console.log("Existing Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new V2 implementation
        InvoiceNFTV2 implementationV2 = new InvoiceNFTV2();
        console.log("V2 Implementation deployed:", address(implementationV2));

        // Upgrade proxy to V2
        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(implementationV2), "");
        console.log("Proxy upgraded to V2");

        // Deploy InvoicePayment
        InvoicePayment paymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("InvoicePayment deployed:", address(paymentProcessor));

        // Initialize V2 with payment processor
        proxy.initializeV2(address(paymentProcessor));
        console.log("V2 initialized with payment processor");

        // Deploy PaymentLink
        PaymentLink paymentLink = new PaymentLink(address(paymentProcessor), proxyAddress, deployer);
        console.log("PaymentLink deployed:", address(paymentLink));

        // Set supported tokens
        address usdcBase = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base
        paymentProcessor.setSupportedToken(usdcBase, true);
        console.log("USDC Base support enabled:", usdcBase);

        vm.stopBroadcast();

        console.log("\n=== Upgrade Complete ===");
        console.log("Proxy:", proxyAddress);
        console.log("V2 Implementation:", address(implementationV2));
        console.log("Payment Processor:", address(paymentProcessor));
        console.log("Payment Link:", address(paymentLink));

        _saveUpgrade(
            "base-mainnet",
            proxyAddress,
            address(implementationV2),
            address(paymentProcessor),
            address(paymentLink),
            deployer
        );
    }

    function _saveUpgrade(
        string memory network,
        address proxy,
        address implementationV2,
        address paymentProcessor,
        address paymentLink,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-v2.json");

        string memory json = "upgrade";
        json.serialize("network", network);
        json.serialize("proxy", proxy);
        json.serialize("implementationV2", implementationV2);
        json.serialize("paymentProcessor", paymentProcessor);
        json.serialize("paymentLink", paymentLink);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}
