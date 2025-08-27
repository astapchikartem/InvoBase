// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../../src/InvoiceManager.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract InvoiceFuzzTest is Test {
    InvoiceManager public manager;
    MockUSDC public usdc;

    address public owner = address(0x1);

    function setUp() public {
        usdc = new MockUSDC();

        InvoiceManager impl = new InvoiceManager();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            owner
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        manager = InvoiceManager(address(proxy));
    }

    function testFuzz_CreateInvoice(
        address issuer,
        address payer,
        uint256 amount
    ) public {
        vm.assume(issuer != address(0));
        vm.assume(payer != address(0));
        vm.assume(amount > 0 && amount < 1_000_000_000e6);

        vm.prank(issuer);
        uint256 invoiceId = manager.createInvoice(
            payer,
            amount,
            address(usdc),
            "Fuzz test invoice"
        );

        assertEq(invoiceId, 1);
    }

    function testFuzz_IssueInvoice(
        address issuer,
        address payer,
        uint256 amount,
        uint256 dueDate
    ) public {
        vm.assume(issuer != address(0));
        vm.assume(payer != address(0));
        vm.assume(amount > 0 && amount < 1_000_000_000e6);
        vm.assume(dueDate > block.timestamp && dueDate < block.timestamp + 365 days);

        vm.prank(issuer);
        uint256 invoiceId = manager.createInvoice(
            payer,
            amount,
            address(usdc),
            "Fuzz test invoice"
        );

        vm.prank(issuer);
        manager.issueInvoice(invoiceId, dueDate);
    }

    function testFuzz_PayInvoice(
        address issuer,
        address payer,
        uint96 amount
    ) public {
        vm.assume(issuer != address(0));
        vm.assume(payer != address(0) && payer != issuer);
        vm.assume(amount > 0);

        usdc.mint(payer, amount);

        vm.prank(payer);
        usdc.approve(address(manager), type(uint256).max);

        vm.prank(issuer);
        uint256 invoiceId = manager.createInvoice(
            payer,
            amount,
            address(usdc),
            "Fuzz test invoice"
        );

        vm.prank(issuer);
        manager.issueInvoice(invoiceId, block.timestamp + 30 days);

        vm.prank(payer);
        manager.payInvoice(invoiceId);

        assertEq(usdc.balanceOf(issuer), amount);
    }
}
