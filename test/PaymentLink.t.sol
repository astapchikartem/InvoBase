// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract PaymentLinkTest is Test {
    InvoiceNFTV2 public nft;
    InvoicePayment public payment;
    PaymentLink public paymentLink;
    MockERC20 public usdc;

    address public owner;
    address public issuer;
    address public payer;
    address public stranger;

    uint256 constant INVOICE_AMOUNT = 1000e6;
    uint256 constant DUE_DATE_OFFSET = 30 days;

    function setUp() public {
        owner = address(this);
        issuer = makeAddr("issuer");
        payer = makeAddr("payer");
        stranger = makeAddr("stranger");

        InvoiceNFTV2 implementation = new InvoiceNFTV2();
        bytes memory initData = abi.encodeCall(InvoiceNFTV2.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = InvoiceNFTV2(address(proxy));

        payment = new InvoicePayment(address(nft), owner);
        nft.initializeV2(address(payment));

        paymentLink = new PaymentLink(address(payment), address(nft), owner);

        usdc = new MockERC20("USD Coin", "USDC", 6);
        payment.setSupportedToken(address(usdc), true);

        vm.deal(payer, 100 ether);
        vm.deal(stranger, 100 ether);
        usdc.mint(payer, 10000e6);
        usdc.mint(stranger, 10000e6);
    }

    function testGenerateLink() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        assertTrue(linkId != bytes32(0));
        assertTrue(paymentLink.isLinkValid(linkId));

        PaymentLink.Link memory link = paymentLink.getLink(linkId);
        assertEq(link.invoiceId, tokenId);
        assertEq(link.expiry, expiry);
        assertFalse(link.used);
    }

    function testPayViaLinkWithETH() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        uint256 issuerBalanceBefore = issuer.balance;

        vm.prank(stranger);
        paymentLink.payViaLink{value: 1 ether}(linkId);

        assertEq(issuer.balance, issuerBalanceBefore + 1 ether);
        assertTrue(payment.isPaid(tokenId));

        PaymentLink.Link memory link = paymentLink.getLink(linkId);
        assertTrue(link.used);
        assertFalse(paymentLink.isLinkValid(linkId));
    }

    function testPayViaLinkWithToken() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        uint256 issuerBalanceBefore = usdc.balanceOf(issuer);

        vm.startPrank(stranger);
        usdc.approve(address(paymentLink), INVOICE_AMOUNT);
        paymentLink.payViaLinkToken(linkId, address(usdc), INVOICE_AMOUNT);
        vm.stopPrank();

        assertEq(usdc.balanceOf(issuer), issuerBalanceBefore + INVOICE_AMOUNT);
        assertTrue(payment.isPaid(tokenId));

        PaymentLink.Link memory link = paymentLink.getLink(linkId);
        assertTrue(link.used);
    }

    function testCannotPayExpiredLink() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        vm.warp(expiry + 1);

        assertFalse(paymentLink.isLinkValid(linkId));

        vm.prank(stranger);
        vm.expectRevert(PaymentLink.LinkExpired.selector);
        paymentLink.payViaLink{value: 1 ether}(linkId);
    }

    function testCannotPayUsedLink() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        vm.prank(stranger);
        paymentLink.payViaLink{value: 1 ether}(linkId);

        vm.prank(stranger);
        vm.expectRevert(PaymentLink.LinkAlreadyUsed.selector);
        paymentLink.payViaLink{value: 1 ether}(linkId);
    }

    function testCannotPayNonexistentLink() public {
        bytes32 fakeLink = keccak256("fake");

        vm.prank(stranger);
        vm.expectRevert(PaymentLink.LinkNotFound.selector);
        paymentLink.payViaLink{value: 1 ether}(fakeLink);
    }

    function testOnlyIssuerCanGenerateLink() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(payer);
        vm.expectRevert(PaymentLink.Unauthorized.selector);
        paymentLink.generateLink(tokenId, expiry);
    }

    function testInsufficientPaymentViaLink() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        vm.prank(stranger);
        vm.expectRevert(PaymentLink.InsufficientPayment.selector);
        paymentLink.payViaLink{value: 0.5 ether}(linkId);
    }

    function testGetLinkByInvoice() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        PaymentLink.Link memory link = paymentLink.getLinkByInvoice(tokenId);
        assertEq(link.linkId, linkId);
        assertEq(link.invoiceId, tokenId);
    }

    function testLinkValidityChecks() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        uint256 expiry = block.timestamp + 7 days;

        vm.prank(issuer);
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);

        assertTrue(paymentLink.isLinkValid(linkId));

        vm.warp(expiry + 1);
        assertFalse(paymentLink.isLinkValid(linkId));
    }

    function testMultipleLinksForDifferentInvoices() public {
        vm.startPrank(issuer);
        uint256 tokenId1 = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        uint256 tokenId2 = nft.mint(payer, 2 ether, block.timestamp + DUE_DATE_OFFSET);

        uint256 expiry = block.timestamp + 7 days;

        bytes32 linkId1 = paymentLink.generateLink(tokenId1, expiry);
        bytes32 linkId2 = paymentLink.generateLink(tokenId2, expiry);
        vm.stopPrank();

        assertTrue(linkId1 != linkId2);
        assertTrue(paymentLink.isLinkValid(linkId1));
        assertTrue(paymentLink.isLinkValid(linkId2));

        PaymentLink.Link memory link1 = paymentLink.getLink(linkId1);
        PaymentLink.Link memory link2 = paymentLink.getLink(linkId2);

        assertEq(link1.invoiceId, tokenId1);
        assertEq(link2.invoiceId, tokenId2);
    }
}
