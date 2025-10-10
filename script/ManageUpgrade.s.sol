// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {InvoiceManagerV2} from "../src/InvoiceManagerV2.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title ManageUpgrade
/// @notice Script for managing contract upgrades
contract ManageUpgrade is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("INVOICE_MANAGER_PROXY");

        console.log("Upgrading InvoiceManager...");
        console.log("Proxy address:", proxyAddress);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new implementation
        InvoiceManagerV2 newImpl = new InvoiceManagerV2();
        console.log("New implementation:", address(newImpl));

        // Upgrade proxy
        InvoiceManager proxy = InvoiceManager(proxyAddress);
        proxy.upgradeToAndCall(address(newImpl), "");

        console.log("Upgrade complete!");

        // Verify upgrade
        console.log("Current implementation:", _getImplementation(proxyAddress));

        vm.stopBroadcast();
    }

    function _getImplementation(address proxy) internal view returns (address) {
        bytes32 slot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        return address(uint160(uint256(vm.load(proxy, slot))));
    }
}
