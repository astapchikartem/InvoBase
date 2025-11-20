// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC721Upgradeable} from "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract InvoiceNFT is ERC721Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public invoiceManager;

    struct InvoiceReceipt {
        uint256 invoiceId;
        address issuer;
        address payer;
        uint256 amount;
        uint256 paidAt;
    }

    mapping(uint256 => InvoiceReceipt) public receipts;

    error UnauthorizedMinter();

    modifier onlyInvoiceManager() {
        if (msg.sender != invoiceManager) revert UnauthorizedMinter();
        _;
    }

    function initialize(address _invoiceManager, address owner) public initializer {
        __ERC721_init("InvoBase Receipt", "INVR");
        __Ownable_init(owner);
        __UUPSUpgradeable_init();
        invoiceManager = _invoiceManager;
    }

    function mint(
        address to,
        uint256 tokenId,
        uint256 invoiceId,
        address issuer,
        uint256 amount,
        uint256 paidAt
    ) external onlyInvoiceManager {
        _mint(to, tokenId);

        receipts[tokenId] = InvoiceReceipt({
            invoiceId: invoiceId,
            issuer: issuer,
            payer: to,
            amount: amount,
            paidAt: paidAt
        });
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _buildTokenURI(tokenId);
    }

    function _buildTokenURI(uint256 tokenId) internal view returns (string memory) {
        InvoiceReceipt memory receipt = receipts[tokenId];
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                _encode(
                    abi.encodePacked(
                        '{"name":"Invoice Receipt #',
                        _toString(receipt.invoiceId),
                        '","description":"Payment receipt for invoice #',
                        _toString(receipt.invoiceId),
                        '","attributes":[',
                        '{"trait_type":"Invoice ID","value":"',
                        _toString(receipt.invoiceId),
                        '"},',
                        '{"trait_type":"Amount","value":"',
                        _toString(receipt.amount),
                        '"}',
                        "]}"
                    )
                )
            )
        );
    }

    function _toString(uint256 value) internal pure returns (string memory) {
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

    function _encode(bytes memory data) internal pure returns (string memory) {
        bytes memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);
        bytes memory result = new bytes(encodedLen);

        uint256 i;
        uint256 j;
        for (i = 0; i < len - 2; i += 3) {
            result[j++] = table[uint8(data[i] >> 2)];
            result[j++] = table[uint8((uint8(data[i] & 0x03) << 4) | (uint8(data[i + 1]) >> 4))];
            result[j++] = table[uint8((uint8(data[i + 1] & 0x0f) << 2) | (uint8(data[i + 2]) >> 6))];
            result[j++] = table[uint8(data[i + 2] & 0x3f)];
        }

        if (len % 3 == 1) {
            result[j++] = table[uint8(data[len - 1] >> 2)];
            result[j++] = table[uint8(uint8(data[len - 1] & 0x03) << 4)];
        } else if (len % 3 == 2) {
            result[j++] = table[uint8(data[len - 2] >> 2)];
            result[j++] = table[uint8((uint8(data[len - 2] & 0x03) << 4) | (uint8(data[len - 1]) >> 4))];
            result[j++] = table[uint8(uint8(data[len - 1] & 0x0f) << 2)];
        }

        return string(result);
    }

    function setInvoiceManager(address _invoiceManager) external onlyOwner {
        invoiceManager = _invoiceManager;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
