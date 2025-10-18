// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ArrayUtils
/// @notice Utility functions for array operations
library ArrayUtils {
    error EmptyArray();
    error IndexOutOfBounds();

    /// @notice Sums all elements in a uint256 array
    /// @param arr Array to sum
    /// @return total Sum of all elements
    function sum(uint256[] memory arr) internal pure returns (uint256 total) {
        for (uint256 i = 0; i < arr.length; i++) {
            total += arr[i];
        }
    }

    /// @notice Checks if an array contains a value
    /// @param arr Array to search
    /// @param value Value to find
    /// @return True if value exists
    function contains(uint256[] memory arr, uint256 value) internal pure returns (bool) {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == value) return true;
        }
        return false;
    }

    /// @notice Validates array is not empty
    /// @param arr Array to validate
    function requireNonEmpty(uint256[] memory arr) internal pure {
        if (arr.length == 0) revert EmptyArray();
    }

    /// @notice Validates array index is valid
    /// @param arr Array to validate
    /// @param index Index to check
    function requireValidIndex(uint256[] memory arr, uint256 index) internal pure {
        if (index >= arr.length) revert IndexOutOfBounds();
    }
}
