// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./PropertyPool.sol";
import "./IdentityRegistry.sol";

/// @notice Allocates rent between investor entitlements, treasury and reserved tenant equity.
/// @dev Equity is an accounting reserve, not a property ownership token or a redeemable claim.
/// Supports a standard, non-rebasing, exact-transfer ERC20 only.
contract RentVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    PropertyPool public immutable propertyPool;
    IdentityRegistry public immutable identityRegistry;
    IERC20 public immutable stablecoin;
    address public immutable treasury;

    uint256 public investorSplit;
    uint256 public treasurySplit;
    uint256 public equitySplit;
    uint256 public totalRentReceived;
    uint256 public totalInvestorAccrued;
    uint256 public totalInvestorClaimed;
    uint256 public totalTreasuryPaid;
    uint256 public totalEquityReserved;
    mapping(address => uint256) public claimedYield;
    mapping(address => uint256) public tenantEquity;

    event RentAllocated(
        address indexed tenant, uint256 amount, uint256 investorAmount, uint256 treasuryAmount, uint256 equityAmount
    );
    event YieldClaimed(address indexed investor, uint256 amount);
    event SplitsUpdated(uint256 investorSplit, uint256 treasurySplit, uint256 equitySplit);

    constructor(
        address _propertyPool,
        address _identityRegistry,
        address _stablecoin,
        address _treasury,
        uint256 _investorSplit,
        uint256 _treasurySplit,
        uint256 _equitySplit
    ) Ownable(msg.sender) {
        require(
            _propertyPool.code.length > 0 && _identityRegistry.code.length > 0 && _stablecoin.code.length > 0,
            "Invalid contract"
        );
        require(_treasury != address(0) && _treasury != address(this), "Invalid treasury");
        propertyPool = PropertyPool(_propertyPool);
        identityRegistry = IdentityRegistry(_identityRegistry);
        stablecoin = IERC20(_stablecoin);
        require(address(propertyPool.stablecoin()) == _stablecoin, "Pool token mismatch");
        require(address(propertyPool.identityRegistry()) == _identityRegistry, "Pool identity mismatch");
        treasury = _treasury;
        _setSplits(_investorSplit, _treasurySplit, _equitySplit);
    }

    function payRent(uint256 amount) external nonReentrant {
        require(propertyPool.getPoolState() == PropertyPool.PoolState.ACTIVE, "Pool is not active");
        require(identityRegistry.isVerified(msg.sender), "Identity not verified");
        require(amount > 0, "Amount must be greater than 0");
        uint256 balanceBefore = stablecoin.balanceOf(address(this));
        stablecoin.safeTransferFrom(msg.sender, address(this), amount);
        require(stablecoin.balanceOf(address(this)) - balanceBefore == amount, "Unsupported transfer fee");

        uint256 investorAmount = Math.mulDiv(amount, investorSplit, 10_000);
        uint256 treasuryAmount = Math.mulDiv(amount, treasurySplit, 10_000);
        // Assign the split-rounding remainder to tenant equity so every unit is allocated.
        uint256 equityAmount = amount - investorAmount - treasuryAmount;
        totalRentReceived += amount;
        totalInvestorAccrued += investorAmount;
        totalTreasuryPaid += treasuryAmount;
        totalEquityReserved += equityAmount;
        tenantEquity[msg.sender] += equityAmount;

        if (treasuryAmount > 0) stablecoin.safeTransfer(treasury, treasuryAmount);
        emit RentAllocated(msg.sender, amount, investorAmount, treasuryAmount, equityAmount);
    }

    /// @notice Historical rent entitlement less previously claimed yield.
    /// @dev Contribution weights cannot change after pool activation.
    /// Direct token donations and the equity reserve do not enter the calculation.
    function pendingYield(address investor) public view returns (uint256) {
        uint256 entitlement =
            Math.mulDiv(totalInvestorAccrued, propertyPool.getContribution(investor), propertyPool.fundingTarget());
        return entitlement - claimedYield[investor];
    }

    /// @notice Anyone can trigger a claim, but payment always goes to the investor.
    /// Final accrued yield remains claimable after pool completion.
    function claimYield(address investor) external nonReentrant {
        require(propertyPool.getPoolState() != PropertyPool.PoolState.FUNDING, "Pool not activated");
        require(identityRegistry.isVerified(investor), "Identity not verified");
        uint256 amount = pendingYield(investor);
        require(amount > 0, "No yield available");
        claimedYield[investor] += amount;
        totalInvestorClaimed += amount;
        stablecoin.safeTransfer(investor, amount);
        emit YieldClaimed(investor, amount);
    }

    function updateSplits(uint256 investors, uint256 protocol, uint256 equity) external onlyOwner {
        _setSplits(investors, protocol, equity);
    }

    function _setSplits(uint256 investors, uint256 protocol, uint256 equity) internal {
        require(investors <= 10_000 && protocol <= 10_000 && equity <= 10_000, "Invalid split");
        require(investors + protocol + equity == 10_000, "Splits must add up to 10000");
        investorSplit = investors;
        treasurySplit = protocol;
        equitySplit = equity;
        emit SplitsUpdated(investors, protocol, equity);
    }
}
