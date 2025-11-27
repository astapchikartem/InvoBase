// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployInvoiceNFT is Script {
    function run() external returns (address proxy, address implementation) {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        implementation = address(new InvoiceNFT());

        bytes memory initData = abi.encodeCall(InvoiceNFT.initialize, (deployer));
        proxy = address(new ERC1967Proxy(implementation, initData));

        vm.stopBroadcast();

        console.log("Implementation deployed at:", implementation);
        console.log("Proxy deployed at:", proxy);
        console.log("Owner:", deployer);

        return (proxy, implementation);
    }
}
