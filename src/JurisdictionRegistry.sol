// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title JurisdictionRegistry
 * @notice Stores and manages regulatory rules per jurisdiction for HomeInv Protocol.
 * South Africa (ZA) is initialized by default. New jurisdictions can be added
 * to support protocol scaling beyond RSA.
 */

import "@openzeppelin/contracts/access/Ownable.sol";

contract JurisdictionRegistry is Ownable {
    // Jurisdiction codes — ISO 3166-1 alpha-2
    // ZA = South Africa

    struct JurisdictionRules {
        bool isActive;
        uint256 transferDutyThreshold; // in ZAR equivalent (18 decimals)
        bool ficaRequired;
        bool exchangeControlRequired;
        uint256 maxForeignOwnershipPercent; // basis points, 10000 = 100%
        string regulatoryFramework; // e.g. "FSCA_2022"
    }

    mapping(bytes2 => JurisdictionRules) public jurisdictions;

    event JurisdictionAdded(bytes2 indexed code, string regulatoryFramework);
    event JurisdictionUpdated(bytes2 indexed code);
    event JurisdictionDeactivated(bytes2 indexed code);

    constructor() Ownable(msg.sender) {
        // Initialize RSA on deploy
        jurisdictions["ZA"] = JurisdictionRules({
            isActive: true,
            transferDutyThreshold: 1_100_000 * 1e18, // R1.1M threshold
            ficaRequired: true,
            exchangeControlRequired: true,
            maxForeignOwnershipPercent: 7500, // 75% max foreign ownership
            regulatoryFramework: "FSCA_2022"
        });

        emit JurisdictionAdded("ZA", "FSCA_2022");
    }

    function addJurisdiction(
        bytes2 _code,
        uint256 _transferDutyThreshold,
        bool _ficaRequired,
        bool _exchangeControlRequired,
        uint256 _maxForeignOwnershipPercent,
        string memory _regulatoryFramework
    ) external onlyOwner {
        require(!jurisdictions[_code].isActive, "Jurisdiction already exists");

        jurisdictions[_code] = JurisdictionRules({
            isActive: true,
            transferDutyThreshold: _transferDutyThreshold,
            ficaRequired: _ficaRequired,
            exchangeControlRequired: _exchangeControlRequired,
            maxForeignOwnershipPercent: _maxForeignOwnershipPercent,
            regulatoryFramework: _regulatoryFramework
        });

        emit JurisdictionAdded(_code, _regulatoryFramework);
    }

    function updateJurisdiction(
        bytes2 _code,
        uint256 _transferDutyThreshold,
        bool _ficaRequired,
        bool _exchangeControlRequired,
        uint256 _maxForeignOwnershipPercent,
        string memory _regulatoryFramework
    ) external onlyOwner {
        require(jurisdictions[_code].isActive, "Jurisdiction does not exist");

        jurisdictions[_code].transferDutyThreshold = _transferDutyThreshold;
        jurisdictions[_code].ficaRequired = _ficaRequired;
        jurisdictions[_code].exchangeControlRequired = _exchangeControlRequired;
        jurisdictions[_code]
            .maxForeignOwnershipPercent = _maxForeignOwnershipPercent;
        jurisdictions[_code].regulatoryFramework = _regulatoryFramework;

        emit JurisdictionUpdated(_code);
    }

    function deactivateJurisdiction(bytes2 _code) external onlyOwner {
        require(jurisdictions[_code].isActive, "Jurisdiction already inactive");

        jurisdictions[_code].isActive = false;

        emit JurisdictionDeactivated(_code);
    }
    function isJurisdictionActive(bytes2 _code) external view returns (bool) {
        return jurisdictions[_code].isActive;
    }
}
