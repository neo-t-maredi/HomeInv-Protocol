// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ICommunityOracle
 * @author HomeInv Protocol
 * @notice Interface for CommunityOracle — Street Committee DAO verification
 */
interface ICommunityOracle {
    enum EventType {
        MAINTENANCE_COMPLETED,
        LEGAL_OCCUPANCY_CONFIRMED,
        CONSTRUCTION_MILESTONE,
        COMPLIANCE_BREACH,
        VACANCY_REPORTED
    }

    enum ProposalState {
        PENDING,
        APPROVED,
        REJECTED
    }

    function proposeEvent(uint256 _propertyId, EventType _eventType, bytes32 _evidenceHash) external;
    function voteOnEvent(uint256 _proposalId, bool _approve) external;
    function getProposalState(uint256 _proposalId) external view returns (ProposalState);
}