// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "lib/forge-std/src/Test.sol";
import {JurisdictionRegistry} from "../../src/registries/JurisdictionRegistry.sol";

contract JurisdictionRegistryTest is Test {
    JurisdictionRegistry public registry;
    address public owner = makeAddr("owner");

    function setUp() public {
        vm.startPrank(owner);
        registry = new JurisdictionRegistry(owner);

        // Seed FICA tiers
        registry.setFICATier(0, 0, 10_000e18, 1, false);
        registry.setFICATier(1, 10_000e18, 100_000e18, 2, false);
        registry.setFICATier(2, 100_000e18, type(uint256).max, 3, true);

        // Seed transfer duty bands
        registry.setTransferDutyBand(0, 1_000_000e18, 0);
        registry.setTransferDutyBand(1, 2_750_000e18, 300);
        registry.setTransferDutyBand(2, type(uint256).max, 600);

        vm.stopPrank();
    }

    function test_GetFICATierBasic() public view {
        (, JurisdictionRegistry.FICATier memory tier) = registry.getApplicableFICATier(500e18);
        assertEq(tier.requiredDocuments, 1);
    }

    function test_GetFICATierStandard() public view {
        (, JurisdictionRegistry.FICATier memory tier) = registry.getApplicableFICATier(50_000e18);
        assertEq(tier.requiredDocuments, 2);
    }

    function test_GetFICATierEnhanced() public view {
        (, JurisdictionRegistry.FICATier memory tier) = registry.getApplicableFICATier(500_000e18);
        assertEq(tier.requiredDocuments, 3);
    }

    function test_TransferDutyZeroBeforeThreshold() public view {
        uint256 duty = registry.calculateTransferDuty(900_000e18);
        assertEq(duty, 0);
    }

    function test_TransferDutyCalculation() public view {
        uint256 duty = registry.calculateTransferDuty(2_000_000e18);
        assertGt(duty, 0);
    }

    function test_ExceedsSARBLimit() public view {
        assertTrue(registry.exceedsSARBLimit(11_000_000e18));
    }

    function test_WithinSARBLimit() public view {
        assertFalse(registry.exceedsSARBLimit(9_000_000e18));
    }

    function test_RequiresBeneficialOwnership() public view {
        assertTrue(registry.requiresBeneficialOwnershipReport(26_000_000e18));
    }

    function test_NoBeneficialOwnershipRequired() public view {
        assertFalse(registry.requiresBeneficialOwnershipReport(24_000_000e18));
    }


    function test_OnlyOwnerCanSetTier() public {
        vm.prank(makeAddr("random"));
        vm.expectRevert();
        registry.setFICATier(0, 0, 1000e18, 1, false);
    }
}
