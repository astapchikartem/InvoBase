// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract InvoiceNFTExtendedTest is Test {
    InvoiceNFT public nft;

    address public owner = address(0x1);
    address public invoiceManager = address(0x2);
    address public user1 = address(0x3);

    function setUp() public {
        InvoiceNFT impl = new InvoiceNFT();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceNFT.initialize.selector,
            invoiceManager,
            owner
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        nft = InvoiceNFT(address(proxy));
    }

    function testMintReceipt() public {
        vm.prank(invoiceManager);
        nft.mint(user1, 1, 100, address(0x123), 1000e6, block.timestamp);

        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.balanceOf(user1), 1);
    }

    function testReceiptMetadata() public {
        vm.prank(invoiceManager);
        nft.mint(user1, 1, 100, address(0x123), 1000e6, block.timestamp);

        (uint256 invoiceId, address issuer, address payer, uint256 amount, uint256 paidAt) =
            nft.receipts(1);

        assertEq(invoiceId, 100);
        assertEq(issuer, address(0x123));
        assertEq(payer, user1);
        assertEq(amount, 1000e6);
        assertEq(paidAt, block.timestamp);
    }

    function testTokenURI() public {
        vm.prank(invoiceManager);
        nft.mint(user1, 1, 100, address(0x123), 1000e6, block.timestamp);

        string memory uri = nft.tokenURI(1);
        assertTrue(bytes(uri).length > 0);
    }

    function testUnauthorizedMint() public {
        vm.prank(user1);
        vm.expectRevert(InvoiceNFT.UnauthorizedMinter.selector);
        nft.mint(user1, 1, 100, address(0x123), 1000e6, block.timestamp);
    }

    function testUpdateInvoiceManager() public {
        address newManager = address(0x999);

        vm.prank(owner);
        nft.setInvoiceManager(newManager);

        assertEq(nft.invoiceManager(), newManager);
    }
}
