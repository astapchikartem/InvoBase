// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {InvoiceFactory} from "../src/InvoiceFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployTestnet is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying to testnet...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy InvoiceManager implementation
        InvoiceManager managerImpl = new InvoiceManager();
        console.log("InvoiceManager implementation:", address(managerImpl));

        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            deployer
        );
        ERC1967Proxy managerProxy = new ERC1967Proxy(address(managerImpl), initData);
        console.log("InvoiceManager proxy:", address(managerProxy));

        // Deploy InvoiceNFT
        InvoiceNFT nftImpl = new InvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(
            InvoiceNFT.initialize.selector,
            address(managerProxy),
            deployer
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        console.log("InvoiceNFT proxy:", address(nftProxy));

        // Deploy Factory
        InvoiceFactory factory = new InvoiceFactory();
        console.log("InvoiceFactory:", address(factory));

        vm.stopBroadcast();

        console.log("\nDeployment complete!");
    }
}
