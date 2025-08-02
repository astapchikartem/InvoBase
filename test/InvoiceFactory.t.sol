// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceFactory} from "../src/InvoiceFactory.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

contract InvoiceFactoryTest is Test {
    InvoiceFactory public factory;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    function setUp() public {
        vm.prank(owner);
        factory = new InvoiceFactory();
        usdc = new MockUSDC();
    }

    function testDeployInvoiceManager() public {
        vm.prank(user1);
        address manager = factory.deployInvoiceManager(user1);

        assertTrue(manager != address(0));
        assertEq(InvoiceManager(manager).owner(), user1);
    }

    function testMultipleDeployments() public {
        vm.prank(user1);
        address manager1 = factory.deployInvoiceManager(user1);

        vm.prank(user2);
        address manager2 = factory.deployInvoiceManager(user2);

        assertTrue(manager1 != manager2);
        assertEq(InvoiceManager(manager1).owner(), user1);
        assertEq(InvoiceManager(manager2).owner(), user2);
    }

    function testGetDeployedManagers() public {
        vm.prank(user1);
        factory.deployInvoiceManager(user1);

        vm.prank(user1);
        factory.deployInvoiceManager(user1);

        address[] memory managers = factory.getUserManagers(user1);
        assertEq(managers.length, 2);
    }
}
