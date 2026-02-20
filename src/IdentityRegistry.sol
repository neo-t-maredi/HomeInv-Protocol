// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IdentityRegistry
 * @notice Manages KYC/FICA identity verification for HomeInv Protocol.
 * Tracks verified wallets, their identity type (resident, investor, developer),
 * and their jurisdiction. Required before any property token transfer.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./JurisdictionRegistry.sol";

contract IdentityRegistry is Ownable {
    JurisdictionRegistry public jurisdictionRegistry;

    enum IdentityType {
        NONE,
        LOCAL_RESIDENT,
        IMPACT_INVESTOR,
        MICRO_DEVELOPER
    }

    struct Identity {
        bool isVerified;
        IdentityType identityType;
        bytes2 jurisdiction;
        uint256 verifiedAt;
        uint256 expiresAt;
    }

    mapping(address => Identity) public identities;

    event IdentityVerified(
        address indexed wallet,
        IdentityType identityType,
        bytes2 jurisdiction
    );
    event IdentityRevoked(address indexed wallet);
    event IdentityExpired(address indexed wallet);

    constructor(address _jurisdictionRegistry) Ownable(msg.sender) {
        jurisdictionRegistry = JurisdictionRegistry(_jurisdictionRegistry);
    }

    function verifyIdentity(
        address _wallet,
        IdentityType _identityType,
        bytes2 _jurisdiction,
        uint256 _expiresAt
    ) external onlyOwner {
        require(_wallet != address(0), "Invalid wallet address");
        require(
            jurisdictionRegistry.isJurisdictionActive(_jurisdiction),
            "Jurisdiction not active"
        );
        require(_expiresAt > block.timestamp, "Expiry must be in the future");

        identities[_wallet] = Identity({
            isVerified: true,
            identityType: _identityType,
            jurisdiction: _jurisdiction,
            verifiedAt: block.timestamp,
            expiresAt: _expiresAt
        });

        emit IdentityVerified(_wallet, _identityType, _jurisdiction);
    }

    function revokeIdentity(address _wallet) external onlyOwner {
        require(identities[_wallet].isVerified, "Identity not found");

        identities[_wallet].isVerified = false;

        emit IdentityRevoked(_wallet);
    }
    // Core check — returns true only if wallet is verified AND not expired
    // Called by PropertyPool, RentVault and TokenFactory before any action
    function isVerified(address _wallet) external view returns (bool) {
        Identity memory identity = identities[_wallet];
        return identity.isVerified && block.timestamp < identity.expiresAt;
    }

    function getIdentity(address _wallet) external view returns (Identity memory) {
    require(identities[_wallet].isVerified, "Identity not verified");
    return identities[_wallet];
}
}
