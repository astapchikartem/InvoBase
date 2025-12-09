// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract InvoiceNFTv1Test is Test {
    InvoiceNFT public nft;
    address public owner;
    address public issuer;
    address public payer;

    function setUp() public {
        owner = address(this);
        issuer = makeAddr("issuer");
        payer = makeAddr("payer");

        InvoiceNFT implementation = new InvoiceNFT();
        bytes memory initData = abi.encodeCall(InvoiceNFT.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = InvoiceNFT(address(proxy));
    }

    function testMintInvoice() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);

        assertEq(tokenId, 1);
        assertEq(nft.ownerOf(tokenId), issuer);

        InvoiceNFT.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(invoice.issuer, issuer);
        assertEq(invoice.payer, payer);
        assertEq(invoice.amount, 1000e6);
        assertEq(uint256(invoice.status), uint256(InvoiceNFT.InvoiceStatus.Draft));

        vm.stopPrank();
    }

    function testIssueInvoice() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);
        nft.issue(tokenId);

        InvoiceNFT.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint256(invoice.status), uint256(InvoiceNFT.InvoiceStatus.Issued));

        vm.stopPrank();
    }

    function testMarkPaid() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);
        nft.issue(tokenId);

        vm.stopPrank();

        vm.prank(payer);
        nft.markPaid(tokenId);

        InvoiceNFT.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint256(invoice.status), uint256(InvoiceNFT.InvoiceStatus.Paid));
    }

    function testCancel() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);
        nft.cancel(tokenId);

        InvoiceNFT.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint256(invoice.status), uint256(InvoiceNFT.InvoiceStatus.Cancelled));

        vm.stopPrank();
    }

    function testTransferRestriction() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);

        vm.expectRevert(InvoiceNFT.UnauthorizedTransfer.selector);
        nft.transferFrom(issuer, payer, tokenId);

        vm.stopPrank();
    }

    function testUnauthorizedIssue() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);

        vm.prank(payer);
        vm.expectRevert(InvoiceNFT.Unauthorized.selector);
        nft.issue(tokenId);
    }

    function testInvalidStatusTransition() public {
        vm.startPrank(issuer);

        uint256 tokenId = nft.mint(payer, 1000e6, block.timestamp + 30 days);

        vm.expectRevert(InvoiceNFT.InvalidStatus.selector);
        nft.markPaid(tokenId);

        vm.stopPrank();
    }
}
