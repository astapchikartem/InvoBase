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
 * @title Deploy
 * @notice Universal deployment scripts for InvoBase contracts
 * @dev All contracts are upgradeable using UUPS pattern
 *
 * Usage:
 *   Deploy all contracts:
 *     forge script script/Deploy.s.sol:DeployAll<Network> --rpc-url $RPC --broadcast --verify
 *
 *   Deploy individual contracts:
 *     forge script script/Deploy.s.sol:DeployNFT<Network> --rpc-url $RPC --broadcast --verify
 *     forge script script/Deploy.s.sol:DeployPayment<Network> --rpc-url $RPC --broadcast --verify
 *     forge script script/Deploy.s.sol:DeployLink<Network> --rpc-url $RPC --broadcast --verify
 */

struct DeploymentAddresses {
    address nftProxy;
    address nftImpl;
    address paymentProxy;
    address paymentImpl;
    address linkProxy;
    address linkImpl;
    address deployer;
}

// ========================================
// BASE SEPOLIA DEPLOYMENTS
// ========================================

contract DeployAllSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying InvoBase on Base Sepolia ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy InvoiceNFTV2
        address nftImpl = address(new InvoiceNFTV2());
        address nft = address(new ERC1967Proxy(nftImpl, abi.encodeCall(InvoiceNFTV2.initialize, (deployer))));
        console.log("InvoiceNFTV2 Proxy:", nft);
        console.log("InvoiceNFTV2 Implementation:", nftImpl);

        // Deploy InvoicePayment
        address paymentImpl = address(new InvoicePayment());
        address payment =
            address(new ERC1967Proxy(paymentImpl, abi.encodeCall(InvoicePayment.initialize, (nft, deployer))));
        console.log("InvoicePayment Proxy:", payment);
        console.log("InvoicePayment Implementation:", paymentImpl);

        // Initialize V2 on NFT
        InvoiceNFTV2(nft).initializeV2(payment);

        // Deploy PaymentLink
        address linkImpl = address(new PaymentLink());
        address link =
            address(new ERC1967Proxy(linkImpl, abi.encodeCall(PaymentLink.initialize, (payment, nft, deployer))));
        console.log("PaymentLink Proxy:", link);
        console.log("PaymentLink Implementation:", linkImpl);

        // Configure USDC support (Base Sepolia USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e)
        InvoicePayment(payable(payment)).setSupportedToken(0x036CbD53842c5426634e7929541eC2318f3dCF7e, true);
        console.log("USDC support enabled:", 0x036CbD53842c5426634e7929541eC2318f3dCF7e);

        vm.stopBroadcast();

        console.log("\n[PASS] Deployment complete");

        _saveDeployment(
            "base-sepolia",
            DeploymentAddresses({
                nftProxy: nft,
                nftImpl: nftImpl,
                paymentProxy: payment,
                paymentImpl: paymentImpl,
                linkProxy: link,
                linkImpl: linkImpl,
                deployer: deployer
            })
        );
    }

    function _saveDeployment(string memory network, DeploymentAddresses memory addrs) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        vm.serializeString(json, "network", network);
        vm.serializeAddress(json, "nft", addrs.nftProxy);
        vm.serializeAddress(json, "nftImpl", addrs.nftImpl);
        vm.serializeAddress(json, "payment", addrs.paymentProxy);
        vm.serializeAddress(json, "paymentImpl", addrs.paymentImpl);
        vm.serializeAddress(json, "paymentLink", addrs.linkProxy);
        vm.serializeAddress(json, "paymentLinkImpl", addrs.linkImpl);
        vm.serializeAddress(json, "deployer", addrs.deployer);
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeUint(json, "blockNumber", block.number);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}

// ========================================
// BASE MAINNET DEPLOYMENTS
// ========================================

contract DeployAllMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=== Deploying InvoBase on Base Mainnet ===");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy InvoiceNFTV2
        address nftImpl = address(new InvoiceNFTV2());
        address nft = address(new ERC1967Proxy(nftImpl, abi.encodeCall(InvoiceNFTV2.initialize, (deployer))));
        console.log("InvoiceNFTV2 Proxy:", nft);
        console.log("InvoiceNFTV2 Implementation:", nftImpl);

        // Deploy InvoicePayment
        address paymentImpl = address(new InvoicePayment());
        address payment =
            address(new ERC1967Proxy(paymentImpl, abi.encodeCall(InvoicePayment.initialize, (nft, deployer))));
        console.log("InvoicePayment Proxy:", payment);
        console.log("InvoicePayment Implementation:", paymentImpl);

        // Initialize V2 on NFT
        InvoiceNFTV2(nft).initializeV2(payment);

        // Deploy PaymentLink
        address linkImpl = address(new PaymentLink());
        address link =
            address(new ERC1967Proxy(linkImpl, abi.encodeCall(PaymentLink.initialize, (payment, nft, deployer))));
        console.log("PaymentLink Proxy:", link);
        console.log("PaymentLink Implementation:", linkImpl);

        // Configure USDC support (Base Mainnet USDC: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
        InvoicePayment(payable(payment)).setSupportedToken(0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913, true);
        console.log("USDC support enabled:", 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913);

        vm.stopBroadcast();

        console.log("\n[PASS] Deployment complete");

        _saveDeployment(
            "base-mainnet",
            DeploymentAddresses({
                nftProxy: nft,
                nftImpl: nftImpl,
                paymentProxy: payment,
                paymentImpl: paymentImpl,
                linkProxy: link,
                linkImpl: linkImpl,
                deployer: deployer
            })
        );
    }

    function _saveDeployment(string memory network, DeploymentAddresses memory addrs) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        vm.serializeString(json, "network", network);
        vm.serializeAddress(json, "nft", addrs.nftProxy);
        vm.serializeAddress(json, "nftImpl", addrs.nftImpl);
        vm.serializeAddress(json, "payment", addrs.paymentProxy);
        vm.serializeAddress(json, "paymentImpl", addrs.paymentImpl);
        vm.serializeAddress(json, "paymentLink", addrs.linkProxy);
        vm.serializeAddress(json, "paymentLinkImpl", addrs.linkImpl);
        vm.serializeAddress(json, "deployer", addrs.deployer);
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeUint(json, "blockNumber", block.number);
        string memory finalJson = vm.serializeUint(json, "timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
        console.log("\nDeployment saved to:", path);
    }
}
