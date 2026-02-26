// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PropertyToken
 * @author HomeInv Protocol
 * @notice Fractional ownership token for a single tokenised South African property
 * @dev ERC-20 with compliance-gated transfers enforced via IdentityRegistry.
 *      Every transfer checks both sender and receiver are KYC verified and not sanctioned.
 *      One PropertyToken contract is deployed per property by the REITFactory.
 *
 * Compliance rules enforced on every transfer:
 *  - Sender must be verified in IdentityRegistry
 *  - Receiver must be verified in IdentityRegistry
 *  - Neither party may be sanctioned
 *  - Neither party's KYC may be expired
 *
 * Token economics:
 *  - Total supply = property value in ZAR (18 decimals) / token price
 *  - Tokens represent proportional ownership of rental yield and capital gains
 *  - Minted once at deployment by REITFactory, no further minting
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IIdentityRegistry} from "../interfaces/IIdentityRegistry.sol";

contract PropertyToken is ERC20, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Identity registry for compliance gating
    IIdentityRegistry public immutable identityRegistry;

    /// @notice Minimum KYC tier required to hold this token
    uint8 public immutable requiredKYCTier;

    /// @notice IPFS hash of property legal documents
    bytes32 public propertyDocHash;

    /// @notice Unique property identifier from REITFactory
    uint256 public immutable propertyId;

    /// @notice ZAR value of the property (18 decimals)
    uint256 public immutable propertyValue;

    /// @notice Whether transfers are paused — emergency use only
    bool public transfersPaused;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransfersPaused(address indexed by);
    event TransfersUnpaused(address indexed by);
    event PropertyDocHashUpdated(bytes32 oldHash, bytes32 newHash);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error PropertyToken__TransfersPaused();
    error PropertyToken__SenderNotVerified(address sender);
    error PropertyToken__ReceiverNotVerified(address receiver);
    error PropertyToken__SenderSanctioned(address sender);
    error PropertyToken__ReceiverSanctioned(address receiver);
    error PropertyToken__InsufficientKYCTier(address account, uint8 required, uint8 actual);
    error PropertyToken__ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys a PropertyToken for a single verified property
    /// @param _name Token name e.g. "HomeInv 14 Buitenkant Street"
    /// @param _symbol Token symbol e.g. "HINV-BKT-001"
    /// @param _totalSupply Total tokens representing 100% ownership
    /// @param _propertyId Unique ID assigned by REITFactory
    /// @param _propertyValue ZAR value of property (18 decimals)
    /// @param _requiredKYCTier Minimum KYC tier to hold this token
    /// @param _propertyDocHash IPFS hash of legal property documents
    /// @param _identityRegistry Deployed IdentityRegistry address
    /// @param _initialOwner REITFactory address — receives full supply
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _propertyId,
        uint256 _propertyValue,
        uint8 _requiredKYCTier,
        bytes32 _propertyDocHash,
        address _identityRegistry,
        address _initialOwner
    )
        ERC20(_name, _symbol)
        Ownable(_initialOwner)
    {
        if (_identityRegistry == address(0)) revert PropertyToken__ZeroAddress();
        if (_initialOwner == address(0)) revert PropertyToken__ZeroAddress();

        identityRegistry = IIdentityRegistry(_identityRegistry);
        requiredKYCTier = _requiredKYCTier;
        propertyDocHash = _propertyDocHash;
        propertyId = _propertyId;
        propertyValue = _propertyValue;

        _mint(_initialOwner, _totalSupply);
    }

    /*//////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Hooks into every transfer, mint and burn
    /// Enforces KYC compliance on both sender and receiver
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20) {
        // Skip compliance checks on mint (from == address(0))
        // and burn (to == address(0))
        if (from != address(0) && to != address(0)) {
            if (transfersPaused) revert PropertyToken__TransfersPaused();

            // Sender checks
            if (identityRegistry.isSanctioned(from))
                revert PropertyToken__SenderSanctioned(from);
            if (!identityRegistry.meetsKYCTier(from, requiredKYCTier))
                revert PropertyToken__SenderNotVerified(from);

            // Receiver checks
            if (identityRegistry.isSanctioned(to))
                revert PropertyToken__ReceiverSanctioned(to);
            if (!identityRegistry.meetsKYCTier(to, requiredKYCTier))
                revert PropertyToken__ReceiverNotVerified(to);
        }

        super._update(from, to, value);
    }

    /*//////////////////////////////////////////////////////////////
                          ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Pauses all token transfers — emergency use only
    function pauseTransfers() external onlyOwner {
        transfersPaused = true;
        emit TransfersPaused(msg.sender);
    }

    /// @notice Unpauses token transfers
    function unpauseTransfers() external onlyOwner {
        transfersPaused = false;
        emit TransfersUnpaused(msg.sender);
    }

    /// @notice Updates the property legal document hash
    /// @param _newHash Updated IPFS hash of legal documents
    function updatePropertyDocHash(bytes32 _newHash) external onlyOwner {
        bytes32 oldHash = propertyDocHash;
        propertyDocHash = _newHash;
        emit PropertyDocHashUpdated(oldHash, _newHash);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether an address can hold this token
    function canHold(address _account) external view returns (bool) {
        return identityRegistry.meetsKYCTier(_account, requiredKYCTier);
    }

    /// @notice Returns ownership percentage of an address (in basis points)
    /// @param _account Address to check
    /// @return bps Ownership in basis points (10000 = 100%)
    function ownershipBps(address _account) external view returns (uint256 bps) {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return (balanceOf(_account) * 10_000) / supply;
    }
}