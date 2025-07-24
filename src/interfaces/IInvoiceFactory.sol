// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInvoiceFactory {
    function createInvoiceFromTemplate(
        bytes32 templateId,
        address payer
    ) external returns (uint256);

    function createTemplate(
        string calldata name,
        uint256 amount,
        address asset,
        string calldata metadata
    ) external returns (bytes32);
}
