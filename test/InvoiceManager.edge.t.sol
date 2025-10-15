// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract InvoiceManagerEdgeTest is Test {
    InvoiceManager public manager;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);

    function setUp() public {
        usdc = new MockUSDC();

        InvoiceManager impl = new InvoiceManager();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            owner
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        manager = InvoiceManager(address(proxy));

        usdc.mint(payer, 100000e6);
        vm.prank(payer);
        usdc.approve(address(manager), type(uint256).max);
    }

    function testMaximumAmount() public {
        vm.prank(issuer);
        uint256 id = manager.createInvoice(
            payer,
            type(uint96).max,
            address(usdc),
            "Max amount invoice"
        );

        assertEq(id, 1);
    }

    function testMultipleInvoicesSameParties() public {
        for (uint256 i = 0; i < 10; i++) {
            vm.prank(issuer);
            manager.createInvoice(payer, 1000e6, address(usdc), "Invoice");
        }

        assertEq(manager.getNextInvoiceId(), 11);
    }

    function testCancelIssuedInvoice() public {
        vm.prank(issuer);
        uint256 id = manager.createInvoice(payer, 1000e6, address(usdc), "Test");

        vm.prank(issuer);
        manager.issueInvoice(id, block.timestamp + 30 days);

        vm.prank(issuer);
        manager.cancelInvoice(id);
    }

    function testImmediatePayment() public {
        vm.prank(issuer);
        uint256 id = manager.createInvoice(payer, 1000e6, address(usdc), "Test");

        vm.prank(issuer);
        manager.issueInvoice(id, block.timestamp + 1 seconds);

        vm.prank(payer);
        manager.payInvoice(id);
    }
}
