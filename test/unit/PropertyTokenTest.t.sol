// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {PropertyToken} from "../../src/tokens/PropertyToken.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";

contract PropertyTokenTest is Test {
    PropertyToken public token;
    IdentityRegistry public identityRegistry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant TOTAL_SUPPLY = 1_000_000e18;
    uint256 public constant PROPERTY_VALUE = 1_000_000e18;
    bytes32 public constant DOC_HASH = keccak256("property_docs");

    function setUp() public {
        vm.startPrank(admin);

        jurisdictionRegistry = new JurisdictionRegistry(admin);
        identityRegistry = new IdentityRegistry(admin, address(jurisdictionRegistry));
        identityRegistry.grantRole(identityRegistry.VERIFIER_ROLE(), verifier);

        token = new PropertyToken(
            "HomeInv 14 Buitenkant Street",
            "HINV-14BS",
            TOTAL_SUPPLY,
            1,
            PROPERTY_VALUE,
            1,
            DOC_HASH,
            address(identityRegistry),
            admin
        );

        vm.stopPrank();

        // Verify alice and bob
        vm.startPrank(verifier);
        identityRegistry.verifyIdentity(admin, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(bob, 1, block.timestamp + 365 days, DOC_HASH);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
    }

    function test_AdminReceivesSupply() public view {
        assertEq(token.balanceOf(admin), TOTAL_SUPPLY);
    }

    function test_PropertyId() public view {
        assertEq(token.propertyId(), 1);
    }

    function test_PropertyValue() public view {
        assertEq(token.propertyValue(), PROPERTY_VALUE);
    }

    /*//////////////////////////////////////////////////////////////
                          TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TransferBetweenVerifiedUsers() public {
        vm.prank(admin);
        token.transfer(alice, 1000e18);

        vm.prank(alice);
        token.transfer(bob, 500e18);

        assertEq(token.balanceOf(bob), 500e18);
    }

    function test_Revert_TransferToUnverifiedUser() public {
        address unverified = makeAddr("unverified");
        vm.prank(admin);
        vm.expectRevert();
        token.transfer(unverified, 1000e18);
    }

    function test_Revert_TransferFromUnverifiedUser() public {
        address unverified = makeAddr("unverified");
        vm.prank(unverified);
        vm.expectRevert();
        token.transfer(alice, 1000e18);
    }

    function test_Revert_TransferWhenPaused() public {
        vm.prank(admin);
        token.transfer(alice, 1000e18);

        vm.prank(admin);
        token.pauseTransfers();

        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 500e18);
    }

    /*//////////////////////////////////////////////////////////////
                          PAUSE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PauseAndUnpause() public {
        vm.prank(admin);
        token.pauseTransfers();
        assertTrue(token.transfersPaused());

        vm.prank(admin);
        token.unpauseTransfers();
        assertFalse(token.transfersPaused());
    }

    function test_Revert_NonOwnerCannotPause() public {
        vm.prank(alice);
        vm.expectRevert();
        token.pauseTransfers();
    }

    /*//////////////////////////////////////////////////////////////
                          VIEW TESTS
    //////////////////////////////////////////////////////////////*/

    function test_CanHold() public view {
        assertTrue(token.canHold(alice));
    }

    function test_CannotHoldUnverified() public {
        assertFalse(token.canHold(makeAddr("unverified")));
    }

    function test_OwnershipBps() public {
        vm.prank(admin);
        token.transfer(alice, TOTAL_SUPPLY / 2);
        assertEq(token.ownershipBps(alice), 5000);
    }
}
