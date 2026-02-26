// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {REITFactory} from "../../src/factory/REITFactory.sol";
import {RentVault} from "../../src/vaults/RentVault.sol";
import {EquityVault} from "../../src/vaults/EquityVault.sol";
import {CommunityOracle} from "../../src/oracle/CommunityOracle.sol";
import {IdentityRegistry} from "../../src/registries/IdentityRegistry.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";
import {PropertyToken} from "../../src/tokens/PropertyToken.sol";
import {PropertyPool} from "../../src/core/PropertyPool.sol";

contract REITFactoryTest is Test {
    REITFactory public factory;
    RentVault public rentVault;
    EquityVault public equityVault;
    CommunityOracle public oracle;
    IdentityRegistry public identityRegistry;
    JurisdictionRegistry public jurisdictionRegistry;

    address public admin = makeAddr("admin");
    address public verifier = makeAddr("verifier");
    address public developer = makeAddr("developer");
    address public manager = makeAddr("manager");
    address public treasury = makeAddr("treasury");
    address public investor = makeAddr("investor");

    bytes32 public constant DOC_HASH = keccak256("property_docs");

    function setUp() public {
        vm.startPrank(admin);

        jurisdictionRegistry = new JurisdictionRegistry(admin);
        identityRegistry = new IdentityRegistry(admin, address(jurisdictionRegistry));
        identityRegistry.grantRole(identityRegistry.VERIFIER_ROLE(), verifier);

        rentVault = new RentVault(treasury, admin);
        equityVault = new EquityVault(admin);
        oracle = new CommunityOracle(admin, 2, 7 days);

        factory = new REITFactory(
            address(identityRegistry),
            address(jurisdictionRegistry),
            address(rentVault),
            address(equityVault),
            treasury,
            admin
        );

        // Authorise factory as allocator in EquityVault
        equityVault.setAllocator(address(factory), true);

        // Grant factory verifier role so it can verify pools it deploys
        identityRegistry.grantRole(identityRegistry.VERIFIER_ROLE(), address(factory));

        // Transfer vault ownership to factory
        rentVault.transferOwnership(address(factory));
        equityVault.transferOwnership(address(factory));

        vm.stopPrank();


        // Verify developer and investor
        vm.startPrank(verifier);
        identityRegistry.verifyIdentity(developer, 3, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(investor, 1, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(admin, 3, block.timestamp + 365 days, DOC_HASH);
        identityRegistry.verifyIdentity(address(factory), 3, block.timestamp + 365 days, DOC_HASH);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_FactoryDeployed() public view {
        assertEq(address(factory.identityRegistry()), address(identityRegistry));
        assertEq(address(factory.rentVault()), address(rentVault));
        assertEq(address(factory.equityVault()), address(equityVault));
    }

    /*//////////////////////////////////////////////////////////////
                      SUBMIT PROPERTY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SubmitProperty() public {
        vm.prank(developer);
        (uint256 propertyId, address propertyToken, address propertyPool) = factory.submitProperty(
            "HomeInv 14 Buitenkant Street",
            "HINV-14BS",
            1_000_000e18,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );

        assertEq(propertyId, 0);
        assertFalse(propertyToken == address(0));
        assertFalse(propertyPool == address(0));
    }

    function test_PropertyCountIncreases() public {
        vm.prank(developer);
        factory.submitProperty(
            "HomeInv Property 1",
            "HINV-1",
            1_000_000e18,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );

        assertEq(factory.propertyCount(), 1);
    }

    function test_Revert_UnverifiedDeveloper() public {
        address unverified = makeAddr("unverified");
        vm.prank(unverified);
        vm.expectRevert();
        factory.submitProperty(
            "HomeInv Property",
            "HINV",
            1_000_000e18,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );
    }

    function test_Revert_InsufficientKYCTier() public {
        // investor only has tier 1 — needs tier 3
        vm.prank(investor);
        vm.expectRevert();
        factory.submitProperty(
            "HomeInv Property",
            "HINV",
            1_000_000e18,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );
    }

    function test_Revert_ZeroPropertyValue() public {
        vm.prank(developer);
        vm.expectRevert();
        factory.submitProperty(
            "HomeInv Property",
            "HINV",
            0,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );
    }

    /*//////////////////////////////////////////////////////////////
                      INTEGRATION FLOW TEST
    //////////////////////////////////////////////////////////////*/

    function test_FullPropertyLifecycle() public {
        // 1. Developer submits property
        vm.prank(developer);
        (, address propertyToken, address propertyPool) = factory.submitProperty(
            "HomeInv 14 Buitenkant Street",
            "HINV-14BS",
            1_000_000e18,
            1e18,
            block.timestamp + 30 days,
            1,
            DOC_HASH,
            manager
        );

        // 2. Verify pool contract and open funding
        vm.prank(verifier);
        identityRegistry.verifyIdentity(propertyPool, 1, block.timestamp + 365 days, DOC_HASH);

        vm.startPrank(address(factory));
        PropertyPool(propertyPool).setVaults(address(rentVault), address(equityVault));
        PropertyPool(propertyPool).openFunding();
        vm.stopPrank();

        // 3. Verify investor and invest
        vm.prank(verifier);
        identityRegistry.verifyIdentity(investor, 1, block.timestamp + 365 days, DOC_HASH);

        vm.prank(investor);
        PropertyPool(propertyPool).invest(1000);

        assertEq(PropertyToken(propertyToken).balanceOf(investor), 1000);
    }
}
