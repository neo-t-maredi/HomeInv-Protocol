// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {PropertyPool} from "../../src/core/PropertyPool.sol";
import {PropertyToken} from "../../src/tokens/PropertyToken.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";
import {IPropertyPool} from "../../src/interfaces/IPropertyPool.sol";

contract PropertyPoolTest is Test {
    PropertyPool public pool;
    PropertyToken public token;
    IdentityRegistry public identityRegistry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public rentVault = makeAddr("rentVault");
    address public equityVault = makeAddr("equityVault");

    uint256 public constant PROPERTY_VALUE = 1_000_000e18;
    uint256 public constant TOKEN_PRICE = 1e18;
    uint256 public constant TOTAL_SUPPLY = PROPERTY_VALUE / TOKEN_PRICE;
    bytes32 public constant DOC_HASH = keccak256("property_docs");

    function setUp() public {
        // Step 1 — Deploy
        vm.startPrank(admin);
        jurisdictionRegistry = new JurisdictionRegistry(admin);
        identityRegistry = new IdentityRegistry(admin, address(jurisdictionRegistry));
        identityRegistry.grantRole(identityRegistry.VERIFIER_ROLE(), verifier);
        token = new PropertyToken(
            "HomeInv Test Property",
            "HINV-TEST",
            TOTAL_SUPPLY,
            1,
            PROPERTY_VALUE,
            1,
            DOC_HASH,
            address(identityRegistry),
            admin
        );
        pool = new PropertyPool(
            1,
            PROPERTY_VALUE,
            TOKEN_PRICE,
            block.timestamp + 30 days,
            address(token),
            address(identityRegistry),
            admin
        );
        vm.stopPrank();

        // Step 2 — Verify everyone including pool contract
        vm.startPrank(verifier);
        identityRegistry.verifyIdentity(admin, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(alice, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(bob, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(address(pool), 1, block.timestamp + 365 days, DOC_HASH);
        vm.stopPrank();

        // Step 3 — Transfer supply and ownership to pool
        vm.startPrank(admin);
        token.transfer(address(pool), TOTAL_SUPPLY);
        token.transferOwnership(address(pool));
        vm.stopPrank();
    }

    function test_InitialStatePending() public view {
        assertEq(uint8(pool.state()), uint8(IPropertyPool.PoolState.PENDING));
    }

    function test_OpenFunding() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        pool.openFunding();
        vm.stopPrank();
        assertEq(uint8(pool.state()), uint8(IPropertyPool.PoolState.FUNDING));
    }

    function test_Revert_OpenFundingWithoutVaults() public {
        vm.prank(admin);
        vm.expectRevert();
        pool.openFunding();
    }

    function test_Revert_NonOwnerCannotOpenFunding() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        vm.stopPrank();
        vm.prank(alice);
        vm.expectRevert();
        pool.openFunding();
    }

    function test_Invest() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        pool.openFunding();
        vm.stopPrank();
        vm.prank(alice);
        pool.invest(1000);
        assertEq(token.balanceOf(alice), 1000);
    }

    function test_Revert_InvestWhenNotFunding() public {
        vm.prank(alice);
        vm.expectRevert();
        pool.invest(1000);
    }

    function test_AutoActivatesWhenFunded() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        pool.openFunding();
        vm.stopPrank();
        vm.prank(alice);
        pool.invest(TOTAL_SUPPLY);
        assertEq(uint8(pool.state()), uint8(IPropertyPool.PoolState.ACTIVE));
    }

    function test_ClosePool() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        pool.openFunding();
        vm.stopPrank();
        vm.prank(alice);
        pool.invest(TOTAL_SUPPLY);
        vm.prank(admin);
        pool.closePool();
        assertEq(uint8(pool.state()), uint8(IPropertyPool.PoolState.CLOSED));
    }

    function test_FundingProgressBps() public {
        vm.startPrank(admin);
        pool.setVaults(rentVault, equityVault);
        pool.openFunding();
        vm.stopPrank();
        vm.prank(alice);
        pool.invest(TOTAL_SUPPLY / 2);
        assertEq(pool.fundingProgressBps(), 5000);
    }
}
