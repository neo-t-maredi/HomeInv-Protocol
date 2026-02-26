// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IdentityRegistry
 * @author HomeInv Protocol
 * @notice KYC/FICA verification registry — gates all protocol interactions
 * @dev Every address interacting with HomeInv must be verified here first.
 *      Verification tiers are determined by JurisdictionRegistry FICA rules.
 *
 * Verification tiers:
 *  - Tier 0: Unverified — no protocol access
 *  - Tier 1: Basic KYC — ID document only, small transactions
 *  - Tier 2: Standard FICA — ID + proof of address, mid-range transactions
 *  - Tier 3: Enhanced Due Diligence — full FICA, beneficial ownership, large transactions
 *
 * Roles:
 *  - VERIFIER_ROLE: Authorised KYC agents who can verify/revoke identities
 *  - DEFAULT_ADMIN_ROLE: Protocol owner — manages verifiers
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";
import {IJurisdictionRegistry} from "../interfaces/IJurisdictionRegistry.sol";

contract IdentityRegistry is AccessControl {
    /*//////////////////////////////////////////////////////////////
                                ROLES
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Identity {
        bool isVerified;
        bool isSanctioned;
        uint8 kycTier;
        uint256 verifiedAt;
        uint256 expiresAt;
        bytes32 ficaDocHash;
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    IJurisdictionRegistry public immutable jurisdictionRegistry;
    mapping(address => Identity) public identities;
    uint256 public verifiedCount;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event IdentityVerified(address indexed account, uint8 kycTier, uint256 expiresAt);
    event IdentityRevoked(address indexed account, address indexed revokedBy);
    event IdentitySanctioned(address indexed account, address indexed sanctionedBy);
    event KYCTierUpgraded(address indexed account, uint8 oldTier, uint8 newTier);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error IdentityRegistry__AlreadyVerified(address account);
    error IdentityRegistry__NotVerified(address account);
    error IdentityRegistry__Sanctioned(address account);
    error IdentityRegistry__Expired(address account);
    error IdentityRegistry__InvalidTier(uint8 tier);
    error IdentityRegistry__InvalidExpiry(uint256 expiry);
    error IdentityRegistry__ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _admin, address _jurisdictionRegistry) {
        if (_admin == address(0)) revert IdentityRegistry__ZeroAddress();
        if (_jurisdictionRegistry == address(0)) revert IdentityRegistry__ZeroAddress();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(VERIFIER_ROLE, _admin);

        jurisdictionRegistry = IJurisdictionRegistry(_jurisdictionRegistry);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function verifyIdentity(
        address _account,
        uint8 _kycTier,
        uint256 _expiresAt,
        bytes32 _ficaDocHash
    ) external onlyRole(VERIFIER_ROLE) {
        if (_account == address(0)) revert IdentityRegistry__ZeroAddress();
        if (_kycTier == 0 || _kycTier > 3) revert IdentityRegistry__InvalidTier(_kycTier);
        if (_expiresAt <= block.timestamp) revert IdentityRegistry__InvalidExpiry(_expiresAt);
        if (identities[_account].isSanctioned) revert IdentityRegistry__Sanctioned(_account);

        identities[_account] = Identity({
            isVerified: true,
            isSanctioned: false,
            kycTier: _kycTier,
            verifiedAt: block.timestamp,
            expiresAt: _expiresAt,
            ficaDocHash: _ficaDocHash
        });

        verifiedCount++;
        emit IdentityVerified(_account, _kycTier, _expiresAt);
    }

    function revokeIdentity(address _account) external onlyRole(VERIFIER_ROLE) {
        if (!identities[_account].isVerified) revert IdentityRegistry__NotVerified(_account);
        identities[_account].isVerified = false;
        verifiedCount--;
        emit IdentityRevoked(_account, msg.sender);
    }

    function sanctionAddress(address _account) external onlyRole(VERIFIER_ROLE) {
        if (_account == address(0)) revert IdentityRegistry__ZeroAddress();
        identities[_account].isSanctioned = true;
        if (identities[_account].isVerified) {
            identities[_account].isVerified = false;
            verifiedCount--;
        }
        emit IdentitySanctioned(_account, msg.sender);
    }

    function upgradeKYCTier(address _account, uint8 _newTier) external onlyRole(VERIFIER_ROLE) {
        if (!identities[_account].isVerified) revert IdentityRegistry__NotVerified(_account);
        if (_newTier <= identities[_account].kycTier) revert IdentityRegistry__InvalidTier(_newTier);
        if (_newTier > 3) revert IdentityRegistry__InvalidTier(_newTier);

        uint8 oldTier = identities[_account].kycTier;
        identities[_account].kycTier = _newTier;
        emit KYCTierUpgraded(_account, oldTier, _newTier);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isVerified(address _account) external view returns (bool) {
        Identity memory id = identities[_account];
        return (id.isVerified && !id.isSanctioned && id.expiresAt > block.timestamp);
    }

    function getIdentity(address _account) external view returns (Identity memory) {
        return identities[_account];
    }

    function meetsKYCTier(address _account, uint8 _requiredTier) external view returns (bool) {
        Identity memory id = identities[_account];
        return (
            id.isVerified &&
            !id.isSanctioned &&
            id.expiresAt > block.timestamp &&
            id.kycTier >= _requiredTier
        );
    }

    function isSanctioned(address _account) external view returns (bool) {
        return identities[_account].isSanctioned;
    }

    function daysUntilExpiry(address _account) external view returns (uint256) {
        if (identities[_account].expiresAt <= block.timestamp) return 0;
        return (identities[_account].expiresAt - block.timestamp) / 1 days;
    }
}
