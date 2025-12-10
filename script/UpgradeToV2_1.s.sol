// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {stdJson} from "forge-std/StdJson.sol";

/**
 * @title UpgradeToV2_1
 * @notice Upgrades InvoBase V2 to V2.1 with tightened lifecycle and payment validation
 * @dev Block 1 improvements: lifecycle tightening, payment state validation, refund improvements
 *
 * Run for Base Sepolia:
 *   forge script script/UpgradeToV2_1.s.sol:UpgradeToV2_1Sepolia \
 *     --rpc-url $BASE_SEPOLIA_RPC \
 *     --broadcast --verify -vvvv
 *
 * Run for Base Mainnet:
 *   forge script script/UpgradeToV2_1.s.sol:UpgradeToV2_1Mainnet \
 *     --rpc-url $BASE_MAINNET_RPC \
 *     --broadcast --verify -vvvv
 */

contract UpgradeToV2_1Sepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing deployment addresses
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia-v2.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".proxy");
        address paymentProcessorAddress = json.readAddress(".paymentProcessor");

        console.log("=== Upgrading to V2.1 on Base Sepolia ===");
        console.log("Existing Proxy (InvoiceNFTV2):", proxyAddress);
        console.log("Existing Payment Processor:", paymentProcessorAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new V2.1 implementation with tightened lifecycle
        InvoiceNFTV2 implementationV2_1 = new InvoiceNFTV2();
        console.log("V2.1 Implementation deployed:", address(implementationV2_1));

        // Upgrade proxy to V2.1
        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(implementationV2_1), "");
        console.log("Proxy upgraded to V2.1");

        // Deploy new InvoicePayment with improved validation
        InvoicePayment newPaymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("New InvoicePayment deployed:", address(newPaymentProcessor));

        // Set payment processor on NFT contract
        proxy.setPaymentProcessor(address(newPaymentProcessor));
        console.log("Payment processor updated on NFT contract");

        // Configure supported tokens on new payment processor
        address usdcSepolia = 0x036CbD53842c5426634e7929541eC2318f3dCF7e; // USDC on Base Sepolia
        newPaymentProcessor.setSupportedToken(usdcSepolia, true);
        console.log("USDC Sepolia support enabled:", usdcSepolia);

        vm.stopBroadcast();

        console.log("\n=== V2.1 Upgrade Complete ===");
        console.log("Improvements:");
        console.log("  - Tightened invoice lifecycle state transitions");
        console.log("  - Strengthened payment validation (Draft/Cancelled checks)");
        console.log("  - Improved partial payment refunds");
        console.log("  - Parameter modification locks (after issuance)");
        console.log("  - Double payment prevention");
        console.log("\nDeployment Details:");
        console.log("  Proxy:", proxyAddress);
        console.log("  V2.1 Implementation:", address(implementationV2_1));
        console.log("  New Payment Processor:", address(newPaymentProcessor));
        console.log("  Old Payment Processor:", paymentProcessorAddress);

        _saveUpgrade(
            "base-sepolia",
            proxyAddress,
            address(implementationV2_1),
            address(newPaymentProcessor),
            paymentProcessorAddress,
            deployer
        );
    }

    function _saveUpgrade(
        string memory network,
        address proxy,
        address implementationV2_1,
        address newPaymentProcessor,
        address oldPaymentProcessor,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-v2.1.json");

        string memory json = "upgrade";
        json.serialize("network", network);
        json.serialize("version", "2.1");
        json.serialize("proxy", proxy);
        json.serialize("implementationV2_1", implementationV2_1);
        json.serialize("paymentProcessor", newPaymentProcessor);
        json.serialize("oldPaymentProcessor", oldPaymentProcessor);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}

contract UpgradeToV2_1Mainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        // Load existing deployment addresses
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-mainnet-v2.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".proxy");
        address paymentProcessorAddress = json.readAddress(".paymentProcessor");

        console.log("=== Upgrading to V2.1 on Base Mainnet ===");
        console.log("Existing Proxy (InvoiceNFTV2):", proxyAddress);
        console.log("Existing Payment Processor:", paymentProcessorAddress);

        console.log("\n[WARNING] Upgrading production contracts on Base Mainnet");
        console.log("Please ensure:");
        console.log("  1. All tests have passed on Base Sepolia");
        console.log("  2. Contracts have been verified on BaseScan");
        console.log("  3. Upgrade has been reviewed and approved");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new V2.1 implementation
        InvoiceNFTV2 implementationV2_1 = new InvoiceNFTV2();
        console.log("V2.1 Implementation deployed:", address(implementationV2_1));

        // Upgrade proxy to V2.1
        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(implementationV2_1), "");
        console.log("Proxy upgraded to V2.1");

        // Deploy new InvoicePayment
        InvoicePayment newPaymentProcessor = new InvoicePayment(proxyAddress, deployer);
        console.log("New InvoicePayment deployed:", address(newPaymentProcessor));

        // Set payment processor on NFT contract
        proxy.setPaymentProcessor(address(newPaymentProcessor));
        console.log("Payment processor updated on NFT contract");

        // Configure supported tokens
        address usdcBase = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // USDC on Base
        newPaymentProcessor.setSupportedToken(usdcBase, true);
        console.log("USDC Base support enabled:", usdcBase);

        vm.stopBroadcast();

        console.log("\n=== V2.1 Upgrade Complete ===");
        console.log("Improvements:");
        console.log("  - Tightened invoice lifecycle state transitions");
        console.log("  - Strengthened payment validation");
        console.log("  - Improved partial payment refunds");
        console.log("  - Parameter modification locks");
        console.log("  - Double payment prevention");
        console.log("\nDeployment Details:");
        console.log("  Proxy:", proxyAddress);
        console.log("  V2.1 Implementation:", address(implementationV2_1));
        console.log("  New Payment Processor:", address(newPaymentProcessor));
        console.log("  Old Payment Processor:", paymentProcessorAddress);

        _saveUpgrade(
            "base-mainnet",
            proxyAddress,
            address(implementationV2_1),
            address(newPaymentProcessor),
            paymentProcessorAddress,
            deployer
        );
    }

    function _saveUpgrade(
        string memory network,
        address proxy,
        address implementationV2_1,
        address newPaymentProcessor,
        address oldPaymentProcessor,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, "-v2.1.json");

        string memory json = "upgrade";
        json.serialize("network", network);
        json.serialize("version", "2.1");
        json.serialize("proxy", proxy);
        json.serialize("implementationV2_1", implementationV2_1);
        json.serialize("paymentProcessor", newPaymentProcessor);
        json.serialize("oldPaymentProcessor", oldPaymentProcessor);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}
