// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title BaseSepoliaIntegration
 * @notice On-chain integration tests for InvoBase V2 on Base Sepolia
 * @dev Run with: forge test --match-contract BaseSepoliaIntegration --fork-url $BASE_SEPOLIA_RPC
 */
contract BaseSepoliaIntegration is Test {
    InvoiceNFTV2 public nft;
    InvoicePayment public payment;
    PaymentLink public paymentLink;

    address public owner;
    address public issuer;
    address public payer;

    // Base Sepolia USDC: 0x036CbD53842c5426634e7929541eC2318f3dCF7e
    IERC20 public constant USDC = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);

    uint256 constant INVOICE_AMOUNT_ETH = 0.001 ether;
    uint256 constant INVOICE_AMOUNT_USDC = 10e6; // 10 USDC
    uint256 constant DUE_DATE_OFFSET = 30 days;

    function setUp() public {
        owner = address(this);
        issuer = makeAddr("issuer");
        payer = makeAddr("payer");

        // Deploy contracts
        InvoiceNFTV2 implementation = new InvoiceNFTV2();
        bytes memory initData = abi.encodeCall(InvoiceNFTV2.initialize, (owner));
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        nft = InvoiceNFTV2(address(proxy));

        payment = new InvoicePayment(address(nft), owner);
        nft.initializeV2(address(payment));

        paymentLink = new PaymentLink(address(payment), address(nft), owner);

        // Configure USDC support
        payment.setSupportedToken(address(USDC), true);

        // Fund test accounts
        vm.deal(issuer, 10 ether);
        vm.deal(payer, 10 ether);

        console.log("=== Base Sepolia Integration Test Setup ===");
        console.log("InvoiceNFTV2:", address(nft));
        console.log("InvoicePayment:", address(payment));
        console.log("PaymentLink:", address(paymentLink));
        console.log("USDC:", address(USDC));
    }

    function testFullLifecycleETHPayment() public {
        console.log("\n=== Test: Full Lifecycle - ETH Payment ===");

        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_ETH, block.timestamp + DUE_DATE_OFFSET);
        console.log("Invoice minted:", tokenId);

        InvoiceNFTV2.Invoice memory invoiceAfterMint = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterMint.status), 0, "Should be Draft");

        nft.issue(tokenId);
        console.log("Invoice issued:", tokenId);

        InvoiceNFTV2.Invoice memory invoiceAfterIssue = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterIssue.status), 1, "Should be Issued");
        vm.stopPrank();

        uint256 issuerBalanceBefore = issuer.balance;

        vm.prank(payer);
        payment.payInvoice{value: INVOICE_AMOUNT_ETH}(tokenId);
        console.log("Payment sent by payer");

        InvoiceNFTV2.Invoice memory invoiceAfterPayment = nft.getInvoice(tokenId);
        assertEq(uint8(invoiceAfterPayment.status), 2, "Should be Paid");

        assertEq(issuer.balance, issuerBalanceBefore + INVOICE_AMOUNT_ETH, "Issuer should receive payment");
        assertTrue(payment.isPaid(tokenId), "Invoice should be marked as paid");

        console.log("[PASS] Invoice lifecycle completed successfully");
        console.log("  Issuer received:", INVOICE_AMOUNT_ETH);
    }

    function testPartialPaymentLifecycle() public {
        console.log("\n=== Test: Partial Payment Lifecycle ===");

        // Get USDC for payer (in real scenario, payer would have USDC)
        // For testing, we'll deal some USDC if we're on a fork
        deal(address(USDC), payer, 100e6);

        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_USDC, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(USDC));
        nft.issue(tokenId);
        console.log("Invoice issued with partial payments enabled:", tokenId);
        vm.stopPrank();

        uint256 firstPayment = INVOICE_AMOUNT_USDC / 3;
        uint256 secondPayment = INVOICE_AMOUNT_USDC / 3;
        uint256 thirdPayment = INVOICE_AMOUNT_USDC - firstPayment - secondPayment;

        uint256 issuerBalanceBefore = USDC.balanceOf(issuer);

        vm.startPrank(payer);
        USDC.approve(address(payment), INVOICE_AMOUNT_USDC);

        payment.payInvoicePartial{value: 0}(tokenId, firstPayment);
        console.log("First partial payment:", firstPayment);
        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT_USDC - firstPayment);

        payment.payInvoicePartial{value: 0}(tokenId, secondPayment);
        console.log("Second partial payment:", secondPayment);
        assertEq(payment.getRemainingAmount(tokenId), INVOICE_AMOUNT_USDC - firstPayment - secondPayment);

        payment.payInvoicePartial{value: 0}(tokenId, thirdPayment);
        console.log("Third partial payment (final):", thirdPayment);
        vm.stopPrank();

        assertEq(payment.getRemainingAmount(tokenId), 0);
        assertTrue(payment.isPaid(tokenId));

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint8(invoice.status), 2, "Should be Paid");

        assertEq(
            USDC.balanceOf(issuer), issuerBalanceBefore + INVOICE_AMOUNT_USDC, "Issuer should receive full payment"
        );

        console.log("[PASS] Partial payment lifecycle completed successfully");
        console.log("  Total received:", INVOICE_AMOUNT_USDC);
    }

    function testExternalPaymentRecording() public {
        console.log("\n=== Test: External Payment Recording (Base Pay) ===");

        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_USDC, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);
        console.log("Invoice issued:", tokenId);

        bytes32 paymentRef = keccak256(abi.encodePacked("BASE_PAY_TX_", block.timestamp));
        payment.recordExternalPayment(tokenId, paymentRef);
        console.log("External payment recorded with ref:");
        console.logBytes32(paymentRef);
        vm.stopPrank();

        assertTrue(payment.isPaid(tokenId), "Invoice should be marked as paid");

        InvoicePayment.PaymentInfo memory paymentInfo = payment.getPaymentInfo(tokenId);
        assertEq(paymentInfo.paymentRef, paymentRef, "Payment ref should match");
        assertEq(paymentInfo.amountPaid, INVOICE_AMOUNT_USDC, "Amount should match");
        assertEq(paymentInfo.paidBy, payer, "Payer should be recorded");

        console.log("[PASS] External payment recording successful");
    }

    function testCancellationWithPartialPaymentRefund() public {
        console.log("\n=== Test: Cancellation with Partial Payment Refund ===");

        deal(address(USDC), payer, 100e6);

        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_USDC, block.timestamp + DUE_DATE_OFFSET);
        nft.setPartialPayment(tokenId, true);
        nft.setInvoiceToken(tokenId, address(USDC));
        nft.issue(tokenId);
        console.log("Invoice issued:", tokenId);
        vm.stopPrank();

        uint256 partialAmount = INVOICE_AMOUNT_USDC / 2;

        vm.startPrank(payer);
        USDC.approve(address(payment), INVOICE_AMOUNT_USDC);
        payment.payInvoicePartial{value: 0}(tokenId, partialAmount);
        console.log("Partial payment made:", partialAmount);
        vm.stopPrank();

        uint256 payerBalanceBefore = USDC.balanceOf(payer);

        vm.startPrank(issuer);
        nft.cancel(tokenId);
        console.log("Invoice cancelled");

        payment.refund(tokenId);
        console.log("Refund processed");
        vm.stopPrank();

        assertEq(USDC.balanceOf(payer), payerBalanceBefore + partialAmount, "Payer should receive refund");
        assertEq(payment.partialPaid(tokenId), 0, "Partial payment state should be cleared");

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint8(invoice.status), 3, "Should be Cancelled");

        console.log("[PASS] Cancellation and refund successful");
        console.log("  Refunded amount:", partialAmount);
    }

    function testPaymentLinkFlow() public {
        console.log("\n=== Test: Payment Link Flow ===");

        vm.startPrank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_ETH, block.timestamp + DUE_DATE_OFFSET);
        nft.issue(tokenId);

        uint256 expiry = block.timestamp + 7 days;
        bytes32 linkId = paymentLink.generateLink(tokenId, expiry);
        console.log("Payment link generated:");
        console.logBytes32(linkId);
        vm.stopPrank();

        assertTrue(paymentLink.isLinkValid(linkId), "Link should be valid");

        uint256 issuerBalanceBefore = issuer.balance;

        vm.prank(payer);
        paymentLink.payViaLink{value: INVOICE_AMOUNT_ETH}(linkId);
        console.log("Payment made via link");

        assertEq(issuer.balance, issuerBalanceBefore + INVOICE_AMOUNT_ETH, "Issuer should receive payment");
        assertTrue(payment.isPaid(tokenId), "Invoice should be paid");
        assertFalse(paymentLink.isLinkValid(linkId), "Link should be marked as used");

        console.log("[PASS] Payment link flow successful");
    }

    function testEdgeCaseRejections() public {
        console.log("\n=== Test: Edge Case Rejections ===");

        vm.prank(issuer);
        uint256 tokenId = nft.mint(payer, INVOICE_AMOUNT_ETH, block.timestamp + DUE_DATE_OFFSET);

        console.log("Testing payment on Draft invoice...");
        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InvoiceNotIssued.selector);
        payment.payInvoice{value: INVOICE_AMOUNT_ETH}(tokenId);
        console.log("[PASS] Correctly rejected payment on Draft");

        vm.prank(issuer);
        nft.issue(tokenId);

        console.log("Testing overpayment...");
        vm.prank(payer);
        vm.expectRevert(InvoicePayment.Overpayment.selector);
        payment.payInvoice{value: INVOICE_AMOUNT_ETH * 2}(tokenId);
        console.log("[PASS] Correctly rejected overpayment");

        vm.prank(payer);
        payment.payInvoice{value: INVOICE_AMOUNT_ETH}(tokenId);

        console.log("Testing double payment...");
        vm.prank(payer);
        vm.expectRevert(InvoicePayment.InvoiceAlreadyPaid.selector);
        payment.payInvoice{value: INVOICE_AMOUNT_ETH}(tokenId);
        console.log("[PASS] Correctly rejected double payment");

        console.log("Testing cancellation of paid invoice...");
        vm.prank(issuer);
        vm.expectRevert(InvoiceNFTV2.CannotCancelPaidInvoice.selector);
        nft.cancel(tokenId);
        console.log("[PASS] Correctly rejected cancellation of paid invoice");

        console.log("All edge case rejections working correctly");
    }

    function testCompleteOnChainScenario() public {
        console.log("\n=== Test: Complete Real-World Scenario ===");
        console.log("Simulating freelancer invoice payment on Base Sepolia\n");

        deal(address(USDC), payer, 1000e6);

        console.log("Step 1: Freelancer creates invoice for 100 USDC");
        vm.startPrank(issuer);
        uint256 invoiceAmount = 100e6;
        uint256 tokenId = nft.mintWithToken(
            payer, invoiceAmount, block.timestamp + 14 days, address(USDC), "Design work for Q1 2025"
        );
        console.log("  Invoice ID:", tokenId);
        console.log("  Amount: 100 USDC");
        console.log("  Due: 14 days");

        console.log("\nStep 2: Freelancer issues invoice");
        nft.issue(tokenId);
        console.log("  Status: Issued");

        console.log("\nStep 3: Freelancer creates payment link");
        bytes32 linkId = paymentLink.generateLink(tokenId, block.timestamp + 14 days);
        console.log("  Link ID:");
        console.logBytes32(linkId);
        vm.stopPrank();

        console.log("\nStep 4: Client pays via payment link");
        vm.startPrank(payer);
        USDC.approve(address(paymentLink), invoiceAmount);
        paymentLink.payViaLinkToken(linkId, address(USDC), invoiceAmount);
        console.log("  Payment sent: 100 USDC");
        vm.stopPrank();

        console.log("\nStep 5: Verify payment completion");
        assertTrue(payment.isPaid(tokenId), "[PASS] Invoice marked as paid");

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        assertEq(uint8(invoice.status), 2, "[PASS] Status is Paid");

        uint256 issuerBalance = USDC.balanceOf(issuer);
        assertEq(issuerBalance, invoiceAmount, "[PASS] Freelancer received 100 USDC");

        console.log("\n=== Scenario Complete ===");
        console.log("Invoice paid successfully on Base Sepolia");
        console.log("All state transitions validated");
        console.log("Funds transferred correctly");
    }
}
