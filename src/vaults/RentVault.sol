//SPDX // SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title RentVault
 * @author HomeInv Protocol
 * @notice Receives rent payments and distributes yield to PropertyToken holders
 * @dev Uses reward-per-token-share pattern for gas-efficient yield distribution.
 *      Splits each rent payment between investors, property manager and treasury.
 *
 *  Split mechanics (configurable, bounded):
 *  - Investor yield : proportional to PropertyToken holdings
 *  - Property manager: operational costs
 *  - Protocol treasury: reserve and development
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPropertyToken} from "../interfaces/IPropertyToken.sol";
import {IPropertyPool} from "../interfaces/IPropertyPool.sol";
import {IRentVault} from "../interfaces/IRentVault.sol";

contract RentVault is IRentVault, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct PropertyYield {
        uint256 accumulatedYieldPerToken; // Running total yield per token
        uint256 totalDeposited;           // Total rent ever deposited
        uint256 managerSplit;             // Basis points to property manager
        uint256 treasurySplit;            // Basis points to treasury
        address propertyManager;          // Manager receiving operational cut
        address propertyToken;            // PropertyToken for this property
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Protocol treasury address
    address public treasury;

    /// @notice Max split allowed to treasury or manager (basis points)
    uint256 public constant MAX_SPLIT_BPS = 2000; // 20% max each

    /// @notice propertyId => PropertyYield data
    mapping(uint256 => PropertyYield) public propertyYields;

    /// @notice propertyId => investor => yield snapshot
    mapping(uint256 => mapping(address => uint256)) public investorSnapshots;

    /// @notice propertyId => investor => unclaimed yield
    mapping(uint256 => mapping(address => uint256)) public unclaimedYield;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event RentDeposited(uint256 indexed propertyId, uint256 amount, uint256 managerCut, uint256 treasuryCut);
    event YieldClaimed(uint256 indexed propertyId, address indexed investor, uint256 amount);
    event PropertyRegistered(uint256 indexed propertyId, address propertyToken, address manager);
    event SplitsUpdated(uint256 indexed propertyId, uint256 managerBps, uint256 treasuryBps);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error RentVault__PropertyNotRegistered(uint256 propertyId);
    error RentVault__SplitExceedsMax(uint256 provided, uint256 max);
    error RentVault__ZeroAmount();
    error RentVault__ZeroAddress();
    error RentVault__NothingToClaim();
    error RentVault__TransferFailed();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param _treasury Protocol treasury address
    /// @param _initialOwner Protocol deployer
    constructor(address _treasury, address _initialOwner) Ownable(_initialOwner) {
        if (_treasury == address(0)) revert RentVault__ZeroAddress();
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Registers a property with its token, manager and split ratios
    function registerProperty(
        uint256 _propertyId,
        address _propertyToken,
        address _propertyManager,
        uint256 _managerBps,
        uint256 _treasuryBps
    ) external onlyOwner {
        if (_propertyToken == address(0)) revert RentVault__ZeroAddress();
        if (_propertyManager == address(0)) revert RentVault__ZeroAddress();
        if (_managerBps > MAX_SPLIT_BPS) revert RentVault__SplitExceedsMax(_managerBps, MAX_SPLIT_BPS);
        if (_treasuryBps > MAX_SPLIT_BPS) revert RentVault__SplitExceedsMax(_treasuryBps, MAX_SPLIT_BPS);

        propertyYields[_propertyId] = PropertyYield({
            accumulatedYieldPerToken: 0,
            totalDeposited: 0,
            managerSplit: _managerBps,
            treasurySplit: _treasuryBps,
            propertyManager: _propertyManager,
            propertyToken: _propertyToken
        });

        emit PropertyRegistered(_propertyId, _propertyToken, _propertyManager);
    }

    /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits rent payment and splits between recipients
    function depositRent(uint256 _propertyId) external payable nonReentrant {
        PropertyYield storage py = propertyYields[_propertyId];
        if (py.propertyToken == address(0)) 
            revert RentVault__PropertyNotRegistered(_propertyId);
        if (msg.value == 0) revert RentVault__ZeroAmount();

        uint256 rentAmount = msg.value;

        // Calculate splits
        uint256 managerCut = (rentAmount * py.managerSplit) / 10_000;
        uint256 treasuryCut = (rentAmount * py.treasurySplit) / 10_000;
        uint256 investorYield = rentAmount - managerCut - treasuryCut;

        // Update accumulated yield per token
        uint256 totalSupply = IPropertyToken(py.propertyToken).totalSupply();
        if (totalSupply > 0) {
            py.accumulatedYieldPerToken += (investorYield * 1e18) / totalSupply;
        }

        py.totalDeposited += rentAmount;

        // Push splits — interactions last
        (bool managerSent,) = py.propertyManager.call{value: managerCut}("");
        if (!managerSent) revert RentVault__TransferFailed();

        (bool treasurySent,) = treasury.call{value: treasuryCut}("");
        if (!treasurySent) revert RentVault__TransferFailed();

        emit RentDeposited(_propertyId, rentAmount, managerCut, treasuryCut);
    }

    /// @notice Investor claims their accumulated yield
    function claimYield(uint256 _propertyId) external nonReentrant {
        _updateYield(_propertyId, msg.sender);

        uint256 owed = unclaimedYield[_propertyId][msg.sender];
        if (owed == 0) revert RentVault__NothingToClaim();

        // Effects before interactions
        unclaimedYield[_propertyId][msg.sender] = 0;

        (bool sent,) = msg.sender.call{value: owed}("");
        if (!sent) revert RentVault__TransferFailed();

        emit YieldClaimed(_propertyId, msg.sender, owed);
    }

    /// @notice Internal — updates unclaimed yield for an investor
    function _updateYield(uint256 _propertyId, address _investor) internal {
        PropertyYield storage py = propertyYields[_propertyId];
        uint256 balance = IPropertyToken(py.propertyToken).balanceOf(_investor);

        uint256 earned = (balance * 
            (py.accumulatedYieldPerToken - investorSnapshots[_propertyId][_investor])
        ) / 1e18;

        unclaimedYield[_propertyId][_investor] += earned;
        investorSnapshots[_propertyId][_investor] = py.accumulatedYieldPerToken;
    }
    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns pending yield for an investor
    function pendingYield(uint256 _propertyId, address _investor) 
        external 
        view 
        returns (uint256) 
    {
        PropertyYield storage py = propertyYields[_propertyId];
        uint256 balance = IPropertyToken(py.propertyToken).balanceOf(_investor);

        uint256 earned = (balance *
            (py.accumulatedYieldPerToken - investorSnapshots[_propertyId][_investor])
        ) / 1e18;

        return unclaimedYield[_propertyId][_investor] + earned;
    }

    /// @notice Returns total rent deposited for a property
    function totalRentDeposited(uint256 _propertyId) 
        external 
        view 
        returns (uint256) 
    {
        return propertyYields[_propertyId].totalDeposited;
    }

    /// @notice Returns current split ratios for a property
    function getSplits(uint256 _propertyId) 
        external 
        view 
        returns (uint256 managerBps, uint256 treasuryBps) 
    {
        return (
            propertyYields[_propertyId].managerSplit,
            propertyYields[_propertyId].treasurySplit
        );
    }
}