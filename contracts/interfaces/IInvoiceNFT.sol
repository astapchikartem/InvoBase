// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInvoiceNFT {
    function markAsPaid(uint256 tokenId) external;
    
    function getInvoice(uint256 tokenId) external view returns (
        uint256 id,
        address creator,
        address recipient,
        uint256 amount,
        address paymentToken,
        string memory description,
        uint256 dueDate,
        uint8 status,
        uint256 createdAt,
        uint256 paidAt
    );
}
