// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title StringUtils
/// @notice String manipulation utilities
library StringUtils {
    /// @notice Converts uint256 to string
    /// @param value The value to convert
    /// @return String representation
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }

        return string(buffer);
    }

    /// @notice Converts address to string
    /// @param addr The address to convert
    /// @return String representation
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }

    /// @notice Converts bytes32 to hex string
    /// @param value The value to convert
    /// @param length The length in bytes
    /// @return String representation
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
}
