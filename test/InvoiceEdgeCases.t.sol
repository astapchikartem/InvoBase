// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract InvoiceEdgeCasesTest is Test {
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

    function testCannotPayDraftInvoice() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InvoiceNotIssued.selector);
        payment.payInvoice{value: 1 ether}(tokenId);
    }

    function testCannotPayDraftInvoiceWithToken() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        vm.expectRevert(InvoicePayment.InvoiceNotIssued.selector);
        payment.payInvoiceToken(tokenId, address(usdc), INVOICE_AMOUNT);
        vm.stopPrank();
    }

    function testCannotPayCancelledInvoice() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.cancel(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InvoiceCancelled.selector);
        payment.payInvoice{value: 1 ether}(tokenId);
    }

    function testCannotRecordExternalPaymentOnDraft() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");

        vm.prank(issuer);
        vm.expectRevert(InvoicePayment.InvoiceNotIssued.selector);
        payment.recordExternalPayment(tokenId, paymentRef);
    }

    function testCannotRecordExternalPaymentOnCancelled() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.cancel(tokenId);
        vm.stopPrank();

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");

        vm.prank(issuer);
        vm.expectRevert(InvoicePayment.InvoiceCancelled.selector);
        payment.recordExternalPayment(tokenId, paymentRef);
    }

    function testCannotRecordExternalPaymentTwice() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);

        bytes32 paymentRef1 = keccak256("BASE_PAY_TX_123");
        payment.recordExternalPayment(tokenId, paymentRef1);

        bytes32 paymentRef2 = keccak256("BASE_PAY_TX_456");
        vm.expectRevert(InvoicePayment.AlreadyRecorded.selector);
        payment.recordExternalPayment(tokenId, paymentRef2);
        vm.stopPrank();
    }

    function testCannotMarkDraftAsPaid() public {
        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);

        vm.prank(address(payment));
        vm.expectRevert(InvoiceNFTV2.InvoiceNotIssued.selector);
        nft.markAsPaid(tokenId);
    }

    function testCannotMarkCancelledAsPaid() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.cancel(tokenId);
        vm.stopPrank();

        vm.prank(address(payment));
        vm.expectRevert(InvoiceNFTV2.InvoiceNotIssued.selector);
        nft.markAsPaid(tokenId);
    }

    function testCannotMarkAlreadyPaidInvoice() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        vm.prank(address(payment));
        vm.expectRevert(InvoiceNFTV2.AlreadyPaid.selector);
        nft.markAsPaid(tokenId);
    }

    function testCannotModifyPartialPaymentAfterIssued() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.issue(tokenId);

        vm.expectRevert(InvoiceNFTV2.CannotModifyIssuedInvoice.selector);
        nft.setPartialPayment(tokenId, false);
        vm.stopPrank();
    }

    function testCannotModifyTokenAfterIssued() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.setInvoiceToken(tokenId, address(usdc));
        nft.issue(tokenId);

        MockERC20 dai = new MockERC20("DAI", "DAI", 18);
        vm.expectRevert(InvoiceNFTV2.CannotModifyIssuedInvoice.selector);
        nft.setInvoiceToken(tokenId, address(dai));
        vm.stopPrank();
    }

    function testRefundPartialPayments() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));
        vm.stopPrank();

        uint256 partialAmount = INVOICE_AMOUNT / 2;

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
        vm.stopPrank();

        uint256 payerBalanceBefore = usdc.balanceOf(payer);

        vm.startPrank(issuer);
        nft.cancel(tokenId);
        payment.refund(tokenId);
        vm.stopPrank();

        assertEq(usdc.balanceOf(payer), payerBalanceBefore + partialAmount);
        assertEq(payment.partialPaid(tokenId), 0);
    }

    function testCannotPayPartialOnDraft() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));
        vm.stopPrank();

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        vm.expectRevert(InvoicePayment.InvoiceNotIssued.selector);
        payment.payInvoicePartial{value: 0}(tokenId, INVOICE_AMOUNT / 2);
        vm.stopPrank();
    }

    function testCannotPayPartialOnCancelled() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));
        nft.issue(tokenId);
        nft.cancel(tokenId);
        vm.stopPrank();

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);
        vm.expectRevert(InvoicePayment.InvoiceCancelled.selector);
        payment.payInvoicePartial{value: 0}(tokenId, INVOICE_AMOUNT / 2);
        vm.stopPrank();
    }

    function testCompleteLifecycleWithPartialPayments() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(usdc));

        InvoiceNFTV2.Invoice memory invoiceAfterMint = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterMint.status), 0);

        nft.issue(tokenId);
        InvoiceNFTV2.Invoice memory invoiceAfterIssue = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterIssue.status), 1);
        vm.stopPrank();

        uint256 firstPayment = INVOICE_AMOUNT / 3;
        uint256 secondPayment = INVOICE_AMOUNT / 3;
        uint256 thirdPayment = INVOICE_AMOUNT - firstPayment - secondPayment;

        uint256 issuerBalanceBefore = usdc.balanceOf(issuer);

        vm.startPrank(payer);
        usdc.approve(address(payment), INVOICE_AMOUNT);

        payment.payInvoicePartial{value: 0}(tokenId, firstPayment);
        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT - firstPayment);
        assertFalse(payment.isPaid(tokenId));

        payment.payInvoicePartial{value: 0}(tokenId, secondPayment);
        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT - firstPayment - secondPayment);
        assertFalse(payment.isPaid(tokenId));

        payment.payInvoicePartial{value: 0}(tokenId, thirdPayment);
        assertEq(payment.getRemainingAmount(tokenId), 0);
        assertTrue(payment.isPaid(tokenId));
        vm.stopPrank();

        InvoiceNFTV2.Invoice memory invoiceAfterPayment = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterPayment.status), 2);
        assertEq(usdc.balanceOf(issuer), issuerBalanceBefore + INVOICE_AMOUNT);

        vm.prank(issuer);
        vm.expectRevert(InvoiceNFTV2.CannotCancelPaidInvoice.selector);
        nft.cancel(tokenId);
    }

    function testExternalPaymentAfterOnChainPaymentFails() public {
        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, 1 ether, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        vm.stopPrank();

        vm.prank(payer);
        payment.payInvoice{value: 1 ether}(tokenId);

        bytes32 paymentRef = keccak256("BASE_PAY_TX_123");

        vm.prank(issuer);
        vm.expectRevert(InvoicePayment.InvoiceAlreadyPaid.selector);
        payment.recordExternalPayment(tokenId, paymentRef);
    }
}
