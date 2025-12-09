// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {stdJson} from "forge-std/StdJson.sol";

// Deploy only InvoicePayment processor
contract DeployPaymentProcessorSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing proxy
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia-v2.json");
        string memory json = vm.readFile(path);
        address proxyAddress = json.readAddress(".proxy");

        console.log("=== Deploying InvoicePayment on Base Sepolia ===");
        console.log("Invoice NFT Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoicePayment paymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("InvoicePayment deployed:", address(paymentProcessor));

        // Set supported tokens
        address usdcSepolia = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        paymentProcessor.setSupportedToken(usdcSepolia, true);
        console.log("USDC Sepolia support enabled:", usdcSepolia);

        // Update payment processor in NFT contract
        InvoiceNFTV2 nft = InvoiceNFTV2(proxyAddress);
        nft.setPaymentProcessor(address(paymentProcessor));
        console.log("Payment processor set in NFT contract");

        vm.stopBroadcast();

        _saveComponent("base-sepolia", "payment-processor", address(paymentProcessor));
    }

    function _saveComponent(string memory network, string memory component, address contractAddress) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-", component, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("component", component);
        json.serialize("address", contractAddress);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}

contract DeployPaymentProcessorMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address proxyAddress = 0xE8E1563be6e10a764C24A46158f661e53D407771;

        console.log("=== Deploying InvoicePayment on Base Mainnet ===");
        console.log("Invoice NFT Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoicePayment paymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("InvoicePayment deployed:", address(paymentProcessor));

        // Set supported tokens
        address usdcBase = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        paymentProcessor.setSupportedToken(usdcBase, true);
        console.log("USDC Base support enabled:", usdcBase);

        // Update payment processor in NFT contract
        InvoiceNFTV2 nft = InvoiceNFTV2(proxyAddress);
        nft.setPaymentProcessor(address(paymentProcessor));
        console.log("Payment processor set in NFT contract");

        vm.stopBroadcast();

        _saveComponent("base-mainnet", "payment-processor", address(paymentProcessor));
    }

    function _saveComponent(string memory network, string memory component, address contractAddress) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-", component, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("component", component);
        json.serialize("address", contractAddress);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}

// Deploy only PaymentLink
contract DeployPaymentLinkSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing addresses
        string memory root = vm.projectRoot();
        string memory v2Path = string.concat(root, "/deployments/base-sepolia-v2.json");
        string memory v2Json = vm.readFile(v2Path);
        address proxyAddress = v2Json.readAddress(".proxy");
        address paymentProcessorAddress = v2Json.readAddress(".paymentProcessor");

        console.log("=== Deploying PaymentLink on Base Sepolia ===");
        console.log("Invoice NFT Proxy:", proxyAddress);
        console.log("Payment Processor:", paymentProcessorAddress);

        vm.startBroadcast(deployerPrivateKey);

        PaymentLink paymentLink = new PaymentLink(paymentProcessorAddress, proxyAddress, deployer);
        console.log("PaymentLink deployed:", address(paymentLink));

        vm.stopBroadcast();

        _saveComponent("base-sepolia", "payment-link", address(paymentLink));
    }

    function _saveComponent(string memory network, string memory component, address contractAddress) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-", component, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("component", component);
        json.serialize("address", contractAddress);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}

contract DeployPaymentLinkMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing addresses
        string memory root = vm.projectRoot();
        string memory v2Path = string.concat(root, "/deployments/base-mainnet-v2.json");
        string memory v2Json = vm.readFile(v2Path);
        address proxyAddress = v2Json.readAddress(".proxy");
        address paymentProcessorAddress = v2Json.readAddress(".paymentProcessor");

        console.log("=== Deploying PaymentLink on Base Mainnet ===");
        console.log("Invoice NFT Proxy:", proxyAddress);
        console.log("Payment Processor:", paymentProcessorAddress);

        vm.startBroadcast(deployerPrivateKey);

        PaymentLink paymentLink = new PaymentLink(paymentProcessorAddress, proxyAddress, deployer);
        console.log("PaymentLink deployed:", address(paymentLink));

        vm.stopBroadcast();

        _saveComponent("base-mainnet", "payment-link", address(paymentLink));
    }

    function _saveComponent(string memory network, string memory component, address contractAddress) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-", component, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("component", component);
        json.serialize("address", contractAddress);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}
