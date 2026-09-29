// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../src/RentVault.sol";
import "../src/JurisdictionRegistry.sol";

contract TestToken is ERC20 {
    bool public fee;
    constructor() ERC20("Test token", "TEST") {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setFee(bool enabled) external {
        fee = enabled;
    }

    function _update(address from, address to, uint256 amount) internal override {
        if (fee && from != address(0) && to != address(0) && amount > 0) {
            super._update(from, to, amount - 1);
            super._update(from, address(0), 1);
        } else {
            super._update(from, to, amount);
        }
    }
}

contract RentVaultTest is Test {
    TestToken token;
    JurisdictionRegistry jurisdictions;
    IdentityRegistry identities;
    PropertyPool pool;
    RentVault rent;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address tenant = address(0x123);
    address tenant2 = address(0x124);
    address treasury = address(0x999);

    function setUp() public {
        token = new TestToken();
        jurisdictions = new JurisdictionRegistry();
        identities = new IdentityRegistry(address(jurisdictions));
        identities.verifyIdentity(
            alice, IdentityRegistry.IdentityType.IMPACT_INVESTOR, "ZA", block.timestamp + 365 days
        );
        identities.verifyIdentity(bob, IdentityRegistry.IdentityType.IMPACT_INVESTOR, "ZA", block.timestamp + 365 days);
        identities.verifyIdentity(
            tenant, IdentityRegistry.IdentityType.LOCAL_RESIDENT, "ZA", block.timestamp + 365 days
        );
        identities.verifyIdentity(
            tenant2, IdentityRegistry.IdentityType.LOCAL_RESIDENT, "ZA", block.timestamp + 365 days
        );
        pool = new PropertyPool(address(this), "Illustrative property", 1000, 0, address(token), address(identities));
        rent = new RentVault(address(pool), address(identities), address(token), treasury, 7000, 1000, 2000);
        token.mint(alice, 600);
        token.mint(bob, 400);
        vm.startPrank(alice);
        token.approve(address(pool), 600);
        pool.contribute(600);
        vm.stopPrank();
        vm.startPrank(bob);
        token.approve(address(pool), 400);
        pool.contribute(400);
        vm.stopPrank();
        pool.activatePool();
    }

    function pay(address payer, uint256 amount) internal {
        token.mint(payer, amount);
        vm.startPrank(payer);
        token.approve(address(rent), amount);
        rent.payRent(amount);
        vm.stopPrank();
    }

    function testPaymentConservesFunds() public {
        pay(tenant, 1000);
        assertEq(token.balanceOf(treasury), 100);
        assertEq(rent.totalInvestorAccrued(), 700);
        assertEq(rent.tenantEquity(tenant), 200);
        assertEq(
            rent.totalRentReceived(),
            rent.totalInvestorAccrued() + rent.totalTreasuryPaid() + rent.totalEquityReserved()
        );
        assertEq(token.balanceOf(address(rent)), 900);
    }

    function testRepeatClaimBlockedAndEquityProtected() public {
        pay(tenant, 1000);
        rent.claimYield(alice);
        assertEq(token.balanceOf(alice), 420);
        vm.expectRevert("No yield available");
        rent.claimYield(alice);
        rent.claimYield(bob);
        assertEq(token.balanceOf(bob), 280);
        assertEq(token.balanceOf(address(rent)), 200);
    }

    function testClaimOrderDoesNotChangeEntitlements() public {
        pay(tenant, 1000);
        rent.claimYield(bob);
        rent.claimYield(alice);
        assertEq(token.balanceOf(alice), 420);
        assertEq(token.balanceOf(bob), 280);
    }

    function testMultiplePaymentsOnlyNewYieldClaimable() public {
        pay(tenant, 1000);
        rent.claimYield(alice);
        pay(tenant, 500);
        assertEq(rent.pendingYield(alice), 210);
        assertEq(rent.pendingYield(bob), 420);
        rent.claimYield(alice);
        rent.claimYield(bob);
        assertEq(token.balanceOf(alice), 630);
        assertEq(token.balanceOf(bob), 420);
        assertEq(token.balanceOf(address(rent)), 300);
    }

    function testDonationDoesNotBecomeYield() public {
        pay(tenant, 1000);
        token.mint(address(rent), 10000);
        assertEq(rent.pendingYield(alice), 420);
        rent.claimYield(alice);
        rent.claimYield(bob);
        assertEq(token.balanceOf(address(rent)), 10200);
    }

    function testSplitUpdatesOnlyAffectFutureRent() public {
        pay(tenant, 1000);
        rent.updateSplits(5000, 1000, 4000);
        pay(tenant, 1000);
        assertEq(rent.pendingYield(alice), 720);
        assertEq(rent.pendingYield(bob), 480);
        assertEq(rent.totalEquityReserved(), 600);
        assertEq(token.balanceOf(treasury), 200);
    }

    function testTenantReservesAreSeparate() public {
        pay(tenant, 1000);
        pay(tenant2, 500);
        assertEq(rent.tenantEquity(tenant), 200);
        assertEq(rent.tenantEquity(tenant2), 100);
        assertEq(rent.totalEquityReserved(), 300);
    }

    function testRoundingRemainderGoesToEquity() public {
        pay(tenant, 11);
        assertEq(rent.totalInvestorAccrued(), 7);
        assertEq(rent.totalTreasuryPaid(), 1);
        assertEq(rent.totalEquityReserved(), 3);
        rent.claimYield(alice);
        rent.claimYield(bob);
        assertEq(token.balanceOf(address(rent)), 4); // 3 equity + 1 investor rounding dust
        pay(tenant, 9); // cumulative investor pool 13; Alice 7, Bob 5
        assertEq(rent.pendingYield(alice), 3);
        assertEq(rent.pendingYield(bob), 3);
    }

    function testFinalYieldClaimableAfterCompletion() public {
        pay(tenant, 1000);
        pool.completePool();
        rent.claimYield(alice);
        assertEq(token.balanceOf(alice), 420);
        vm.prank(tenant);
        vm.expectRevert("Pool is not active");
        rent.payRent(1);
    }

    function testThirdPartyClaimPaysInvestor() public {
        pay(tenant, 1000);
        vm.prank(tenant2);
        rent.claimYield(alice);
        assertEq(token.balanceOf(alice), 420);
        assertEq(token.balanceOf(tenant2), 0);
    }

    function testExpiredIdentityCannotClaim() public {
        pay(tenant, 1000);
        vm.warp(block.timestamp + 366 days);
        vm.expectRevert("Identity not verified");
        rent.claimYield(alice);
        assertEq(rent.pendingYield(alice), 420);
    }

    function testUnverifiedPayerRejected() public {
        vm.prank(address(0xBAD));
        vm.expectRevert("Identity not verified");
        rent.payRent(100);
    }

    function testNonOwnerCannotChangeSplits() public {
        vm.prank(tenant);
        vm.expectRevert();
        rent.updateSplits(10000, 0, 0);
    }

    function testInvalidSplitRejected() public {
        vm.expectRevert("Splits must add up to 10000");
        rent.updateSplits(7000, 1000, 1000);
    }

    function testFeeTokenRentRejectedWithoutAccountingChanges() public {
        token.setFee(true);
        token.mint(tenant, 1000);
        vm.startPrank(tenant);
        token.approve(address(rent), 1000);
        vm.expectRevert("Unsupported transfer fee");
        rent.payRent(1000);
        vm.stopPrank();
        assertEq(rent.totalRentReceived(), 0);
        assertEq(token.balanceOf(tenant), 1000);
    }

    function testFeeTokenContributionRejected() public {
        PropertyPool other = new PropertyPool(address(this), "Test", 1000, 0, address(token), address(identities));
        token.mint(alice, 1000);
        token.setFee(true);
        vm.startPrank(alice);
        token.approve(address(other), 1000);
        vm.expectRevert("Unsupported transfer fee");
        other.contribute(1000);
        vm.stopPrank();
        assertEq(other.totalRaised(), 0);
    }

    function testCannotChangeContributionWeightsAfterActivation() public {
        vm.prank(alice);
        vm.expectRevert("Pool is not in funding state");
        pool.contribute(1);
    }

    function testFuzzConservationAcrossInterleavedClaims(uint64 first, uint64 second) public {
        uint256 a = bound(uint256(first), 10, 1e15);
        uint256 b = bound(uint256(second), 10, 1e15);
        pay(tenant, a);
        rent.claimYield(alice);
        pay(tenant2, b);
        rent.claimYield(bob);
        if (rent.pendingYield(alice) > 0) rent.claimYield(alice);
        assertEq(
            token.balanceOf(alice) + token.balanceOf(bob) + token.balanceOf(treasury) + token.balanceOf(address(rent)),
            a + b
        );
        assertGe(token.balanceOf(address(rent)), rent.totalEquityReserved());
        assertEq(
            rent.totalRentReceived(),
            rent.totalInvestorAccrued() + rent.totalTreasuryPaid() + rent.totalEquityReserved()
        );
        assertEq(rent.pendingYield(alice), 0);
        assertEq(rent.pendingYield(bob), 0);
    }
}
