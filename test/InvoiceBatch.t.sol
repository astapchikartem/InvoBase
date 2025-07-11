// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {InvoiceManager} from "../src/InvoiceManager.sol";
import {InvoiceBatchOperations} from "../src/InvoiceBatchOperations.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IInvoiceManager} from "../src/interfaces/IInvoiceManager.sol";

contract InvoiceBatchTest is Test {
    InvoiceManager public invoiceManager;
    InvoiceBatchOperations public batchOps;
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

        batchOps = new InvoiceBatchOperations(address(invoiceManager));
    }

    function testBatchCreate() public {
        InvoiceBatchOperations.BatchInvoiceParams[]
            memory params = new InvoiceBatchOperations.BatchInvoiceParams[](3);

        params[0] = InvoiceBatchOperations.BatchInvoiceParams({
            payer: payer,
            amount: 1000e6,
            asset: address(usdc),
            metadata: "Invoice #1"
        });

        params[1] = InvoiceBatchOperations.BatchInvoiceParams({
            payer: payer,
            amount: 2000e6,
            asset: address(usdc),
            metadata: "Invoice #2"
        });

        params[2] = InvoiceBatchOperations.BatchInvoiceParams({
            payer: payer,
            amount: 3000e6,
            asset: address(usdc),
            metadata: "Invoice #3"
        });

        vm.prank(issuer);
        uint256[] memory ids = batchOps.createBatch(params);

        assertEq(ids.length, 3);
        assertEq(ids[0], 1);
        assertEq(ids[1], 2);
        assertEq(ids[2], 3);
    }
}
