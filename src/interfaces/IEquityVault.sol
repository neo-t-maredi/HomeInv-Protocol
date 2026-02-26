// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEquityVault {
    function allocateEquity(address _tenant, uint256 _propertyId, uint256 _amount) external;
    function claimEquityTokens(uint256 _propertyId) external;
    function pendingEquity(address _tenant, uint256 _propertyId) external view returns (uint256);
    function configureProperty(uint256 _propertyId, address _propertyToken, uint256 _conversionThreshold, uint256 _equityRateBps) external;
}
