// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceAccessControl} from "../src/InvoiceAccessControl.sol";

contract InvoiceAccessControlTest is Test {
    InvoiceAccessControl public accessControl;

    address public admin = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.prank(admin);
        accessControl = new InvoiceAccessControl();
    }

    function testGrantRole() public {
        bytes32 role = keccak256("ISSUER_ROLE");

        vm.prank(admin);
        accessControl.grantRole(role, user1);

        assertTrue(accessControl.hasRole(role, user1));
    }

    function testRevokeRole() public {
        bytes32 role = keccak256("ISSUER_ROLE");

        vm.startPrank(admin);
        accessControl.grantRole(role, user1);
        accessControl.revokeRole(role, user1);
        vm.stopPrank();

        assertFalse(accessControl.hasRole(role, user1));
    }

    function testMultipleRoles() public {
        bytes32 issuerRole = keccak256("ISSUER_ROLE");
        bytes32 payerRole = keccak256("PAYER_ROLE");

        vm.startPrank(admin);
        accessControl.grantRole(issuerRole, user1);
        accessControl.grantRole(payerRole, user1);
        vm.stopPrank();

        assertTrue(accessControl.hasRole(issuerRole, user1));
        assertTrue(accessControl.hasRole(payerRole, user1));
    }
}
