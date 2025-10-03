// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title AddressUtils
/// @notice Address validation and utility functions
library AddressUtils {
    error ZeroAddress();
    error InvalidAddress();

    /// @notice Validates address is not zero
    /// @param addr Address to validate
    function requireNonZero(address addr) internal pure {
        if (addr == address(0)) revert ZeroAddress();
    }

    /// @notice Checks if address is a contract
    /// @param addr Address to check
    /// @return True if contract
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /// @notice Validates address is a contract
    /// @param addr Address to validate
    function requireContract(address addr) internal view {
        if (!isContract(addr)) revert InvalidAddress();
    }
}
