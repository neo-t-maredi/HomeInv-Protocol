// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title RentVault
 * @notice Receives rent payments in stablecoins and automatically splits
 * every payment three ways — yield to investors, cut to protocol treasury,
 * and a portion to EquityVault where it accumulates toward tenant ownership.
 * This is the mechanic that turns tenants into owners.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PropertyPool.sol";
import "./IdentityRegistry.sol";

contract RentVault is Ownable {
    using SafeERC20 for IERC20;

    PropertyPool public propertyPool;
    IdentityRegistry public identityRegistry;
    IERC20 public stablecoin;

    address public treasury;

    // Split percentages in basis points — must add up to 10000
    uint256 public investorSplit; // e.g. 7000 = 70%
    uint256 public treasurySplit; // e.g. 1000 = 10%
    uint256 public equitySplit; // e.g. 2000 = 20%

    uint256 public totalRentReceived;

    event RentReceived(
        address indexed tenant,
        uint256 amount,
        uint256 timestamp
    );
    event YieldDistributed(
        uint256 investorAmount,
        uint256 treasuryAmount,
        uint256 equityAmount
    );

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
            _investorSplit + _treasurySplit + _equitySplit == 10000,
            "Splits must add up to 10000"
        );

        propertyPool = PropertyPool(_propertyPool);
        identityRegistry = IdentityRegistry(_identityRegistry);
        stablecoin = IERC20(_stablecoin);
        treasury = _treasury;
        investorSplit = _investorSplit;
        treasurySplit = _treasurySplit;
        equitySplit = _equitySplit;
    }

    // Tenant pays rent in stablecoins
    // Automatically splits payment between investors, treasury and equity vault
    // Pool must be ACTIVE before rent can be received
    function payRent(uint256 _amount) external {
        require(
            propertyPool.getPoolState() == PropertyPool.PoolState.ACTIVE,
            "Pool is not active"
        );
        require(identityRegistry.isVerified(msg.sender), "Not FICA verified");
        require(_amount > 0, "Amount must be greater than 0");

        stablecoin.safeTransferFrom(msg.sender, address(this), _amount);

        uint256 investorAmount = (_amount * investorSplit) / 10000;
        uint256 treasuryAmount = (_amount * treasurySplit) / 10000;
        uint256 equityAmount = (_amount * equitySplit) / 10000;

        // Send treasury cut immediately
        stablecoin.safeTransfer(treasury, treasuryAmount);

        totalRentReceived += _amount;

        emit RentReceived(msg.sender, _amount, block.timestamp);
        emit YieldDistributed(investorAmount, treasuryAmount, equityAmount);
    }

    // Investors claim their proportional yield based on contribution to the pool
    // Yield is calculated based on their share of total funding
    function claimYield(address _investor) external {
        require(
            propertyPool.getPoolState() == PropertyPool.PoolState.ACTIVE,
            "Pool is not active"
        );
        require(identityRegistry.isVerified(_investor), "Not FICA verified");

        uint256 contribution = propertyPool.getContribution(_investor);
        require(contribution > 0, "No contribution found");

        uint256 fundingTarget = propertyPool.fundingTarget();
        uint256 availableYield = (stablecoin.balanceOf(address(this)) *
            contribution) / fundingTarget;
        require(availableYield > 0, "No yield available");

        stablecoin.safeTransfer(_investor, availableYield);
    }

    // Allows owner to update rent split percentages
    // Splits must always add up to 10000 basis points
    function updateSplits(
        uint256 _investorSplit,
        uint256 _treasurySplit,
        uint256 _equitySplit
    ) external onlyOwner {
        require(
            _investorSplit + _treasurySplit + _equitySplit == 10000,
            "Splits must add up to 10000"
        );

        investorSplit = _investorSplit;
        treasurySplit = _treasurySplit;
        equitySplit = _equitySplit;
    }
}
