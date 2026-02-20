// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title REITFactory
 * @notice Entry point for HomeInv Protocol. Micro-developers and sponsors
 * submit properties here. Factory deploys a dedicated PropertyPool per
 * development. All submissions are gated by FICA/KYC verification.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "./JurisdictionRegistry.sol";
import "./IdentityRegistry.sol";

contract REITFactory is Ownable {
    JurisdictionRegistry public jurisdictionRegistry;
    IdentityRegistry public identityRegistry;

    uint256 public propertyCount;

    struct PropertySubmission {
        address developer;
        string location;
        uint256 fundingTarget;
        uint256 projectedYield;
        bytes2 jurisdiction;
        address poolAddress;
        bool isActive;
    }

    mapping(uint256 => PropertySubmission) public properties;

    event PropertySubmitted(
        uint256 indexed propertyId,
        address indexed developer,
        string location
    );
    event PoolDeployed(uint256 indexed propertyId, address indexed poolAddress);

    constructor(
        address _jurisdictionRegistry,
        address _identityRegistry
    ) Ownable(msg.sender) {
        jurisdictionRegistry = JurisdictionRegistry(_jurisdictionRegistry);
        identityRegistry = IdentityRegistry(_identityRegistry);
    }

    // Developer submits a property for tokenization
    // Must be FICA verified and jurisdiction must be active
    function submitProperty(
        string memory _location,
        uint256 _fundingTarget,
        uint256 _projectedYield,
        bytes2 _jurisdiction
    ) external returns (uint256) {
        require(identityRegistry.isVerified(msg.sender), "Not FICA verified");
        require(
            jurisdictionRegistry.isJurisdictionActive(_jurisdiction),
            "Jurisdiction not active"
        );
        require(_fundingTarget > 0, "Funding target must be greater than 0");
        require(bytes(_location).length > 0, "Location cannot be empty");

        uint256 propertyId = propertyCount;

        properties[propertyId] = PropertySubmission({
            developer: msg.sender,
            location: _location,
            fundingTarget: _fundingTarget,
            projectedYield: _projectedYield,
            jurisdiction: _jurisdiction,
            poolAddress: address(0),
            isActive: true
        });

        propertyCount++;

        emit PropertySubmitted(propertyId, msg.sender, _location);

        return propertyId;
    }

    // Returns full property submission details by ID
    function getProperty(
        uint256 _propertyId
    ) external view returns (PropertySubmission memory) {
        require(_propertyId < propertyCount, "Property does not exist");
        return properties[_propertyId];
    }

    // Emergency deactivation — removes property from active listings
    // Called by owner if submission is fraudulent or non-compliant
    function deactivateProperty(uint256 _propertyId) external onlyOwner {
        require(_propertyId < propertyCount, "Property does not exist");
        require(properties[_propertyId].isActive, "Property already inactive");

        properties[_propertyId].isActive = false;
    }

    // Links deployed PropertyPool address back to the submission
    // Called by owner after pool deployment
    function setPoolAddress(
        uint256 _propertyId,
        address _poolAddress
    ) external onlyOwner {
        require(_propertyId < propertyCount, "Property does not exist");
        require(
            properties[_propertyId].poolAddress == address(0),
            "Pool already deployed"
        );
        require(_poolAddress != address(0), "Invalid pool address");

        properties[_propertyId].poolAddress = _poolAddress;

        emit PoolDeployed(_propertyId, _poolAddress);
    }

    // Returns total number of property submissions — used by frontend and subgraph
    function getPropertyCount() external view returns (uint256) {
        return propertyCount;
    }
}
