// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IInvoiceManager} from "../src/interfaces/IInvoiceManager.sol";

contract InvoiceManagerTest is Test {
    InvoiceManager public invoiceManager;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);

    function setUp() public {
        usdc = new MockUSDC();

        InvoiceManager implementation = new InvoiceManager();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            owner
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        invoiceManager = InvoiceManager(address(proxy));

        usdc.mint(payer, 10000e6);

        vm.prank(payer);
        usdc.approve(address(invoiceManager), type(uint256).max);
    }

    function testCreateInvoice() public {
        vm.startPrank(issuer);

        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        assertEq(invoiceId, 1);

        IInvoiceManager.Invoice memory invoice = invoiceManager.getInvoice(invoiceId);

        assertEq(invoice.issuer, issuer);
        assertEq(invoice.payer, payer);
        assertEq(invoice.amount, 1000e6);
        assertEq(invoice.asset, address(usdc));
        assertEq(uint256(invoice.status), uint256(IInvoiceManager.InvoiceStatus.Draft));

        vm.stopPrank();
    }

    function testIssueInvoice() public {
        vm.startPrank(issuer);

        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        uint256 dueDate = block.timestamp + 30 days;
        invoiceManager.issueInvoice(invoiceId, dueDate);

        IInvoiceManager.Invoice memory invoice = invoiceManager.getInvoice(invoiceId);

        assertEq(uint256(invoice.status), uint256(IInvoiceManager.InvoiceStatus.Issued));
        assertEq(invoice.dueDate, dueDate);

        vm.stopPrank();
    }

    function testPayInvoice() public {
        vm.prank(issuer);
        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        vm.prank(issuer);
        invoiceManager.issueInvoice(invoiceId, block.timestamp + 30 days);

        uint256 issuerBalanceBefore = usdc.balanceOf(issuer);
        uint256 payerBalanceBefore = usdc.balanceOf(payer);

        vm.prank(payer);
        invoiceManager.payInvoice(invoiceId);

        assertEq(usdc.balanceOf(issuer), issuerBalanceBefore + 1000e6);
        assertEq(usdc.balanceOf(payer), payerBalanceBefore - 1000e6);

        IInvoiceManager.Invoice memory invoice = invoiceManager.getInvoice(invoiceId);
        assertEq(uint256(invoice.status), uint256(IInvoiceManager.InvoiceStatus.Paid));
    }

    function testCancelInvoice() public {
        vm.prank(issuer);
        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        vm.prank(issuer);
        invoiceManager.cancelInvoice(invoiceId);

        IInvoiceManager.Invoice memory invoice = invoiceManager.getInvoice(invoiceId);
        assertEq(uint256(invoice.status), uint256(IInvoiceManager.InvoiceStatus.Cancelled));
    }

    function testRevertUnauthorizedIssue() public {
        vm.prank(issuer);
        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        vm.prank(payer);
        vm.expectRevert(InvoiceManager.UnauthorizedAccess.selector);
        invoiceManager.issueInvoice(invoiceId, block.timestamp + 30 days);
    }

    function testRevertZeroAmount() public {
        vm.prank(issuer);
        vm.expectRevert(InvoiceManager.InvalidAmount.selector);
        invoiceManager.createInvoice(payer, 0, address(usdc), "Invalid");
    }

    function testRevertInvalidAddress() public {
        vm.prank(issuer);
        vm.expectRevert(InvoiceManager.InvalidAddress.selector);
        invoiceManager.createInvoice(address(0), 1000e6, address(usdc), "Invalid");
    }

    function testRevertPayUnauthorized() public {
        vm.prank(issuer);
        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        vm.prank(issuer);
        invoiceManager.issueInvoice(invoiceId, block.timestamp + 30 days);

        vm.prank(issuer);
        vm.expectRevert(InvoiceManager.UnauthorizedAccess.selector);
        invoiceManager.payInvoice(invoiceId);
    }
}
