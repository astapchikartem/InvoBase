// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "./interfaces/IInvoiceManager.sol";

contract InvoiceFactory {
    IInvoiceManager public immutable invoiceManager;

    struct InvoiceTemplate {
        uint256 amount;
        address asset;
        string metadata;
        bool active;
    }

    mapping(bytes32 => InvoiceTemplate) public templates;
    mapping(address => bytes32[]) public userTemplates;

    event TemplateCreated(bytes32 indexed templateId, address indexed creator);
    event TemplateUsed(bytes32 indexed templateId, uint256 indexed invoiceId);

    constructor(address _invoiceManager) {
        invoiceManager = IInvoiceManager(_invoiceManager);
    }

    function createTemplate(
        string calldata name,
        uint256 amount,
        address asset,
        string calldata metadata
    ) external returns (bytes32) {
        bytes32 templateId = keccak256(abi.encodePacked(msg.sender, name, block.timestamp));

        templates[templateId] = InvoiceTemplate({
            amount: amount,
            asset: asset,
            metadata: metadata,
            active: true
        });

        userTemplates[msg.sender].push(templateId);

        emit TemplateCreated(templateId, msg.sender);

        return templateId;
    }

    function createInvoiceFromTemplate(
        bytes32 templateId,
        address payer
    ) external returns (uint256) {
        InvoiceTemplate memory template = templates[templateId];
        require(template.active, "Template not active");

        uint256 invoiceId = invoiceManager.createInvoice(
            payer,
            template.amount,
            template.asset,
            template.metadata
        );

        emit TemplateUsed(templateId, invoiceId);

        return invoiceId;
    }

    function deactivateTemplate(bytes32 templateId) external {
        templates[templateId].active = false;
    }

    function getUserTemplates(address user) external view returns (bytes32[] memory) {
        return userTemplates[user];
    }
}
