// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {stdJson} from "forge-std/StdJson.sol";

/**
 * @title Migrate to Upgradeable
 * @notice Migrates existing deployment to fully upgradeable system
 * @dev
 *   - InvoiceNFTV2: Already UUPS - just upgrade
 *   - InvoicePayment: No proxy - deploy new with proxy
 *   - PaymentLink: No proxy - deploy new with proxy
 *
 * Usage:
 *   forge script script/Migrate.s.sol:MigrateSepolia --rpc-url $RPC --broadcast --verify
 */

contract MigrateSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Migrating to Upgradeable System on Base Sepolia ===");
        console.log("Deployer:", deployer);

        // Load existing addresses - scope strings to reduce stack pressure
        address nftProxy;
        {
            string memory root = vm.projectRoot();
            string memory path = string.concat(root, "/deployments/base-sepolia.json");
            string memory json = vm.readFile(path);

            nftProxy = json.readAddress(".nft");

            console.log("\n=== Existing Deployment ===");
            console.log("InvoiceNFTV2 Proxy:", nftProxy);
            console.log("Old InvoicePayment (no proxy):", json.readAddress(".payment"));
            console.log("Old PaymentLink (no proxy):", json.readAddress(".paymentLink"));
        }

        vm.startBroadcast(deployerPrivateKey);

        // 1. Upgrade InvoiceNFTV2
        console.log("\n=== Step 1: Upgrade InvoiceNFTV2 ===");
        address nftImpl = address(new InvoiceNFTV2());
        InvoiceNFTV2(nftProxy).upgradeToAndCall(nftImpl, "");
        console.log("New NFT Implementation:", nftImpl);

        // 2. Deploy InvoicePayment with proxy
        console.log("\n=== Step 2: Deploy InvoicePayment with Proxy ===");
        address paymentImpl = address(new InvoicePayment());
        address payment =
            address(new ERC1967Proxy(paymentImpl, abi.encodeCall(InvoicePayment.initialize, (nftProxy, deployer))));
        console.log("InvoicePayment Proxy:", payment);
        console.log("InvoicePayment Implementation:", paymentImpl);

        // 3. Update paymentProcessor on NFT
        console.log("\n=== Step 3: Update Payment Processor on NFT ===");
        // Hardcode NFT address to bypass any variable issues
        address nftProxyHardcoded = 0x59aD7168615DeE3024c4d2719eDAb656ad9cCE9c;
        console.log("Calling setPaymentProcessor on NFT proxy:", nftProxyHardcoded);
        console.log("Setting new payment processor to:", payment);

        // Low-level call: setPaymentProcessor(address)
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("setPaymentProcessor(address)")), payment);
        (bool success, bytes memory returnData) = nftProxyHardcoded.call(callData);
        require(success, string(abi.encodePacked("setPaymentProcessor failed: ", returnData)));
        console.log("Payment processor updated successfully");

        // 4. Deploy PaymentLink with proxy
        console.log("\n=== Step 4: Deploy PaymentLink with Proxy ===");
        address linkImpl = address(new PaymentLink());
        address link =
            address(new ERC1967Proxy(linkImpl, abi.encodeCall(PaymentLink.initialize, (payment, nftProxy, deployer))));
        console.log("PaymentLink Proxy:", link);
        console.log("PaymentLink Implementation:", linkImpl);

        // 5. Configure USDC support
        console.log("\n=== Step 5: Configure USDC ===");
        InvoicePayment(payable(payment)).setSupportedToken(0x036CbD53842c5426634e7929541eC2318f3dCF7e, true);
        console.log("USDC support enabled");

        vm.stopBroadcast();

        console.log("\n=== Migration Complete ===");
        console.log("All contracts now upgradeable!");
        console.log("\nNew Addresses:");
        console.log("  NFT Proxy:", nftProxy, "(unchanged)");
        console.log("  NFT Implementation:", nftImpl, "(new)");
        console.log("  Payment Proxy:", payment, "(new - upgradeable)");
        console.log("  Payment Implementation:", paymentImpl, "(new)");
        console.log("  Link Proxy:", link, "(new - upgradeable)");
        console.log("  Link Implementation:", linkImpl, "(new)");

        _saveMigration(nftProxy, nftImpl, payment, paymentImpl, link, linkImpl, deployer);
    }

    function _saveMigration(
        address nftProxy,
        address nftImpl,
        address paymentProxy,
        address paymentImpl,
        address linkProxy,
        address linkImpl,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia.json");

        string memory json = "migration";
        vm.serializeString(json, "network", "base-sepolia");
        vm.serializeAddress(json, "nft", nftProxy);
        vm.serializeAddress(json, "nftImpl", nftImpl);
        vm.serializeAddress(json, "payment", paymentProxy);
        vm.serializeAddress(json, "paymentImpl", paymentImpl);
        vm.serializeAddress(json, "paymentLink", linkProxy);
        vm.serializeAddress(json, "paymentLinkImpl", linkImpl);
        vm.serializeAddress(json, "deployer", deployer);
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeUint(json, "blockNumber", block.number);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}

contract MigrateMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Migrating to Upgradeable System on Base Mainnet ===");
        console.log("Deployer:", deployer);

        // Load existing addresses - scope strings to reduce stack pressure
        address nftProxy;
        {
            string memory root = vm.projectRoot();
            string memory path = string.concat(root, "/deployments/base-mainnet.json");
            string memory json = vm.readFile(path);

            nftProxy = json.readAddress(".nft");

            console.log("\n=== Existing Deployment ===");
            console.log("InvoiceNFTV2 Proxy:", nftProxy);
            console.log("Old InvoicePayment (no proxy):", json.readAddress(".payment"));
            console.log("Old PaymentLink (no proxy):", json.readAddress(".paymentLink"));
        }

        vm.startBroadcast(deployerPrivateKey);

        // 1. Upgrade InvoiceNFTV2
        console.log("\n=== Step 1: Upgrade InvoiceNFTV2 ===");
        address nftImpl = address(new InvoiceNFTV2());
        InvoiceNFTV2(nftProxy).upgradeToAndCall(nftImpl, "");
        console.log("New NFT Implementation:", nftImpl);

        // 2. Deploy InvoicePayment with proxy
        console.log("\n=== Step 2: Deploy InvoicePayment with Proxy ===");
        address paymentImpl = address(new InvoicePayment());
        address payment =
            address(new ERC1967Proxy(paymentImpl, abi.encodeCall(InvoicePayment.initialize, (nftProxy, deployer))));
        console.log("InvoicePayment Proxy:", payment);
        console.log("InvoicePayment Implementation:", paymentImpl);

        // 3. Update paymentProcessor on NFT
        console.log("\n=== Step 3: Update Payment Processor on NFT ===");
        // Load NFT address from deployment file
        address nftProxyAddress;
        {
            string memory root2 = vm.projectRoot();
            string memory path2 = string.concat(root2, "/deployments/base-mainnet.json");
            string memory json2 = vm.readFile(path2);
            nftProxyAddress = json2.readAddress(".nft");
        }
        console.log("Calling setPaymentProcessor on NFT proxy:", nftProxyAddress);
        console.log("Setting new payment processor to:", payment);

        // Low-level call: setPaymentProcessor(address)
        bytes memory callData = abi.encodeWithSelector(bytes4(keccak256("setPaymentProcessor(address)")), payment);
        (bool success, bytes memory returnData) = nftProxyAddress.call(callData);
        require(success, string(abi.encodePacked("setPaymentProcessor failed: ", returnData)));
        console.log("Payment processor updated successfully");

        // 4. Deploy PaymentLink with proxy
        console.log("\n=== Step 4: Deploy PaymentLink with Proxy ===");
        address linkImpl = address(new PaymentLink());
        address link =
            address(new ERC1967Proxy(linkImpl, abi.encodeCall(PaymentLink.initialize, (payment, nftProxy, deployer))));
        console.log("PaymentLink Proxy:", link);
        console.log("PaymentLink Implementation:", linkImpl);

        // 5. Configure USDC support
        console.log("\n=== Step 5: Configure USDC ===");
        InvoicePayment(payable(payment)).setSupportedToken(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, true);
        console.log("USDC support enabled");

        vm.stopBroadcast();

        console.log("\n=== Migration Complete ===");
        console.log("All contracts now upgradeable!");
        console.log("\nNew Addresses:");
        console.log("  NFT Proxy:", nftProxy, "(unchanged)");
        console.log("  NFT Implementation:", nftImpl, "(new)");
        console.log("  Payment Proxy:", payment, "(new - upgradeable)");
        console.log("  Payment Implementation:", paymentImpl, "(new)");
        console.log("  Link Proxy:", link, "(new - upgradeable)");
        console.log("  Link Implementation:", linkImpl, "(new)");

        _saveMigration(nftProxy, nftImpl, payment, paymentImpl, link, linkImpl, deployer);
    }

    function _saveMigration(
        address nftProxy,
        address nftImpl,
        address paymentProxy,
        address paymentImpl,
        address linkProxy,
        address linkImpl,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-mainnet.json");

        string memory json = "migration";
        vm.serializeString(json, "network", "base-mainnet");
        vm.serializeAddress(json, "nft", nftProxy);
        vm.serializeAddress(json, "nftImpl", nftImpl);
        vm.serializeAddress(json, "payment", paymentProxy);
        vm.serializeAddress(json, "paymentImpl", paymentImpl);
        vm.serializeAddress(json, "paymentLink", linkProxy);
        vm.serializeAddress(json, "paymentLinkImpl", linkImpl);
        vm.serializeAddress(json, "deployer", deployer);
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeUint(json, "blockNumber", block.number);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}
