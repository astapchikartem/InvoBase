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
        InvoiceNFTV2 nftImpl = new InvoiceNFTV2();
        bytes memory nftInitData = abi.encodeCall(InvoiceNFTV2.initialize, (deployer));
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        InvoiceNFTV2 nft = InvoiceNFTV2(address(nftProxy));
        console.log("InvoiceNFTV2 Proxy:", address(nft));
        console.log("InvoiceNFTV2 Implementation:", address(nftImpl));

        // Deploy InvoicePayment
        InvoicePayment paymentImpl = new InvoicePayment();
        bytes memory paymentInitData = abi.encodeCall(InvoicePayment.initialize, (address(nft), deployer));
        ERC1967Proxy paymentProxy = new ERC1967Proxy(address(paymentImpl), paymentInitData);
        InvoicePayment payment = InvoicePayment(payable(address(paymentProxy)));
        console.log("InvoicePayment Proxy:", address(payment));
        console.log("InvoicePayment Implementation:", address(paymentImpl));

        // Initialize V2 on NFT
        nft.initializeV2(address(payment));

        // Deploy PaymentLink
        PaymentLink linkImpl = new PaymentLink();
        bytes memory linkInitData = abi.encodeCall(PaymentLink.initialize, (address(payment), address(nft), deployer));
        ERC1967Proxy linkProxy = new ERC1967Proxy(address(linkImpl), linkInitData);
        PaymentLink link = PaymentLink(payable(address(linkProxy)));
        console.log("PaymentLink Proxy:", address(link));
        console.log("PaymentLink Implementation:", address(linkImpl));

        // Configure USDC support (Base Sepolia USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e)
        address usdcSepolia = 0x036CbD53842c5426634e7929541eC2318f3dCF7e;
        payment.setSupportedToken(usdcSepolia, true);
        console.log("USDC support enabled:", usdcSepolia);

        vm.stopBroadcast();

        console.log("\n[PASS] Deployment complete");

        _saveDeployment("base-sepolia", address(nft), address(nftImpl), address(payment), address(paymentImpl), address(link), address(linkImpl), deployer);
    }

    function _saveDeployment(
        string memory network,
        address nftProxy,
        address nftImpl,
        address paymentProxy,
        address paymentImpl,
        address linkProxy,
        address linkImpl,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        vm.serializeString(json, "network", network);
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
        InvoiceNFTV2 nftImpl = new InvoiceNFTV2();
        bytes memory nftInitData = abi.encodeCall(InvoiceNFTV2.initialize, (deployer));
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        InvoiceNFTV2 nft = InvoiceNFTV2(address(nftProxy));
        console.log("InvoiceNFTV2 Proxy:", address(nft));
        console.log("InvoiceNFTV2 Implementation:", address(nftImpl));

        // Deploy InvoicePayment
        InvoicePayment paymentImpl = new InvoicePayment();
        bytes memory paymentInitData = abi.encodeCall(InvoicePayment.initialize, (address(nft), deployer));
        ERC1967Proxy paymentProxy = new ERC1967Proxy(address(paymentImpl), paymentInitData);
        InvoicePayment payment = InvoicePayment(payable(address(paymentProxy)));
        console.log("InvoicePayment Proxy:", address(payment));
        console.log("InvoicePayment Implementation:", address(paymentImpl));

        // Initialize V2 on NFT
        nft.initializeV2(address(payment));

        // Deploy PaymentLink
        PaymentLink linkImpl = new PaymentLink();
        bytes memory linkInitData = abi.encodeCall(PaymentLink.initialize, (address(payment), address(nft), deployer));
        ERC1967Proxy linkProxy = new ERC1967Proxy(address(linkImpl), linkInitData);
        PaymentLink link = PaymentLink(payable(address(linkProxy)));
        console.log("PaymentLink Proxy:", address(link));
        console.log("PaymentLink Implementation:", address(linkImpl));

        // Configure USDC support (Base Mainnet USDC: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
        address usdcMainnet = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        payment.setSupportedToken(usdcMainnet, true);
        console.log("USDC support enabled:", usdcMainnet);

        vm.stopBroadcast();

        console.log("\n[PASS] Deployment complete");

        _saveDeployment("base-mainnet", address(nft), address(nftImpl), address(payment), address(paymentImpl), address(link), address(linkImpl), deployer);
    }

    function _saveDeployment(
        string memory network,
        address nftProxy,
        address nftImpl,
        address paymentProxy,
        address paymentImpl,
        address linkProxy,
        address linkImpl,
        address deployer
    ) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        vm.serializeString(json, "network", network);
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
