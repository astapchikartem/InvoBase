// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract DeployToBaseSepolia is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceNFT implementation = new InvoiceNFT();
        bytes memory initData = abi.encodeCall(InvoiceNFT.initialize, (deployer));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        console.log("=== Base Sepolia Deployment ===");
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner:", deployer);
        console.log("Chain ID:", block.chainid);

        _saveDeployment("base-sepolia", address(proxy), address(implementation), deployer);
    }

    function _saveDeployment(string memory network, address proxy, address implementation, address deployer) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("proxy", proxy);
        json.serialize("implementation", implementation);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}

contract DeployToBaseMainnet is Script {
    using stdJson for string;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        vm.startBroadcast(deployerPrivateKey);

        InvoiceNFT implementation = new InvoiceNFT();
        bytes memory initData = abi.encodeCall(InvoiceNFT.initialize, (deployer));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);

        vm.stopBroadcast();

        console.log("=== Base Mainnet Deployment ===");
        console.log("Implementation:", address(implementation));
        console.log("Proxy:", address(proxy));
        console.log("Owner:", deployer);
        console.log("Chain ID:", block.chainid);

        _saveDeployment("base-mainnet", address(proxy), address(implementation), deployer);
    }

    function _saveDeployment(string memory network, address proxy, address implementation, address deployer) internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", network, ".json");

        string memory json = "deployment";
        json.serialize("network", network);
        json.serialize("proxy", proxy);
        json.serialize("implementation", implementation);
        json.serialize("deployer", deployer);
        json.serialize("chainId", block.chainid);
        json.serialize("blockNumber", block.number);
        string memory finalJson = json.serialize("timestamp", block.timestamp);

        vm.writeJson(finalJson, path);
    }
}
