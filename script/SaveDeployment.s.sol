// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract SaveDeployment is Script {
    using stdJson for string;

    function saveDeployment(string memory network, address proxy, address implementation, address deployer) public {
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

        console.log("Deployment metadata saved to:", path);
    }
}
