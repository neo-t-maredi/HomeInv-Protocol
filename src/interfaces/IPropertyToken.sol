// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPropertyToken {
    function propertyId() external view returns (uint256);
    function propertyValue() external view returns (uint256);
    function requiredKYCTier() external view returns (uint8);
    function ownershipBps(address _account) external view returns (uint256);
    function canHold(address _account) external view returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function pauseTransfers() external;
    function unpauseTransfers() external;
}
