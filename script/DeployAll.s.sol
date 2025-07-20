// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {InvoiceBatchOperations} from "../src/InvoiceBatchOperations.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployAllScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying all contracts...");

        vm.startBroadcast(deployerPrivateKey);

        InvoiceManager managerImpl = new InvoiceManager();
        bytes memory managerInit = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            deployer
        );
        ERC1967Proxy managerProxy = new ERC1967Proxy(address(managerImpl), managerInit);
        console.log("InvoiceManager:", address(managerProxy));

        InvoiceNFT nftImpl = new InvoiceNFT();
        bytes memory nftInit = abi.encodeWithSelector(
            InvoiceNFT.initialize.selector,
            address(managerProxy),
            deployer
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInit);
        console.log("InvoiceNFT:", address(nftProxy));

        InvoiceBatchOperations batchOps = new InvoiceBatchOperations(address(managerProxy));
        console.log("BatchOperations:", address(batchOps));

        console.log("Deployment complete!");

        vm.stopBroadcast();
    }
}
