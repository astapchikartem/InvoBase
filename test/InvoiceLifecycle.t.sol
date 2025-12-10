// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract InvoiceLifecycleTest is Test {
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

    function testCannotIssueFromCancelled() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        nft.cancel(tokenId);

        vm.expectRevert(InvoiceNFTV2.InvalidTransition.selector);
        nft.issue(tokenId);
        vm.stopPrank();
    }

    function testCannotCancelPaidInvoice() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        vm.prank(issuer);
        vm.expectRevert(InvoiceNFTV2.CannotCancelPaidInvoice.selector);
        nft.cancel(tokenId);
    }

    function testCannotCancelAlreadyCancelled() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.cancel(tokenId);

        vm.expectRevert(InvoiceNFTV2.InvalidTransition.selector);
        nft.cancel(tokenId);
        vm.stopPrank();
    }

    function testOverpaymentReverts() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.Overpayment.selector);
        payment.payInvoice{value: 1.5 ether}(tokenId);
    }

    function testOverpaymentTokenReverts() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT + 100e6);
        vm.expectRevert(InvoicePayment.Overpayment.selector);
        payment.payInvoiceToken(tokenId, address(usdc), INVOICE_AMOUNT + 100e6);
        vm.stopPrank();
    }

    function testPartialPaymentOverpaymentReverts() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));
        vm.stopPrank();

        uint256 firstPayment = INVOICE_AMOUNT / 2;
        uint256 secondPayment = INVOICE_AMOUNT / 2 + 100e6;

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT * 2);
        payment.payInvoicePartial{value: 0}(tokenId, firstPayment);

        vm.expectRevert(InvoicePayment.Overpayment.selector);
        payment.payInvoicePartial{value: 0}(tokenId, secondPayment);
        vm.stopPrank();
    }

    function testPaymentUpdatesNFTStatus() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        InvoiceNFTV2.Invoice memory invoiceBefore = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceBefore.status), 1); // Issued

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        InvoiceNFTV2.Invoice memory invoiceAfter = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfter.status), 2); // Paid
    }

    function testExternalPaymentUpdatesNFTStatus() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");
        payment.recordExternalPayment(tokenId, paymentRef);
        vm.stopPrank();

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint8(invoice.status), 2); // Paid
        assertTrue(payment.isPaid(tokenId));
    }

    function testPartialPaymentCompletionUpdatesStatus() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));
        vm.stopPrank();

        uint256 firstPayment = INVOICE_AMOUNT / 2;
        uint256 secondPayment = INVOICE_AMOUNT / 2;

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, firstPayment);

        InvoiceNFTV2.Invoice memory invoiceAfterFirst = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterFirst.status), 1); // Still Issued

        payment.payInvoicePartial{value: 0}(tokenId, secondPayment);
        vm.stopPrank();

        InvoiceNFTV2.Invoice memory invoiceAfterSecond = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterSecond.status), 2); // Now Paid
    }

    function testCancelWithNoPaymentSucceeds() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);

        nft.cancel(tokenId);

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint8(invoice.status), 3); // Cancelled
        vm.stopPrank();
    }

    function testCannotIssueNonDraftInvoice() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);

        vm.expectRevert(InvoiceNFTV2.InvalidTransition.selector);
        nft.issue(tokenId);
        vm.stopPrank();
    }

    function testOnlyPaymentProcessorCanMarkAsPaid() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(issuer);
        nft.issue(tokenId);

        vm.prank(payer);
        vm.expectRevert(InvoiceNFTV2.Unauthorized.selector);
        nft.markAsPaid(tokenId);
    }

    function testPartialPaymentFlagReadFromNFT() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.PartialPaymentNotAllowed.selector);
        payment.payInvoicePartial{value: 0}(tokenId, INVOICE_AMOUNT / 2);

        vm.prank(issuer);
        nft.setPartialPayment(tokenId, true);

        vm.prank(issuer);
        nft.setInvoiceToken(tokenId, address(usdc));

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, INVOICE_AMOUNT / 2);
        vm.stopPrank();
    }
}
