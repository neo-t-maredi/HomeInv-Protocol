// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CommunityOracle
 * @author HomeInv Protocol
 * @notice Street Committee DAO — verifies physical real-world events on-chain
 * @dev Committee members propose and vote on property events.
 *      Approved events trigger actions in PropertyPool.
 *      Quorum required before any event is considered verified.
 *
 * This contract encodes spatial justice into the protocol:
 *  - Truth comes from the community, not a centralised oracle
 *  - Street committees who know the property verify its status
 *  - Verified events are immutable, transparent and auditable
 *
 * Verifiable events:
 *  - MAINTENANCE_COMPLETED       — repairs done, property habitable
 *  - LEGAL_OCCUPANCY_CONFIRMED   — tenant legally occupying
 *  - CONSTRUCTION_MILESTONE      — development phase verified
 *  - COMPLIANCE_BREACH           — flags issue, can pause distributions
 *  - VACANCY_REPORTED            — property unoccupied
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {ICommunityOracle} from "../interfaces/ICommunityOracle.sol";
import {IPropertyPool} from "../interfaces/IPropertyPool.sol";

contract CommunityOracle is ICommunityOracle, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant COMMITTEE_MEMBER_ROLE = keccak256("COMMITTEE_MEMBER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Proposal {
        uint256 propertyId;
        EventType eventType;
        bytes32 evidenceHash;
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 createdAt;
        ProposalState state;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Minimum votes required for approval
    uint256 public quorum;

    /// @notice Voting window in seconds
    uint256 public votingPeriod;

    /// @notice Total proposals created
    uint256 public proposalCount;

    /// @notice proposalId => Proposal
    mapping(uint256 => Proposal) public proposals;

    /// @notice proposalId => voter => has voted
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    /// @notice propertyId => approved event hashes
    mapping(uint256 => bytes32[]) public verifiedEvents;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event ProposalCreated(uint256 indexed proposalId, uint256 indexed propertyId, EventType eventType, address proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool approved);
    event ProposalApproved(uint256 indexed proposalId, uint256 indexed propertyId, EventType eventType);
    event ProposalRejected(uint256 indexed proposalId);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error CommunityOracle__NotCommitteeMember();
    error CommunityOracle__AlreadyVoted(address voter);
    error CommunityOracle__ProposalNotPending(uint256 proposalId);
    error CommunityOracle__VotingPeriodExpired(uint256 proposalId);
    error CommunityOracle__ZeroAddress();
    error CommunityOracle__InvalidQuorum();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _admin,
        uint256 _quorum,
        uint256 _votingPeriod
    ) {
        if (_admin == address(0)) revert CommunityOracle__ZeroAddress();
        if (_quorum == 0) revert CommunityOracle__InvalidQuorum();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(COMMITTEE_MEMBER_ROLE, _admin);

        quorum = _quorum;
        votingPeriod = _votingPeriod;
    }

    /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Committee member proposes a real-world event for verification
    function proposeEvent(
        uint256 _propertyId,
        EventType _eventType,
        bytes32 _evidenceHash
    ) external onlyRole(COMMITTEE_MEMBER_ROLE) {
        uint256 proposalId = proposalCount++;

        proposals[proposalId] = Proposal({
            propertyId: _propertyId,
            eventType: _eventType,
            evidenceHash: _evidenceHash,
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            createdAt: block.timestamp,
            state: ProposalState.PENDING
        });

        emit ProposalCreated(proposalId, _propertyId, _eventType, msg.sender);
    }

    /// @notice Committee member votes on a pending proposal
    function voteOnEvent(uint256 _proposalId, bool _approve) external onlyRole(COMMITTEE_MEMBER_ROLE) {
        Proposal storage proposal = proposals[_proposalId];

        if (proposal.state != ProposalState.PENDING)
            revert CommunityOracle__ProposalNotPending(_proposalId);
        if (block.timestamp > proposal.createdAt + votingPeriod)
            revert CommunityOracle__VotingPeriodExpired(_proposalId);
        if (hasVoted[_proposalId][msg.sender])
            revert CommunityOracle__AlreadyVoted(msg.sender);

        // Record vote
        hasVoted[_proposalId][msg.sender] = true;

        if (_approve) {
            proposal.votesFor++;
        } else {
            proposal.votesAgainst++;
        }

        emit VoteCast(_proposalId, msg.sender, _approve);

        // Check if quorum reached
        if (proposal.votesFor >= quorum) {
            proposal.state = ProposalState.APPROVED;
            verifiedEvents[proposal.propertyId].push(proposal.evidenceHash);
            emit ProposalApproved(_proposalId, proposal.propertyId, proposal.eventType);
        } else if (proposal.votesAgainst >= quorum) {
            proposal.state = ProposalState.REJECTED;
            emit ProposalRejected(_proposalId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates quorum threshold
    function setQuorum(uint256 _newQuorum) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newQuorum == 0) revert CommunityOracle__InvalidQuorum();
        emit QuorumUpdated(quorum, _newQuorum);
        quorum = _newQuorum;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns current state of a proposal
    function getProposalState(uint256 _proposalId) external view returns (ProposalState) {
        return proposals[_proposalId].state;
    }

    /// @notice Returns all verified event hashes for a property
    function getVerifiedEvents(uint256 _propertyId) external view returns (bytes32[] memory) {
        return verifiedEvents[_propertyId];
    }

    /// @notice Returns full proposal details
    function getProposal(uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_proposalId];
    }


}