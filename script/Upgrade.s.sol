// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract UpgradeScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        console.log("Upgrading InvoiceManager at proxy:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceManager newImplementation = new InvoiceManager();
        console.log("New implementation deployed at:", address(newImplementation));

        InvoiceManager proxy = InvoiceManager(proxyAddress);
        proxy.upgradeToAndCall(address(newImplementation), "");

        console.log("Upgrade complete!");

        vm.stopBroadcast();
    }
}
