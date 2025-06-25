// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external returns (address) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying InvoiceManager with deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceManager implementation = new InvoiceManager();
        console.log("Implementation deployed at:", address(implementation));

        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            deployer
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        console.log("Proxy deployed at:", address(proxy));

        InvoiceManager invoiceManager = InvoiceManager(address(proxy));

        console.log("Owner:", deployer);
        console.log("Deployment complete!");

        vm.stopBroadcast();

        return address(proxy);
    }
}
