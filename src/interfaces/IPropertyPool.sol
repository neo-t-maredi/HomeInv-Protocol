// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPropertyPool {
    enum PoolState {
        PENDING,
        FUNDING,
        ACTIVE,
        CLOSED
    }

    function state() external view returns (PoolState);
    function propertyId() external view returns (uint256);
    function fundingTarget() external view returns (uint256);
    function totalRaised() external view returns (uint256);
    function contributions(address _investor) external view returns (uint256);
}