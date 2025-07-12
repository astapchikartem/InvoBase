// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract SmartWalletHooks {
    mapping(address => bool) public registeredSmartWallets;
    mapping(address => address) public walletOwners;

    event SmartWalletRegistered(address indexed wallet, address indexed owner);
    event SmartWalletRemoved(address indexed wallet);

    function registerSmartWallet(address wallet, address owner) external {
        require(!registeredSmartWallets[wallet], "Already registered");
        registeredSmartWallets[wallet] = true;
        walletOwners[wallet] = owner;
        emit SmartWalletRegistered(wallet, owner);
    }

    function removeSmartWallet(address wallet) external {
        require(walletOwners[wallet] == msg.sender, "Unauthorized");
        registeredSmartWallets[wallet] = false;
        delete walletOwners[wallet];
        emit SmartWalletRemoved(wallet);
    }

    function isSmartWallet(address wallet) external view returns (bool) {
        return registeredSmartWallets[wallet];
    }

    function getWalletOwner(address wallet) external view returns (address) {
        return walletOwners[wallet];
    }
}
