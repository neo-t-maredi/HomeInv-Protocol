// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {CommunityOracle} from "../../src/oracle/CommunityOracle.sol";
import {ICommunityOracle} from "../../src/interfaces/ICommunityOracle.sol";

contract CommunityOracleTest is Test {
    CommunityOracle public oracle;

    address public admin = makeAddr("admin");
    address public member1 = makeAddr("member1");
    address public member2 = makeAddr("member2");
    address public member3 = makeAddr("member3");
    address public outsider = makeAddr("outsider");

    uint256 public constant PROPERTY_ID = 1;
    bytes32 public constant EVIDENCE_HASH = keccak256("ipfs://evidence");

    function setUp() public {
        vm.startPrank(admin);
        oracle = new CommunityOracle(admin, 2, 7 days);
        oracle.grantRole(oracle.COMMITTEE_MEMBER_ROLE(), member1);
        oracle.grantRole(oracle.COMMITTEE_MEMBER_ROLE(), member2);
        oracle.grantRole(oracle.COMMITTEE_MEMBER_ROLE(), member3);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_QuorumSet() public view {
        assertEq(oracle.quorum(), 2);
    }

    function test_VotingPeriodSet() public view {
        assertEq(oracle.votingPeriod(), 7 days);
    }

    function test_AdminIsMember() public view {
        assertTrue(oracle.hasRole(oracle.COMMITTEE_MEMBER_ROLE(), admin));
    }

    /*//////////////////////////////////////////////////////////////
                          PROPOSAL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ProposeEvent() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);
        assertEq(oracle.proposalCount(), 1);
    }

    function test_Revert_NonMemberCannotPropose() public {
        vm.prank(outsider);
        vm.expectRevert();
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);
    }

    /*//////////////////////////////////////////////////////////////
                            VOTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VoteApprovesProposal() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.prank(member1);
        oracle.voteOnEvent(0, true);

        vm.prank(member2);
        oracle.voteOnEvent(0, true);

        assertEq(uint8(oracle.getProposalState(0)), uint8(ICommunityOracle.ProposalState.APPROVED));
    }

    function test_VoteRejectsProposal() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.prank(member1);
        oracle.voteOnEvent(0, false);

        vm.prank(member2);
        oracle.voteOnEvent(0, false);

        assertEq(uint8(oracle.getProposalState(0)), uint8(ICommunityOracle.ProposalState.REJECTED));
    }

    function test_Revert_DoubleVote() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.prank(member1);
        oracle.voteOnEvent(0, true);

        vm.prank(member1);
        vm.expectRevert();
        oracle.voteOnEvent(0, true);
    }

    function test_Revert_VoteAfterExpiry() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.warp(block.timestamp + 8 days);

        vm.prank(member1);
        vm.expectRevert();
        oracle.voteOnEvent(0, true);
    }

    function test_Revert_NonMemberCannotVote() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.prank(outsider);
        vm.expectRevert();
        oracle.voteOnEvent(0, true);
    }

    /*//////////////////////////////////////////////////////////////
                          VERIFIED EVENTS TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ApprovedEventStoredOnChain() public {
        vm.prank(member1);
        oracle.proposeEvent(PROPERTY_ID, ICommunityOracle.EventType.MAINTENANCE_COMPLETED, EVIDENCE_HASH);

        vm.prank(member1);
        oracle.voteOnEvent(0, true);
        vm.prank(member2);
        oracle.voteOnEvent(0, true);

        bytes32[] memory events = oracle.getVerifiedEvents(PROPERTY_ID);
        assertEq(events.length, 1);
        assertEq(events[0], EVIDENCE_HASH);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_UpdateQuorum() public {
        vm.prank(admin);
        oracle.setQuorum(3);
        assertEq(oracle.quorum(), 3);
    }

    function test_Revert_NonAdminCannotSetQuorum() public {
        vm.prank(outsider);
        vm.expectRevert();
        oracle.setQuorum(3);
    }
}
