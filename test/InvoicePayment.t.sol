// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract InvoicePaymentTest is Test {
    InvoiceNFTV2 public nft;
    InvoicePayment public payment;
    MockERC20 public usdc;

    address public owner;
    address public issuer;
    address public payer;

    uint256 constant INVOICE_AMOUNT = 1000e6;
    uint256 constant DUE_DATE_OFFSET = 30 days;

    function setUp() public {
        owner = address(this);
        issuer = makeAddr("issuer");
        payer = makeAddr("payer");

        InvoiceNFTV2 implementation = new InvoiceNFTV2();
        bytes memory initData = abi.encodeCall(InvoiceNFTV2.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = InvoiceNFTV2(address(proxy));

        payment = new InvoicePayment(address(nft), owner);
        nft.initializeV2(address(payment));

        usdc = new MockERC20("USD Coin", "USDC", 6);
        payment.setSupportedToken(address(usdc), true);

        vm.deal(payer, 100 ether);
        usdc.mint(payer, 10000e6);
    }

    function testPayInvoiceWithETH() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 issuerBalanceBefore = issuer.balance;

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        assertEq(issuer.balance, issuerBalanceBefore + 1 ether);
        assertTrue(payment.isPaid(tokenId));

        InvoicePayment.PaymentInfo memory paymentInfo = payment.getPaymentInfo(tokenId);
        assertEq(paymentInfo.invoiceId, tokenId);
        assertEq(paymentInfo.token, address(0));
        assertEq(paymentInfo.amountPaid, 1 ether);
        assertEq(paymentInfo.paidBy, payer);
    }

    function testPayInvoiceWithToken() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 issuerBalanceBefore = usdc.balanceOf(issuer);

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoiceToken(tokenId, address(usdc), INVOICE_AMOUNT);
        vm.stopPrank();

        assertEq(usdc.balanceOf(issuer), issuerBalanceBefore + INVOICE_AMOUNT);
        assertTrue(payment.isPaid(tokenId));

        InvoicePayment.PaymentInfo memory paymentInfo = payment.getPaymentInfo(tokenId);
        assertEq(paymentInfo.token, address(usdc));
        assertEq(paymentInfo.amountPaid, INVOICE_AMOUNT);
    }

    function testPartialPayment() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.setPartialPayment(tokenId, true);

        vm.prank(issuer);
        nft.setInvoiceToken(tokenId, address(usdc));

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 partialAmount = INVOICE_AMOUNT / 2;

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
        vm.stopPrank();

        assertEq(payment.partialPaid(tokenId), partialAmount);
        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT - partialAmount);
        assertFalse(payment.isPaid(tokenId));

        vm.startPrank(payer);
        payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
        vm.stopPrank();

        assertEq(payment.partialPaid(tokenId), INVOICE_AMOUNT);
        assertEq(payment.getRemainingAmount(tokenId), 0);
        assertTrue(payment.isPaid(tokenId));
    }

    function testRecordExternalPayment() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");

        vm.prank(issuer);
        payment.recordExternalPayment(tokenId, paymentRef);

        assertTrue(payment.isPaid(tokenId));

        InvoicePayment.PaymentInfo memory paymentInfo = payment.getPaymentInfo(tokenId);
        assertEq(paymentInfo.paymentRef, paymentRef);
        assertEq(paymentInfo.amountPaid, INVOICE_AMOUNT);
    }

    function testCannotPayTwice() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InvoiceAlreadyPaid.selector);
        payment.payInvoice{value: 1 ether}(tokenId);
    }

    function testCannotPayUnsupportedToken() public {
        MockERC20 unsupportedToken = new MockERC20("Unsupported", "UNSUP", 18);

        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.TokenNotSupported.selector);
        payment.payInvoiceToken(tokenId, address(unsupportedToken), INVOICE_AMOUNT);
    }

    function testCannotPartialPaymentWhenNotAllowed() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.PartialPaymentNotAllowed.selector);
        payment.payInvoicePartial{value: 0}(tokenId, INVOICE_AMOUNT / 2);
    }

    function testOnlyIssuerCanSetPartialPayment() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.Unauthorized.selector);
        nft.setPartialPayment(tokenId, true);
    }

    function testOnlyIssuerCanRecordExternalPayment() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.Unauthorized.selector);
        payment.recordExternalPayment(tokenId, paymentRef);
    }

    function testInsufficientPayment() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InsufficientPayment.selector);
        payment.payInvoice{value: 0.5 ether}(tokenId);
    }

    function testGetRemainingAmount() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT);

        vm.prank(issuer);
        nft.setPartialPayment(tokenId, true);

        vm.prank(issuer);
        nft.setInvoiceToken(tokenId, address(usdc));

        vm.prank(issuer);
        nft.issue(tokenId);

        uint256 partialAmount = INVOICE_AMOUNT / 4;

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
        vm.stopPrank();

        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT - partialAmount);
    }
}
