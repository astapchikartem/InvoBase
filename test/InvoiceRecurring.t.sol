// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {RecurringInvoices} from "../src/RecurringInvoices.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract RecurringInvoicesTest is Test {
    RecurringInvoices public recurring;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);

    function setUp() public {
        usdc = new MockUSDC();
        vm.prank(owner);
        recurring = new RecurringInvoices();
    }

    function testCreateRecurringInvoice() public {
        vm.prank(issuer);
        uint256 recurringId = recurring.createRecurring(
            payer,
            1000e6,
            address(usdc),
            30 days,
            12
        );

        assertEq(recurringId, 1);
    }

    function testExecuteRecurringPayment() public {
        vm.prank(issuer);
        uint256 recurringId = recurring.createRecurring(
            payer,
            1000e6,
            address(usdc),
            30 days,
            12
        );

        usdc.mint(payer, 12000e6);
        vm.prank(payer);
        usdc.approve(address(recurring), type(uint256).max);

        vm.warp(block.timestamp + 30 days);

        vm.prank(payer);
        recurring.executePayment(recurringId);

        assertEq(usdc.balanceOf(issuer), 1000e6);
    }
}
