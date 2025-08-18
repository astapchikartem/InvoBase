// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ReentrancyCheck
/// @notice Additional reentrancy protection utilities
library ReentrancyCheck {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    error ReentrancyDetected();

    /// @notice Checks if a call is reentrant
    /// @param status Current status flag
    /// @return bool True if reentrant
    function isReentrant(uint256 status) internal pure returns (bool) {
        return status == ENTERED;
    }

    /// @notice Validates no reentrancy
    /// @param status Current status flag
    function validateNoReentrancy(uint256 status) internal pure {
        if (status == ENTERED) revert ReentrancyDetected();
    }
}
