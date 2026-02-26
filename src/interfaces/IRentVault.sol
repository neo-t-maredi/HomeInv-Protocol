// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IRentVault {
    function depositRent(uint256 _propertyId) external payable;
    function claimYield(uint256 _propertyId) external;
    function pendingYield(uint256 _propertyId, address _investor) external view returns (uint256);
    function totalRentDeposited(uint256 _propertyId) external view returns (uint256);
    function registerProperty(uint256 _propertyId, address _propertyToken, address _propertyManager, uint256 _managerBps, uint256 _treasuryBps) external;
}
