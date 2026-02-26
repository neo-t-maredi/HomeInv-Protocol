// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {EquityVault} from "../../src/vaults/EquityVault.sol";
import {PropertyToken} from "../../src/tokens/PropertyToken.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";

contract EquityVaultTest is Test {
    EquityVault public equityVault;
    PropertyToken public token;
    IdentityRegistry public identityRegistry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public alice = makeAddr("alice");
    address public allocator = makeAddr("allocator");

    uint256 public constant TOTAL_SUPPLY = 1_000_000e18;
    uint256 public constant PROPERTY_VALUE = 1_000_000e18;
    uint256 public constant PROPERTY_ID = 1;
    uint256 public constant THRESHOLD = 1000e18;
    uint256 public constant EQUITY_RATE_BPS = 500;
    bytes32 public constant DOC_HASH = keccak256("property_docs");

    function setUp() public {
        vm.startPrank(admin);
        jurisdictionRegistry = new JurisdictionRegistry(admin);
        identityRegistry = new IdentityRegistry(admin, address(jurisdictionRegistry));
        identityRegistry.grantRole(identityRegistry.VERIFIER_ROLE(), verifier);

        token = new PropertyToken(
            "HomeInv Test Property",
            "HINV-TEST",
            TOTAL_SUPPLY,
            PROPERTY_ID,
            PROPERTY_VALUE,
            1,
            DOC_HASH,
            address(identityRegistry),
            admin
        );

        equityVault = new EquityVault(admin);
        equityVault.configureProperty(PROPERTY_ID, address(token), THRESHOLD, EQUITY_RATE_BPS);
        equityVault.setAllocator(allocator, true);
        vm.stopPrank();

        vm.startPrank(verifier);
        identityRegistry.verifyIdentity(admin, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(address(equityVault), 1, block.timestamp + 365 days, DOC_HASH);
        vm.stopPrank();

        // Give equityVault tokens to distribute
        vm.prank(admin);
        token.transfer(address(equityVault), TOTAL_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PropertyConfigured() public view {
        (address propertyToken,,,bool active) = equityVault.propertyConfigs(PROPERTY_ID);
        assertTrue(active);
        assertEq(propertyToken, address(token));
    }

    function test_AllocatorSet() public view {
        assertTrue(equityVault.authorisedAllocators(allocator));
    }

    /*//////////////////////////////////////////////////////////////
                          ALLOCATION TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AllocateEquity() public {
        vm.prank(allocator);
        equityVault.allocateEquity(alice, PROPERTY_ID, 10_000e18);
        assertGt(equityVault.pendingEquity(alice, PROPERTY_ID), 0);
    }

    function test_Revert_UnauthorisedAllocator() public {
        vm.prank(alice);
        vm.expectRevert();
        equityVault.allocateEquity(alice, PROPERTY_ID, 1000e18);
    }

    function test_Revert_AllocateZero() public {
        vm.prank(allocator);
        vm.expectRevert();
        equityVault.allocateEquity(alice, PROPERTY_ID, 0);
    }

    /*//////////////////////////////////////////////////////////////
                          CLAIM TESTS
    //////////////////////////////////////////////////////////////*/

    function test_ClaimEquityTokens() public {
        // Allocate enough to exceed threshold
        vm.prank(allocator);
        equityVault.allocateEquity(alice, PROPERTY_ID, 1_000_000e18);

        uint256 aliceBefore = token.balanceOf(alice);
        vm.prank(alice);
        equityVault.claimEquityTokens(PROPERTY_ID);
        assertGt(token.balanceOf(alice), aliceBefore);
    }

    function test_Revert_ClaimBelowThreshold() public {
        vm.prank(allocator);
        equityVault.allocateEquity(alice, PROPERTY_ID, 100e18);

        vm.prank(alice);
        vm.expectRevert();
        equityVault.claimEquityTokens(PROPERTY_ID);
    }

    function test_Revert_ClaimWithNoCredits() public {
        vm.prank(alice);
        vm.expectRevert();
        equityVault.claimEquityTokens(PROPERTY_ID);
    }

    function test_CreditsResetAfterClaim() public {
        vm.prank(allocator);
        equityVault.allocateEquity(alice, PROPERTY_ID, 1_000_000e18);

        vm.prank(alice);
        equityVault.claimEquityTokens(PROPERTY_ID);

        assertEq(equityVault.pendingEquity(alice, PROPERTY_ID), 0);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Revert_NonOwnerCannotConfigure() public {
        vm.prank(alice);
        vm.expectRevert();
        equityVault.configureProperty(2, address(token), THRESHOLD, EQUITY_RATE_BPS);
    }

    function test_Revert_NonOwnerCannotSetAllocator() public {
        vm.prank(alice);
        vm.expectRevert();
        equityVault.setAllocator(alice, true);
    }
}
