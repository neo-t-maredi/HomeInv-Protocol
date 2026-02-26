// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IREITFactory
 * @author HomeInv Protocol
 * @notice Interface for REITFactory — property submission and deployment
 */
interface IREITFactory {
    function submitProperty(
        string memory _name,
        string memory _symbol,
        uint256 _propertyValue,
        uint256 _tokenPrice,
        uint256 _fundingDeadline,
        uint8 _requiredKYCTier,
        bytes32 _propertyDocHash,
        address _propertyManager
    ) external returns (uint256 propertyId, address propertyToken, address propertyPool);

    function getProperty(uint256 _propertyId) external view returns (address propertyToken, address propertyPool);
    function propertyCount() external view returns (uint256);
}