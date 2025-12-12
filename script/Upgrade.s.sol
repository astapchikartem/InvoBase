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
 * @title Upgrade
 * @notice Universal upgrade scripts for InvoBase contracts
 * @dev Supports upgrading InvoiceNFTV2, InvoicePayment, and PaymentLink
 *
 * Usage:
 *   Upgrade NFT:
 *     forge script script/Upgrade.s.sol:UpgradeNFT --rpc-url $RPC --broadcast --verify
 *
 *   Upgrade Payment:
 *     forge script script/Upgrade.s.sol:UpgradePayment --rpc-url $RPC --broadcast --verify
 *
 *   Upgrade PaymentLink:
 *     forge script script/Upgrade.s.sol:UpgradeLink --rpc-url $RPC --broadcast --verify
 */

// Base Sepolia Upgrade Scripts
contract UpgradeNFTSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".nft");

        console.log("=== Upgrading InvoiceNFTV2 on Base Sepolia ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceNFTV2 newImpl = new InvoiceNFTV2();
        console.log("New Implementation:", address(newImpl));

        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}

contract UpgradePaymentSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".payment");

        console.log("=== Upgrading InvoicePayment on Base Sepolia ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoicePayment newImpl = new InvoicePayment();
        console.log("New Implementation:", address(newImpl));

        InvoicePayment proxy = InvoicePayment(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}

contract UpgradeLinkSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".paymentLink");

        console.log("=== Upgrading PaymentLink on Base Sepolia ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        PaymentLink newImpl = new PaymentLink();
        console.log("New Implementation:", address(newImpl));

        PaymentLink proxy = PaymentLink(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}

// Base Mainnet Upgrade Scripts
contract UpgradeNFTMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-mainnet.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".nft");

        console.log("=== Upgrading InvoiceNFTV2 on Base Mainnet ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceNFTV2 newImpl = new InvoiceNFTV2();
        console.log("New Implementation:", address(newImpl));

        InvoiceNFTV2 proxy = InvoiceNFTV2(proxyAddress);
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}

contract UpgradePaymentMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-mainnet.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".payment");

        console.log("=== Upgrading InvoicePayment on Base Mainnet ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoicePayment newImpl = new InvoicePayment();
        console.log("New Implementation:", address(newImpl));

        InvoicePayment proxy = InvoicePayment(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}

contract UpgradeLinkMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-mainnet.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".paymentLink");

        console.log("=== Upgrading PaymentLink on Base Mainnet ===");
        console.log("Proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        PaymentLink newImpl = new PaymentLink();
        console.log("New Implementation:", address(newImpl));

        PaymentLink proxy = PaymentLink(payable(proxyAddress));
        proxy.upgradeToAndCall(address(newImpl), "");

        vm.stopBroadcast();

        console.log("[PASS] Upgrade complete");
    }
}
