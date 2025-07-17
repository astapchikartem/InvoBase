// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "./interfaces/IInvoiceManager.sol";

contract InvoiceDisputes {
    enum DisputeStatus {
        Open,
        Resolved,
        Rejected
    }

    struct Dispute {
        uint256 invoiceId;
        address initiator;
        string reason;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
        string resolution;
    }

    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => uint256) public invoiceDisputes;
    uint256 public nextDisputeId;

    address public arbitrator;

    event DisputeCreated(
        uint256 indexed disputeId,
        uint256 indexed invoiceId,
        address indexed initiator
    );
    event DisputeResolved(uint256 indexed disputeId, DisputeStatus status);

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Not arbitrator");
        _;
    }

    constructor(address _arbitrator) {
        arbitrator = _arbitrator;
        nextDisputeId = 1;
    }

    function createDispute(uint256 invoiceId, string calldata reason) external returns (uint256) {
        require(invoiceDisputes[invoiceId] == 0, "Dispute exists");

        uint256 disputeId = nextDisputeId++;

        disputes[disputeId] = Dispute({
            invoiceId: invoiceId,
            initiator: msg.sender,
            reason: reason,
            status: DisputeStatus.Open,
            createdAt: block.timestamp,
            resolvedAt: 0,
            resolution: ""
        });

        invoiceDisputes[invoiceId] = disputeId;

        emit DisputeCreated(disputeId, invoiceId, msg.sender);

        return disputeId;
    }

    function resolveDispute(
        uint256 disputeId,
        DisputeStatus status,
        string calldata resolution
    ) external onlyArbitrator {
        Dispute storage dispute = disputes[disputeId];
        require(dispute.status == DisputeStatus.Open, "Not open");

        dispute.status = status;
        dispute.resolvedAt = block.timestamp;
        dispute.resolution = resolution;

        emit DisputeResolved(disputeId, status);
    }

    function getDispute(uint256 disputeId) external view returns (Dispute memory) {
        return disputes[disputeId];
    }

    function setArbitrator(address newArbitrator) external onlyArbitrator {
        arbitrator = newArbitrator;
    }
}
