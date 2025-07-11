// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFT} from "../src/InvoiceNFT.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract InvoiceNFTTest is Test {
    InvoiceNFT public nft;
    address public owner = address(0x1);
    address public invoiceManager = address(0x2);
    address public user = address(0x3);

    function setUp() public {
        InvoiceNFT implementation = new InvoiceNFT();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceNFT.initialize.selector,
            invoiceManager,
            owner
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = InvoiceNFT(address(proxy));
    }

    function testMintNFT() public {
        vm.prank(invoiceManager);
        nft.mint(user, 1, 1, owner, 1000e6, block.timestamp);

        assertEq(nft.ownerOf(1), user);
        assertEq(nft.balanceOf(user), 1);
    }

    function testRevertUnauthorizedMint() public {
        vm.prank(user);
        vm.expectRevert(InvoiceNFT.UnauthorizedMinter.selector);
        nft.mint(user, 1, 1, owner, 1000e6, block.timestamp);
    }

    function testReceiptData() public {
        uint256 amount = 1000e6;
        uint256 paidAt = block.timestamp;

        vm.prank(invoiceManager);
        nft.mint(user, 1, 1, owner, amount, paidAt);

        (uint256 invoiceId, address issuer, address payer, uint256 amt, uint256 paid) = nft
            .receipts(1);

        assertEq(invoiceId, 1);
        assertEq(issuer, owner);
        assertEq(payer, user);
        assertEq(amt, amount);
        assertEq(paid, paidAt);
    }
}
