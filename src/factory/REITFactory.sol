// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title REITFactory
 * @author HomeInv Protocol
 * @notice Entry point for property tokenisation — deploys and wires all protocol contracts
 * @dev Accepts verified property submissions and deploys a PropertyToken + PropertyPool pair.
 *      Registers each deployment with RentVault and EquityVault automatically.
 *      Only verified developers (KYC Tier 3) can submit properties.
 *
 * Deployment flow per property:
 *  1. Verify developer identity via IdentityRegistry
 *  2. Deploy PropertyToken (ERC-20 with compliance gating)
 *  3. Deploy PropertyPool (lifecycle state machine)
 *  4. Register with RentVault (yield distribution)
 *  5. Register with EquityVault (tenant equity accumulation)
 *  6. Emit PropertyDeployed event with all addresses
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IREITFactory} from "../interfaces/IREITFactory.sol";
import {IIdentityRegistry} from "../interfaces/IIdentityRegistry.sol";
import {IJurisdictionRegistry} from "../interfaces/IJurisdictionRegistry.sol";
import {IRentVault} from "../interfaces/IRentVault.sol";
import {IEquityVault} from "../interfaces/IEquityVault.sol";
import {PropertyToken} from "../tokens/PropertyToken.sol";
import {PropertyPool} from "../core/PropertyPool.sol";

contract REITFactory is IREITFactory, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Core protocol contract references
    IIdentityRegistry public immutable identityRegistry;
    IJurisdictionRegistry public immutable jurisdictionRegistry;
    IRentVault public immutable rentVault;
    IEquityVault public immutable equityVault;

    /// @notice Protocol treasury
    address public immutable treasury;

    /// @notice Total properties deployed
    uint256 public propertyCount;

    /// @notice propertyId => PropertyToken address
    mapping(uint256 => address) public propertyTokens;

    /// @notice propertyId => PropertyPool address
    mapping(uint256 => address) public propertyPools;

    /// @notice Developer address => properties they submitted
    mapping(address => uint256[]) public developerProperties;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event PropertyDeployed(
        uint256 indexed propertyId,
        address indexed developer,
        address propertyToken,
        address propertyPool
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error REITFactory__DeveloperNotVerified(address developer);
    error REITFactory__InsufficientKYCTier(address developer);
    error REITFactory__ZeroAddress();
    error REITFactory__InvalidParams();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _identityRegistry,
        address _jurisdictionRegistry,
        address _rentVault,
        address _equityVault,
        address _treasury,
        address _initialOwner
    ) Ownable(_initialOwner) {
        if (_identityRegistry == address(0)) revert REITFactory__ZeroAddress();
        if (_jurisdictionRegistry == address(0)) revert REITFactory__ZeroAddress();
        if (_rentVault == address(0)) revert REITFactory__ZeroAddress();
        if (_equityVault == address(0)) revert REITFactory__ZeroAddress();
        if (_treasury == address(0)) revert REITFactory__ZeroAddress();

        identityRegistry = IIdentityRegistry(_identityRegistry);
        jurisdictionRegistry = IJurisdictionRegistry(_jurisdictionRegistry);
        rentVault = IRentVault(_rentVault);
        equityVault = IEquityVault(_equityVault);
        treasury = _treasury;
    }

    /*//////////////////////////////////////////////////////////////
                          CORE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a full property investment instance
    function submitProperty(
        string memory _name,
        string memory _symbol,
        uint256 _propertyValue,
        uint256 _tokenPrice,
        uint256 _fundingDeadline,
        uint8 _requiredKYCTier,
        bytes32 _propertyDocHash,
        address _propertyManager
    ) external returns (uint256 propertyId, address propertyToken, address propertyPool) {
        // Verify developer is KYC Tier 3
        if (!identityRegistry.isVerified(msg.sender))
            revert REITFactory__DeveloperNotVerified(msg.sender);
        if (!identityRegistry.meetsKYCTier(msg.sender, 3))
            revert REITFactory__InsufficientKYCTier(msg.sender);
        if (_propertyValue == 0 || _tokenPrice == 0)
            revert REITFactory__InvalidParams();
        if (_propertyManager == address(0))
            revert REITFactory__ZeroAddress();

        propertyId = propertyCount++;

        // Calculate total token supply
        uint256 totalSupply = _propertyValue / _tokenPrice;

        // Deploy PropertyToken
        PropertyToken token = new PropertyToken(
            _name,
            _symbol,
            totalSupply,
            propertyId,
            _propertyValue,
            _requiredKYCTier,
            _propertyDocHash,
            address(identityRegistry),
            address(this)
        );

        // Deploy PropertyPool
        PropertyPool pool = new PropertyPool(
            propertyId,
            _propertyValue,
            _tokenPrice,
            _fundingDeadline,
            address(token),
            address(identityRegistry),
            address(this)
        );

        // Verify pool in IdentityRegistry before token transfer
        identityRegistry.verifyIdentity(address(pool), 1, block.timestamp + 365 days, bytes32(0));
    
        // Transfer token supply to pool
        token.transfer(address(pool), totalSupply);

        // Register with RentVault
        rentVault.registerProperty(
            propertyId,
            address(token),
            _propertyManager,
            500,  // 5% manager split
            300   // 3% treasury split
        );

        // Register with EquityVault
        equityVault.configureProperty(
            propertyId,
            address(token),
            1000e18,  // conversion threshold — 1000 ZAR in credits
            500       // 5% equity rate
        );

        // Store addresses
        propertyTokens[propertyId] = address(token);
        propertyPools[propertyId] = address(pool);
        developerProperties[msg.sender].push(propertyId);

        propertyToken = address(token);
        propertyPool = address(pool);

        emit PropertyDeployed(propertyId, msg.sender, propertyToken, propertyPool);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns deployed contract addresses for a property
    function getProperty(uint256 _propertyId)
        external
        view
        returns (address propertyToken, address propertyPool)
    {
        return (propertyTokens[_propertyId], propertyPools[_propertyId]);
    }

    /// @notice Returns all properties submitted by a developer
    function getDeveloperProperties(address _developer)
        external
        view
        returns (uint256[] memory)
    {
        return developerProperties[_developer];
    }

}