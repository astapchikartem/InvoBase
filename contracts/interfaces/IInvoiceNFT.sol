// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInvoiceNFT {
    function markAsPaid(uint256 tokenId) external;
}
