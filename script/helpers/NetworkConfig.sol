// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title NetworkConfig
/// @notice Network-specific configuration helper
library NetworkConfig {
    struct Config {
        address usdc;
        address weth;
        uint256 chainId;
        string name;
    }

    function getConfig() internal view returns (Config memory) {
        uint256 chainId = block.chainid;

        if (chainId == 8453) {
            return Config({
                usdc: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913,
                weth: 0x4200000000000000000000000000000000000006,
                chainId: 8453,
                name: "Base Mainnet"
            });
        } else if (chainId == 84532) {
            return Config({
                usdc: 0x036CbD53842c5426634e7929541eC2318f3dCF7e,
                weth: 0x4200000000000000000000000000000000000006,
                chainId: 84532,
                name: "Base Sepolia"
            });
        } else if (chainId == 31337) {
            return Config({
                usdc: address(0),
                weth: address(0),
                chainId: 31337,
                name: "Localhost"
            });
        } else {
            revert("Unsupported network");
        }
    }

    function isTestnet() internal view returns (bool) {
        uint256 chainId = block.chainid;
        return chainId == 84532 || chainId == 31337;
    }
}
