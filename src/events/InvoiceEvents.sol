// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library InvoiceEvents {
    event InvoiceCreated(
        uint256 indexed id,
        address indexed issuer,
        address indexed payer,
        uint256 amount,
        address asset,
        uint256 timestamp
    );

    event InvoiceUpdated(uint256 indexed id, string field, bytes oldValue, bytes newValue);

    event InvoiceMetadataUpdated(uint256 indexed id, string newMetadata);

    event InvoiceAmountAdjusted(uint256 indexed id, uint256 oldAmount, uint256 newAmount);
}
