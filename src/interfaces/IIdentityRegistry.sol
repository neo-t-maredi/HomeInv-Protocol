// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IIdentityRegistry
 * @author HomeInv Protocol
 * @notice Interface for IdentityRegistry — exposes KYC verification queries
 */
interface IIdentityRegistry {
    function isVerified(address _account) external view returns (bool);
    function isSanctioned(address _account) external view returns (bool);
    function meetsKYCTier(address _account, uint8 _requiredTier) external view returns (bool);
    function verifyIdentity(address _account, uint8 _kycTier, uint256 _expiresAt, bytes32 _ficaDocHash) external;
    function daysUntilExpiry(address _account) external view returns (uint256);
}