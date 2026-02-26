// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";

contract IdentityRegistryTest is Test {
    IdentityRegistry public registry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    bytes32 public constant DOC_HASH = keccak256("alice_fica_docs");

    function setUp() public {
        vm.startPrank(admin);
        jurisdictionRegistry = new JurisdictionRegistry(admin);
        registry = new IdentityRegistry(admin, address(jurisdictionRegistry));
        registry.grantRole(registry.VERIFIER_ROLE(), verifier);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                          VERIFICATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_VerifyIdentity() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        assertTrue(registry.isVerified(alice));
    }

    function test_CorrectKYCTier() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 2, block.timestamp + 365 days, DOC_HASH);
        assertTrue(registry.meetsKYCTier(alice, 2));
    }

    function test_DoesNotMeetHigherTier() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        assertFalse(registry.meetsKYCTier(alice, 2));
    }

    function test_RevokeIdentity() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);

        vm.prank(verifier);
        registry.revokeIdentity(alice);

        assertFalse(registry.isVerified(alice));
    }

    /*//////////////////////////////////////////////////////////////
                          SANCTION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SanctionAddress() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);

        vm.prank(admin);
        registry.sanctionAddress(alice);

        assertFalse(registry.isVerified(alice));
    }

    function test_SanctionedCannotBeVerified() public {
        vm.prank(admin);
        registry.sanctionAddress(alice);

        vm.prank(verifier);
        vm.expectRevert();
        registry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
    }

    /*//////////////////////////////////////////////////////////////
                          EXPIRY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ExpiredIdentityNotVerified() public {
        vm.prank(verifier);
        registry.verifyIdentity(alice, 1, block.timestamp + 1 days, DOC_HASH);

        vm.warp(block.timestamp + 2 days);

        assertFalse(registry.isVerified(alice));
    }

    /*//////////////////////////////////////////////////////////////
                          ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Revert_NonVerifierCannotVerify() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.verifyIdentity(bob, 1, block.timestamp + 365 days, DOC_HASH);
    }

    function test_Revert_NonAdminCannotSanction() public {
        vm.prank(alice);
        vm.expectRevert();
        registry.sanctionAddress(bob);
    }
}