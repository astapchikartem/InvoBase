// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../../src/InvoiceManager.sol";
import {InvoiceManagerV2} from "../../src/InvoiceManagerV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";

contract UpgradeTest is Test {
    InvoiceManager public managerV1;
    InvoiceManagerV2 public managerV2;
    MockUSDC public usdc;
    ERC1967Proxy public proxy;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);

    function setUp() public {
        usdc = new MockUSDC();

        // Deploy V1
        InvoiceManager v1Impl = new InvoiceManager();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            owner
        );
        proxy = new ERC1967Proxy(address(v1Impl), initData);
        managerV1 = InvoiceManager(address(proxy));

        // Create an invoice with V1
        vm.prank(issuer);
        managerV1.createInvoice(payer, 1000e6, address(usdc), "V1 Invoice");
    }

    function testUpgradePreservesData() public {
        // Get invoice data before upgrade
        IInvoiceManager.Invoice memory invoiceBeforeUpgrade = managerV1.getInvoice(1);

        // Deploy V2 and upgrade
        InvoiceManagerV2 v2Impl = new InvoiceManagerV2();

        vm.prank(owner);
        managerV1.upgradeToAndCall(address(v2Impl), "");

        // Create new instance pointing to same proxy
        managerV2 = InvoiceManagerV2(address(proxy));

        // Verify data is preserved
        IInvoiceManager.Invoice memory invoiceAfterUpgrade = managerV2.getInvoice(1);

        assertEq(invoiceBeforeUpgrade.id, invoiceAfterUpgrade.id);
        assertEq(invoiceBeforeUpgrade.issuer, invoiceAfterUpgrade.issuer);
        assertEq(invoiceBeforeUpgrade.payer, invoiceAfterUpgrade.payer);
        assertEq(invoiceBeforeUpgrade.amount, invoiceAfterUpgrade.amount);
    }

    function testUpgradeUnauthorized() public {
        InvoiceManagerV2 v2Impl = new InvoiceManagerV2();

        vm.prank(issuer);
        vm.expectRevert();
        managerV1.upgradeToAndCall(address(v2Impl), "");
    }
}
