// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PropertyPool
 * @author HomeInv Protocol
 * @notice Manages the full lifecycle of a single tokenised South African property
 * @dev Implements a four-stage state machine: PENDING → FUNDING → ACTIVE → CLOSED
 *      Handles capital raises, yield distribution and investor redemptions.
 *
 * State machine:
 *  - PENDING  : Property submitted, due diligence underway
 *  - FUNDING  : Capital raise open, investors purchasing PropertyTokens
 *  - ACTIVE   : Funding complete, property operational, yield distributing
 *  - CLOSED   : Lifecycle complete, proceeds distributed, tokens redeemable
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {
    ReentrancyGuard
} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPropertyToken} from "../interfaces/IPropertyToken.sol";
import {IIdentityRegistry} from "../interfaces/IIdentityRegistry.sol";
import {IPropertyPool} from "../interfaces/IPropertyPool.sol";

contract PropertyPool is IPropertyPool, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    PoolState public state;

    IPropertyToken public immutable propertyToken;
    IIdentityRegistry public immutable identityRegistry;

    uint256 public immutable propertyId;
    uint256 public immutable fundingTarget;
    uint256 public immutable tokenPrice;
    uint256 public immutable fundingDeadline;

    uint256 public totalRaised;
    uint256 public totalYieldDistributed;

    address public rentVault;
    address public equityVault;

    mapping(address => uint256) public contributions;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event StateTransitioned(PoolState indexed from, PoolState indexed to);
    event InvestmentReceived(
        address indexed investor,
        uint256 amount,
        uint256 tokensIssued
    );
    event YieldDeposited(address indexed from, uint256 amount);
    event VaultAddressesSet(address rentVault, address equityVault);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error PropertyPool__InvalidState(PoolState required, PoolState current);
    error PropertyPool__FundingDeadlinePassed();
    error PropertyPool__FundingDeadlineNotPassed();
    error PropertyPool__InvestorNotVerified(address investor);
    error PropertyPool__FundingTargetNotMet();
    error PropertyPool__ZeroAmount();
    error PropertyPool__ZeroAddress();
    error PropertyPool__VaultsNotSet();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        uint256 _propertyId,
        uint256 _fundingTarget,
        uint256 _tokenPrice,
        uint256 _fundingDeadline,
        address _propertyToken,
        address _identityRegistry,
        address _initialOwner
    ) Ownable(_initialOwner) {
        if (_propertyToken == address(0)) revert PropertyPool__ZeroAddress();
        if (_identityRegistry == address(0)) revert PropertyPool__ZeroAddress();
        if (_fundingTarget == 0) revert PropertyPool__ZeroAmount();
        if (_tokenPrice == 0) revert PropertyPool__ZeroAmount();

        propertyId = _propertyId;
        fundingTarget = _fundingTarget;
        tokenPrice = _tokenPrice;
        fundingDeadline = _fundingDeadline;
        propertyToken = IPropertyToken(_propertyToken);
        identityRegistry = IIdentityRegistry(_identityRegistry);

        state = PoolState.PENDING;
    }

    /*//////////////////////////////////////////////////////////////
                        STATE TRANSITIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Moves pool from PENDING to FUNDING — opens capital raise
    /// @dev Only owner (REITFactory) can open funding after due diligence
    function openFunding() external onlyOwner {
        if (state != PoolState.PENDING)
            revert PropertyPool__InvalidState(PoolState.PENDING, state);
        if (rentVault == address(0) || equityVault == address(0))
            revert PropertyPool__VaultsNotSet();

        emit StateTransitioned(state, PoolState.FUNDING);
        state = PoolState.FUNDING;
    }

    /// @notice Moves pool from FUNDING to ACTIVE — closes capital raise
    /// @dev Self-triggers when funding target is met, or owner closes manually
    function activatePool() external onlyOwner {
        if (state != PoolState.FUNDING)
            revert PropertyPool__InvalidState(PoolState.FUNDING, state);
        if (totalRaised < fundingTarget)
            revert PropertyPool__FundingTargetNotMet();

        emit StateTransitioned(state, PoolState.ACTIVE);
        state = PoolState.ACTIVE;
    }

    /// @notice Moves pool from ACTIVE to CLOSED — ends lifecycle
    function closePool() external onlyOwner {
        if (state != PoolState.ACTIVE)
            revert PropertyPool__InvalidState(PoolState.ACTIVE, state);

        emit StateTransitioned(state, PoolState.CLOSED);
        state = PoolState.CLOSED;

        // Pause all token transfers on close
        propertyToken.pauseTransfers();
    }

    /// @notice Sets vault addresses — must be called before openFunding
    function setVaults(address _rentVault, address _equityVault) external onlyOwner {
        if (_rentVault == address(0)) revert PropertyPool__ZeroAddress();
        if (_equityVault == address(0)) revert PropertyPool__ZeroAddress();

        rentVault = _rentVault;
        equityVault = _equityVault;

        emit VaultAddressesSet(_rentVault, _equityVault);
    }

    /*//////////////////////////////////////////////////////////////
                        INVESTMENT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Investor purchases PropertyTokens during FUNDING phase
    /// @param _tokenAmount Number of tokens to purchase
    function invest(uint256 _tokenAmount) external nonReentrant {
        if (state != PoolState.FUNDING)
            revert PropertyPool__InvalidState(PoolState.FUNDING, state);
        if (block.timestamp > fundingDeadline)
            revert PropertyPool__FundingDeadlinePassed();
        if (_tokenAmount == 0)
            revert PropertyPool__ZeroAmount();
        if (!identityRegistry.isVerified(msg.sender))
            revert PropertyPool__InvestorNotVerified(msg.sender);

        uint256 investmentAmount = _tokenAmount * tokenPrice;

        // Checks → Effects → Interactions
        totalRaised += investmentAmount;
        contributions[msg.sender] += investmentAmount;

        // Transfer tokens to investor
        propertyToken.transfer(msg.sender, _tokenAmount);

        // Auto-activate if funding target met
        if (totalRaised >= fundingTarget) {
            emit StateTransitioned(state, PoolState.ACTIVE);
            state = PoolState.ACTIVE;
        }

        emit InvestmentReceived(msg.sender, investmentAmount, _tokenAmount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns funding progress as a percentage in basis points
    function fundingProgressBps() external view returns (uint256) {
        if (fundingTarget == 0) return 0;
        return (totalRaised * 10_000) / fundingTarget;
    }

    /// @notice Returns whether funding deadline has passed
    function isFundingExpired() external view returns (bool) {
        return block.timestamp > fundingDeadline;
    }

    /// @notice Returns investor's token balance
    function investorBalance(address _investor) external view returns (uint256) {
        return propertyToken.balanceOf(_investor);
    }

    /// @notice Returns investor's ownership percentage in basis points
    function investorOwnershipBps(address _investor) external view returns (uint256) {
        return propertyToken.ownershipBps(_investor);
    }
}
