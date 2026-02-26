// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {RentVault} from "../../src/vaults/RentVault.sol";
import {PropertyToken} from "../../src/tokens/PropertyToken.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";

contract RentVaultTest is Test {
    RentVault public rentVault;
    PropertyToken public token;
    IdentityRegistry public identityRegistry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public manager = makeAddr("manager");
    address public treasury = makeAddr("treasury");

    uint256 public constant TOTAL_SUPPLY = 1_000_000e18;
    uint256 public constant PROPERTY_VALUE = 1_000_000e18;
    uint256 public constant PROPERTY_ID = 1;
    bytes32 public constant DOC_HASH = keccak256("property_docs");

    function setUp() public {
        // Deploy
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

        rentVault = new RentVault(treasury, admin);
        rentVault.registerProperty(PROPERTY_ID, address(token), manager, 500, 300);
        vm.stopPrank();

        // Verify
        vm.startPrank(verifier);
        identityRegistry.verifyIdentity(admin, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(bob, 1, block.timestamp + 365 days, DOC_HASH);
        vm.stopPrank();

        // Give alice half supply
        vm.prank(admin);
        token.transfer(alice, TOTAL_SUPPLY / 2);
    }

    /*//////////////////////////////////////////////////////////////
                          DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TreasurySet() public view {
        assertEq(rentVault.treasury(), treasury);
    }

    function test_PropertyRegistered() public view {
        (uint256 totalDeposited,,,,,) = rentVault.propertyYields(PROPERTY_ID);
        assertEq(totalDeposited, 0);
    }

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DepositRent() public {
        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);
        assertGt(rentVault.totalRentDeposited(PROPERTY_ID), 0);
    }

    function test_ManagerReceivesCut() public {
        uint256 managerBefore = manager.balance;
        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);
        assertGt(manager.balance, managerBefore);
    }

    function test_TreasuryReceivesCut() public {
        uint256 treasuryBefore = treasury.balance;
        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);
        assertGt(treasury.balance, treasuryBefore);
    }

    function test_Revert_DepositZero() public {
        vm.expectRevert();
        rentVault.depositRent{value: 0}(PROPERTY_ID);
    }

    function test_Revert_DepositUnregisteredProperty() public {
        deal(address(this), 1 ether);
        vm.expectRevert();
        rentVault.depositRent{value: 1 ether}(999);
    }

    /*//////////////////////////////////////////////////////////////
                          YIELD TESTS
    //////////////////////////////////////////////////////////////*/

    function test_PendingYieldAfterDeposit() public {
        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);
        assertGt(rentVault.pendingYield(PROPERTY_ID, alice), 0);
    }

    function test_ClaimYield() public {
        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);

        uint256 aliceBefore = alice.balance;
        vm.prank(alice);
        rentVault.claimYield(PROPERTY_ID);
        assertGt(alice.balance, aliceBefore);
    }

    function test_Revert_ClaimWithNoYield() public {
        vm.prank(alice);
        vm.expectRevert();
        rentVault.claimYield(PROPERTY_ID);
    }

    function test_YieldProportionalToBalance() public {
        // Bob gets quarter supply
        vm.prank(admin);
        token.transfer(bob, TOTAL_SUPPLY / 4);

        deal(address(this), 1 ether);
        rentVault.depositRent{value: 1 ether}(PROPERTY_ID);

        uint256 aliceYield = rentVault.pendingYield(PROPERTY_ID, alice);
        uint256 bobYield = rentVault.pendingYield(PROPERTY_ID, bob);

        // Alice has 2x bob's tokens so should have 2x yield
        assertApproxEqRel(aliceYield, bobYield * 2, 0.01e18);
    }

    /*//////////////////////////////////////////////////////////////
                          ACCESS CONTROL TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Revert_NonOwnerCannotRegisterProperty() public {
        vm.prank(alice);
        vm.expectRevert();
        rentVault.registerProperty(2, address(token), manager, 500, 300);
    }

    function test_Revert_SplitExceedsMax() public {
        vm.prank(admin);
        vm.expectRevert();
        rentVault.registerProperty(2, address(token), manager, 3000, 300);
    }
}