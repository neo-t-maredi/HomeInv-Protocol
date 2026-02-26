// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title EquityVault
 * @author HomeInv Protocol
 * @notice Converts tenant rent payments into fractional property ownership
 * @dev Accumulates equity credits per tenant per property.
 *      When credits exceed conversionThreshold, PropertyTokens are transferred
 *      to the tenant — converting them from renter to fractional owner.
 *
 * This mechanic is the core social impact proposition of HomeInv:
 *  - Tenants in previously excluded communities gain ownership over time
 *  - No lump sum required — ownership accrues through regular rent payments
 *  - Fully transparent and auditable on-chain
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IPropertyToken} from "../interfaces/IPropertyToken.sol";
import {IEquityVault} from "../interfaces/IEquityVault.sol";

contract EquityVault is IEquityVault, Ownable, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct TenantEquity {
        uint256 credits;          // Accumulated equity credits (ZAR, 18 decimals)
        uint256 tokensReceived;   // Total PropertyTokens earned so far
        uint256 lastUpdated;      // Timestamp of last accumulation
    }

    struct PropertyConfig {
        address propertyToken;        // PropertyToken address
        uint256 conversionThreshold;  // Credits needed to convert to tokens
        uint256 equityRateBps;        // % of rent allocated as equity (basis points)
        bool active;                  // Whether this property accepts equity allocations
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice propertyId => PropertyConfig
    mapping(uint256 => PropertyConfig) public propertyConfigs;

    /// @notice propertyId => tenant => TenantEquity
    mapping(uint256 => mapping(address => TenantEquity)) public tenantEquity;

    /// @notice Authorised callers — RentVault allocates equity
    mapping(address => bool) public authorisedAllocators;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event EquityAllocated(address indexed tenant, uint256 indexed propertyId, uint256 credits);
    event EquityConverted(address indexed tenant, uint256 indexed propertyId, uint256 tokens);
    event PropertyConfigured(uint256 indexed propertyId, uint256 threshold, uint256 rateBps);
    event AllocatorUpdated(address indexed allocator, bool authorised);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error EquityVault__NotAuthorised();
    error EquityVault__PropertyNotActive(uint256 propertyId);
    error EquityVault__ZeroAmount();
    error EquityVault__ZeroAddress();
    error EquityVault__NothingToClaim();
    error EquityVault__ThresholdNotMet(uint256 credits, uint256 threshold);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _initialOwner) Ownable(_initialOwner) {
        if (_initialOwner == address(0)) revert EquityVault__ZeroAddress();
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Configures a property for equity accumulation
    function configureProperty(
        uint256 _propertyId,
        address _propertyToken,
        uint256 _conversionThreshold,
        uint256 _equityRateBps
    ) external onlyOwner {
        if (_propertyToken == address(0)) revert EquityVault__ZeroAddress();
        if (_conversionThreshold == 0) revert EquityVault__ZeroAmount();
        if (_equityRateBps == 0) revert EquityVault__ZeroAmount();

        propertyConfigs[_propertyId] = PropertyConfig({
            propertyToken: _propertyToken,
            conversionThreshold: _conversionThreshold,
            equityRateBps: _equityRateBps,
            active: true
        });

        emit PropertyConfigured(_propertyId, _conversionThreshold, _equityRateBps);
    }

    /// @notice Grants or revokes allocator permission
    function setAllocator(address _allocator, bool _authorised) external onlyOwner {
        if (_allocator == address(0)) revert EquityVault__ZeroAddress();
        authorisedAllocators[_allocator] = _authorised;
        emit AllocatorUpdated(_allocator, _authorised);
    }

    /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Allocates equity credits to a tenant — called by RentVault
    function allocateEquity(
        address _tenant,
        uint256 _propertyId,
        uint256 _amount
    ) external {
        if (!authorisedAllocators[msg.sender]) revert EquityVault__NotAuthorised();
        if (_amount == 0) revert EquityVault__ZeroAmount();

        PropertyConfig storage config = propertyConfigs[_propertyId];
        if (!config.active) revert EquityVault__PropertyNotActive(_propertyId);

        TenantEquity storage equity = tenantEquity[_propertyId][_tenant];

        uint256 equityCredits = (_amount * config.equityRateBps) / 10_000;
        equity.credits += equityCredits;
        equity.lastUpdated = block.timestamp;

        emit EquityAllocated(_tenant, _propertyId, equityCredits);
    }

    /// @notice Tenant claims accumulated equity as PropertyTokens
    function claimEquityTokens(uint256 _propertyId) external nonReentrant {
        PropertyConfig storage config = propertyConfigs[_propertyId];
        if (!config.active) revert EquityVault__PropertyNotActive(_propertyId);

        TenantEquity storage equity = tenantEquity[_propertyId][msg.sender];
        if (equity.credits == 0) revert EquityVault__NothingToClaim();
        if (equity.credits < config.conversionThreshold)
            revert EquityVault__ThresholdNotMet(equity.credits, config.conversionThreshold);

        // Calculate tokens to issue
        uint256 tokenSupply = IPropertyToken(config.propertyToken).totalSupply();
        uint256 tokensToIssue = equity.credits;

        // Effects before interactions
        equity.credits = 0;
        equity.tokensReceived += tokensToIssue;

        IPropertyToken(config.propertyToken).transfer(msg.sender, tokensToIssue);

        emit EquityConverted(msg.sender, _propertyId, tokensToIssue);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns pending equity credits for a tenant
    function pendingEquity(
        address _tenant,
        uint256 _propertyId
    ) external view returns (uint256) {
        return tenantEquity[_propertyId][_tenant].credits;
    }

    /// @notice Returns full equity record for a tenant
    function getTenantEquity(
        address _tenant,
        uint256 _propertyId
    ) external view returns (TenantEquity memory) {
        return tenantEquity[_propertyId][_tenant];
    }

}