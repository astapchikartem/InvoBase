// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../../src/InvoiceManager.sol";
import {InvoiceNFT} from "../../src/InvoiceNFT.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IInvoiceManager} from "../../src/interfaces/IInvoiceManager.sol";

contract FullWorkflowTest is Test {
    InvoiceManager public manager;
    InvoiceNFT public nft;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public payer = address(0x3);

    function setUp() public {
        usdc = new MockUSDC();

        InvoiceManager managerImpl = new InvoiceManager();
        bytes memory initData = abi.encodeWithSelector(
            InvoiceManager.initialize.selector,
            owner
        );
        ERC1967Proxy managerProxy = new ERC1967Proxy(address(managerImpl), initData);
        manager = InvoiceManager(address(managerProxy));

        InvoiceNFT nftImpl = new InvoiceNFT();
        bytes memory nftInitData = abi.encodeWithSelector(
            InvoiceNFT.initialize.selector,
            address(manager),
            owner
        );
        ERC1967Proxy nftProxy = new ERC1967Proxy(address(nftImpl), nftInitData);
        nft = InvoiceNFT(address(nftProxy));

        usdc.mint(payer, 100000e6);
        vm.prank(payer);
        usdc.approve(address(manager), type(uint256).max);
    }

    function testFullInvoiceLifecycle() public {
        // Create invoice
        vm.prank(issuer);
        uint256 invoiceId = manager.createInvoice(
            payer,
            1000e6,
            address(usdc),
            "Invoice #001"
        );

        // Issue invoice
        vm.prank(issuer);
        uint256 dueDate = block.timestamp + 30 days;
        manager.issueInvoice(invoiceId, dueDate);

        // Pay invoice
        vm.prank(payer);
        manager.payInvoice(invoiceId);

        // Verify payment
        IInvoiceManager.Invoice memory invoice = manager.getInvoice(invoiceId);
        assertEq(uint256(invoice.status), uint256(IInvoiceManager.InvoiceStatus.Paid));
        assertEq(usdc.balanceOf(issuer), 1000e6);
        assertEq(usdc.balanceOf(payer), 99000e6);
    }

    function testMultipleInvoices() public {
        for (uint256 i = 1; i <= 5; i++) {
            vm.prank(issuer);
            uint256 id = manager.createInvoice(
                payer,
                1000e6 * i,
                address(usdc),
                string(abi.encodePacked("Invoice #", vm.toString(i)))
            );

            vm.prank(issuer);
            manager.issueInvoice(id, block.timestamp + 30 days);

            vm.prank(payer);
            manager.payInvoice(id);
        }

        assertEq(usdc.balanceOf(issuer), 15000e6);
    }
}
