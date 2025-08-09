// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title GasOptimizer
/// @notice Gas optimization utilities for invoice operations
library GasOptimizer {
    /// @notice Packs invoice status and timestamps into single storage slot
    /// @param status Invoice status (1 byte)
    /// @param createdAt Creation timestamp (4 bytes)
    /// @param dueDate Due date timestamp (4 bytes)
    /// @param paidAt Payment timestamp (4 bytes)
    /// @return packed Packed uint256 value
    function packInvoiceData(
        uint8 status,
        uint32 createdAt,
        uint32 dueDate,
        uint32 paidAt
    ) internal pure returns (uint256 packed) {
        packed = uint256(status);
        packed |= uint256(createdAt) << 8;
        packed |= uint256(dueDate) << 40;
        packed |= uint256(paidAt) << 72;
    }

    /// @notice Unpacks invoice data from single storage slot
    /// @param packed Packed uint256 value
    /// @return status Invoice status
    /// @return createdAt Creation timestamp
    /// @return dueDate Due date timestamp
    /// @return paidAt Payment timestamp
    function unpackInvoiceData(uint256 packed)
        internal
        pure
        returns (uint8 status, uint32 createdAt, uint32 dueDate, uint32 paidAt)
    {
        status = uint8(packed);
        createdAt = uint32(packed >> 8);
        dueDate = uint32(packed >> 40);
        paidAt = uint32(packed >> 72);
    }
}
