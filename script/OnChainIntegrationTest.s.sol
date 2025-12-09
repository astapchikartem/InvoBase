// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {InvoiceNFTV2} from "../src/InvoiceNFTV2.sol";
import {InvoicePayment} from "../src/InvoicePayment.sol";
import {PaymentLink} from "../src/PaymentLink.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {stdJson} from "forge-std/StdJson.sol";

contract OnChainIntegrationTest is Script {
    using stdJson for string;

    InvoiceNFTV2 public nft;
    InvoicePayment public payment;
    PaymentLink public paymentLink;
    IERC20 public usdc;

    address public issuer;
    address public payer;

    uint256 constant TEST_AMOUNT = 100e6;
    uint256 constant TEST_AMOUNT_ETH = 0.01 ether;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        issuer = vm.addr(deployerPrivateKey);
        payer = issuer;

        _loadContracts();

        console.log("=== On-Chain Integration Tests ===");

        vm.startBroadcast(deployerPrivateKey);

        _testFullETHPaymentFlow();
        _testFullUSDCPaymentFlow();
        _testPartialPaymentFlow();
        _testExternalPaymentFlow();
        _testStateTransitionValidation();

        vm.stopBroadcast();

        console.log("=== Tests Complete ===");
    }

    function _loadContracts() internal {
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/base-sepolia-v2.json");
        string memory json = vm.readFile(path);

        address proxyAddress = json.readAddress(".proxy");
        address paymentAddress = json.readAddress(".paymentProcessor");
        address linkAddress = json.readAddress(".paymentLink");

        nft = InvoiceNFTV2(proxyAddress);
        payment = InvoicePayment(paymentAddress);
        paymentLink = PaymentLink(linkAddress);
        usdc = IERC20(0x036CbD53842c5426634e7929541eC2318f3dCF7e);
    }

    function _testFullETHPaymentFlow() internal {
        uint256 tokenId = nft.mint(payer, TEST_AMOUNT_ETH, block.timestamp + 30 days);
        nft.issue(tokenId);
        payment.payInvoice{value: TEST_AMOUNT_ETH}(tokenId);

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        require(uint8(invoice.status) == 2, "Should be Paid");
        console.log("PASS: Full ETH payment");
    }

    function _testFullUSDCPaymentFlow() internal {
        uint256 tokenId = nft.mint(payer, TEST_AMOUNT, block.timestamp + 30 days);
        nft.issue(tokenId);
        usdc.approve(address(payment), TEST_AMOUNT);
        payment.payInvoiceToken(tokenId, address(usdc), TEST_AMOUNT);

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        require(uint8(invoice.status) == 2, "Should be Paid");
        console.log("PASS: Full USDC payment");
    }

    function _testPartialPaymentFlow() internal {
        uint256 tokenId = nft.mint(payer, TEST_AMOUNT, block.timestamp + 30 days);
        nft.issue(tokenId);
        nft.setPartialPayment(tokenId, true);

        usdc.approve(address(payment), TEST_AMOUNT);
        payment.payInvoicePartial{value: 0}(tokenId, TEST_AMOUNT / 2);
        payment.payInvoicePartial{value: 0}(tokenId, TEST_AMOUNT / 2);

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        require(uint8(invoice.status) == 2, "Should be Paid");
        console.log("PASS: Partial payments");
    }

    function _testExternalPaymentFlow() internal {
        uint256 tokenId = nft.mint(payer, TEST_AMOUNT, block.timestamp + 30 days);
        nft.issue(tokenId);

        bytes32 paymentRef = keccak256("BASE_PAY_TEST");
        payment.recordExternalPayment(tokenId, paymentRef);

        InvoiceNFTV2.Invoice memory invoice = nft.getInvoice(tokenId);
        require(uint8(invoice.status) == 2, "Should be Paid");
        console.log("PASS: External payment");
    }

    function _testStateTransitionValidation() internal {
        uint256 tokenId = nft.mint(payer, TEST_AMOUNT, block.timestamp + 30 days);
        nft.issue(tokenId);

        try nft.issue(tokenId) {
            revert("Should not allow double issue");
        } catch {
            console.log("PASS: State validation");
        }
    }
}
