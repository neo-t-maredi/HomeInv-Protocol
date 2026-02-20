// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PropertyPool
 * @notice One deployed per property via REITFactory. Manages the full
 * lifecycle of a development — from investor funding through to tenant
 * ownership. State machine enforces correct order of operations.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IdentityRegistry.sol";

contract PropertyPool is Ownable {
    using SafeERC20 for IERC20;
    IdentityRegistry public identityRegistry;

    enum PoolState {
        FUNDING,
        ACTIVE,
        COMPLETE
    }

    PoolState public state;

    address public developer;
    string public location;
    uint256 public fundingTarget;
    uint256 public projectedYield;
    uint256 public totalRaised;
    IERC20 public stablecoin;

    mapping(address => uint256) public contributions;

    event ContributionMade(address indexed investor, uint256 amount);
    event PoolActivated(uint256 timestamp);
    event PoolCompleted(uint256 timestamp);

    constructor(
        address _developer,
        string memory _location,
        uint256 _fundingTarget,
        uint256 _projectedYield,
        address _stablecoin,
        address _identityRegistry
    ) Ownable(msg.sender) {
        developer = _developer;
        location = _location;
        fundingTarget = _fundingTarget;
        projectedYield = _projectedYield;
        stablecoin = IERC20(_stablecoin);
        identityRegistry = IdentityRegistry(_identityRegistry);
        state = PoolState.FUNDING;
    }
    // Investors contribute stablecoins toward the funding target
    // Must be FICA verified and pool must be in FUNDING state
    function contribute(uint256 _amount) external {
        require(state == PoolState.FUNDING, "Pool is not in funding state");
        require(identityRegistry.isVerified(msg.sender), "Not FICA verified");
        require(_amount > 0, "Amount must be greater than 0");
        require(
            totalRaised + _amount <= fundingTarget,
            "Exceeds funding target"
        );

        stablecoin.safeTransferFrom(msg.sender, address(this), _amount);

        contributions[msg.sender] += _amount;
        totalRaised += _amount;

        emit ContributionMade(msg.sender, _amount);
    }

    // Transitions pool from FUNDING to ACTIVE state
    // Called by CommunityOracle once building completion is verified on the ground
    function activatePool() external onlyOwner {
        require(state == PoolState.FUNDING, "Pool is not in funding state");
        require(totalRaised >= fundingTarget, "Funding target not reached");

        state = PoolState.ACTIVE;

        emit PoolActivated(block.timestamp);
    }

    // Transitions pool from ACTIVE to COMPLETE
    // Called when tenants have accumulated full ownership through rent-to-equity
    function completePool() external onlyOwner {
        require(state == PoolState.ACTIVE, "Pool is not in active state");

        state = PoolState.COMPLETE;

        emit PoolCompleted(block.timestamp);
    }

    // Returns the contribution amount for a specific investor
    // Used by frontend and RentVault to calculate yield distribution
    function getContribution(
        address _investor
    ) external view returns (uint256) {
        return contributions[_investor];
    }

    // Returns current pool state — used by frontend and other contracts to gate actions
    function getPoolState() external view returns (PoolState) {
        return state;
    }
}
