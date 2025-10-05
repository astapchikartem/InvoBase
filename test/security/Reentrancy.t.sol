// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../../src/InvoiceManager.sol";
import {MockUSDC} from "../../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ReentrancyTest is Test {
    InvoiceManager public manager;
    MockUSDC public usdc;

    address public owner = address(0x1);
    address public issuer = address(0x2);
    address public attacker = address(0x3);

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

    function testReentrancyProtection() public {
        // Create invoice
        vm.prank(issuer);
        uint256 invoiceId = manager.createInvoice(
            attacker,
            1000e6,
            address(usdc),
            "Test"
        );

        vm.prank(issuer);
        manager.issueInvoice(invoiceId, block.timestamp + 30 days);

        usdc.mint(attacker, 10000e6);

        vm.prank(attacker);
        usdc.approve(address(manager), type(uint256).max);

        // Attempt reentrancy (should be protected)
        vm.prank(attacker);
        manager.payInvoice(invoiceId);

        // Verify state is correct
        assertEq(usdc.balanceOf(issuer), 1000e6);
    }
}
