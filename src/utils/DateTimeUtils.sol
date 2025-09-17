// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title DateTimeUtils
/// @notice Utilities for date and time calculations
library DateTimeUtils {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;

    /// @notice Adds days to a timestamp
    /// @param timestamp Base timestamp
    /// @param daysToAdd Number of days to add
    /// @return New timestamp
    function addDays(uint256 timestamp, uint256 daysToAdd) internal pure returns (uint256) {
        return timestamp + (daysToAdd * SECONDS_PER_DAY);
    }

    /// @notice Calculates days between two timestamps
    /// @param from Start timestamp
    /// @param to End timestamp
    /// @return Number of days
    function daysBetween(uint256 from, uint256 to) internal pure returns (uint256) {
        if (to <= from) return 0;
        return (to - from) / SECONDS_PER_DAY;
    }

    /// @notice Checks if a timestamp is in the past
    /// @param timestamp Timestamp to check
    /// @return True if in the past
    function isPast(uint256 timestamp) internal view returns (bool) {
        return timestamp < block.timestamp;
    }

    /// @notice Checks if a timestamp is in the future
    /// @param timestamp Timestamp to check
    /// @return True if in the future
    function isFuture(uint256 timestamp) internal view returns (bool) {
        return timestamp > block.timestamp;
    }

    /// @notice Gets the start of day for a timestamp
    /// @param timestamp Input timestamp
    /// @return Start of day timestamp
    function startOfDay(uint256 timestamp) internal pure returns (uint256) {
        return (timestamp / SECONDS_PER_DAY) * SECONDS_PER_DAY;
    }
}
