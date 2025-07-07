// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControlUpgradeable} from "@openzeppelin-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract InvoiceAccessControl is AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant APPROVER_ROLE = keccak256("APPROVER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    mapping(uint256 => bool) public invoiceApprovals;

    event InvoiceApproved(uint256 indexed invoiceId, address indexed approver);
    event RoleGrantedForInvoice(uint256 indexed invoiceId, bytes32 indexed role, address account);

    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function grantIssuerRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(ISSUER_ROLE, account);
    }

    function grantApproverRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(APPROVER_ROLE, account);
    }

    function grantExecutorRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(EXECUTOR_ROLE, account);
    }

    function approveInvoice(uint256 invoiceId) external onlyRole(APPROVER_ROLE) {
        invoiceApprovals[invoiceId] = true;
        emit InvoiceApproved(invoiceId, msg.sender);
    }

    function isApproved(uint256 invoiceId) external view returns (bool) {
        return invoiceApprovals[invoiceId];
    }

    function canIssue(address account) external view returns (bool) {
        return hasRole(ISSUER_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function canApprove(address account) external view returns (bool) {
        return hasRole(APPROVER_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function canExecute(address account) external view returns (bool) {
        return hasRole(EXECUTOR_ROLE, account) || hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
