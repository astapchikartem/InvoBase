// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title MathUtils
/// @notice Math utility functions
library MathUtils {
    /// @notice Calculates percentage of a value
    /// @param value Base value
    /// @param percentage Percentage in basis points (100 = 1%)
    /// @return Result
    function percentageOf(uint256 value, uint256 percentage) internal pure returns (uint256) {
        return (value * percentage) / 10000;
    }

    /// @notice Safely adds with overflow check
    /// @param a First number
    /// @param b Second number
    /// @return Sum
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    /// @notice Calculates minimum of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return Minimum value
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Calculates maximum of two numbers
    /// @param a First number
    /// @param b Second number
    /// @return Maximum value
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }
}
