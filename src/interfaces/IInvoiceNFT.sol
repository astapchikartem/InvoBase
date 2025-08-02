// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title IInvoiceNFT
/// @notice Interface for the InvoiceNFT contract
interface IInvoiceNFT is IERC721 {
    struct InvoiceReceipt {
        uint256 invoiceId;
        address issuer;
        address payer;
        uint256 amount;
        uint256 paidAt;
    }

    /// @notice Mints a new receipt NFT
    /// @param to Recipient address
    /// @param tokenId Token ID to mint
    /// @param invoiceId Associated invoice ID
    /// @param issuer Invoice issuer address
    /// @param amount Payment amount
    /// @param paidAt Timestamp when paid
    function mint(
        address to,
        uint256 tokenId,
        uint256 invoiceId,
        address issuer,
        uint256 amount,
        uint256 paidAt
    ) external;

    /// @notice Gets receipt data for a token
    /// @param tokenId Token ID to query
    /// @return Receipt data
    function receipts(uint256 tokenId) external view returns (InvoiceReceipt memory);

    /// @notice Updates the invoice manager address
    /// @param _invoiceManager New invoice manager address
    function setInvoiceManager(address _invoiceManager) external;
}
