// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IInvoiceManager} from "./interfaces/IInvoiceManager.sol";

contract RecurringInvoices {
    IInvoiceManager public immutable invoiceManager;

    enum Frequency {
        Weekly,
        BiWeekly,
        Monthly,
        Quarterly,
        Yearly
    }

    struct RecurringSchedule {
        address payer;
        uint256 amount;
        address asset;
        string metadata;
        Frequency frequency;
        uint256 startDate;
        uint256 endDate;
        uint256 lastInvoiceDate;
        bool active;
    }

    mapping(bytes32 => RecurringSchedule) public schedules;
    mapping(bytes32 => uint256[]) public generatedInvoices;

    event ScheduleCreated(bytes32 indexed scheduleId, address indexed issuer);
    event InvoiceGenerated(bytes32 indexed scheduleId, uint256 indexed invoiceId);

    constructor(address _invoiceManager) {
        invoiceManager = IInvoiceManager(_invoiceManager);
    }

    function createSchedule(
        address payer,
        uint256 amount,
        address asset,
        string calldata metadata,
        Frequency frequency,
        uint256 startDate,
        uint256 endDate
    ) external returns (bytes32) {
        bytes32 scheduleId = keccak256(
            abi.encodePacked(msg.sender, payer, block.timestamp)
        );

        schedules[scheduleId] = RecurringSchedule({
            payer: payer,
            amount: amount,
            asset: asset,
            metadata: metadata,
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            lastInvoiceDate: 0,
            active: true
        });

        emit ScheduleCreated(scheduleId, msg.sender);

        return scheduleId;
    }

    function generateInvoice(bytes32 scheduleId) external returns (uint256) {
        RecurringSchedule storage schedule = schedules[scheduleId];
        require(schedule.active, "Schedule not active");
        require(block.timestamp >= schedule.startDate, "Not started");
        require(block.timestamp <= schedule.endDate, "Schedule ended");

        if (schedule.lastInvoiceDate > 0) {
            uint256 interval = _getInterval(schedule.frequency);
            require(
                block.timestamp >= schedule.lastInvoiceDate + interval,
                "Too early"
            );
        }

        uint256 invoiceId = invoiceManager.createInvoice(
            schedule.payer,
            schedule.amount,
            schedule.asset,
            schedule.metadata
        );

        schedule.lastInvoiceDate = block.timestamp;
        generatedInvoices[scheduleId].push(invoiceId);

        emit InvoiceGenerated(scheduleId, invoiceId);

        return invoiceId;
    }

    function _getInterval(Frequency frequency) internal pure returns (uint256) {
        if (frequency == Frequency.Weekly) return 7 days;
        if (frequency == Frequency.BiWeekly) return 14 days;
        if (frequency == Frequency.Monthly) return 30 days;
        if (frequency == Frequency.Quarterly) return 90 days;
        return 365 days;
    }

    function cancelSchedule(bytes32 scheduleId) external {
        schedules[scheduleId].active = false;
    }
}
