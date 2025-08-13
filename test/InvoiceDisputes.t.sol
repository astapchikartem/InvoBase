// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceDisputes} from "../src/InvoiceDisputes.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract InvoiceDisputesTest is Test {
    InvoiceDisputes public disputes;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);
    address public arbiter = address(0x4);

    function setUp() public {
        usdc = new MockUSDC();
        vm.prank(owner);
        disputes = new InvoiceDisputes();
    }

    function testCreateDispute() public {
        vm.prank(payer);
        uint256 disputeId = disputes.createDispute(1, "Invalid invoice amount");

        assertEq(disputeId, 1);
    }

    function testResolveDispute() public {
        vm.prank(payer);
        uint256 disputeId = disputes.createDispute(1, "Invalid invoice amount");

        vm.prank(arbiter);
        disputes.resolveDispute(disputeId, true, "Dispute resolved in favor of payer");

        (,,,, bool resolved) = disputes.getDispute(disputeId);
        assertTrue(resolved);
    }

    function testRejectUnauthorizedResolution() public {
        vm.prank(payer);
        uint256 disputeId = disputes.createDispute(1, "Invalid invoice amount");

        vm.prank(payer);
        vm.expectRevert();
        disputes.resolveDispute(disputeId, true, "Unauthorized");
    }
}
