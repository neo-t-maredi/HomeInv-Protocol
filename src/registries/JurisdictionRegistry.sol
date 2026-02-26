// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title JurisdictionRegistry
 * @author HomeInv Protocol
 * @notice Stores South African regulatory rules governing the protocol
 * @dev Encodes FICA thresholds, SARB limits and transfer duty bands on-chain.
 *      All compliance checks in IdentityRegistry and RentVault reference this contract.
 *
 * Regulatory framework encoded:
 *  - FICA (Financial Intelligence Centre Act) — KYC tier thresholds
 *  - SARB (South African Reserve Bank) — single transaction limits
 *  - Transfer Duty Act — property value tax bands
 *  - FIC Act Section 21 — beneficial ownership reporting threshold
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract JurisdictionRegistry is Ownable {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Defines KYC tier thresholds per FICA requirements
    struct FICATier {
        uint256 minTransactionValue; // Minimum value triggering this tier (ZAR, 18 decimals)
        uint256 maxTransactionValue; // Maximum value for this tier (ZAR, 18 decimals)
        uint8 requiredDocuments; // Number of documents required (1=ID only, 2=ID+proof, 3=full FICA)
        bool requiresBeneficialOwnership; // FIC Act Section 21 trigger
    }

    /// @notice Transfer duty bands per Transfer Duty Act
    struct TransferDutyBand {
        uint256 thresholdValue; // Property value upper bound (ZAR, 18 decimals)
        uint256 dutyRateBps; // Duty rate in basis points (e.g. 300 = 3%)
    }

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum single transaction value permitted by SARB (ZAR, 18 decimals)
    uint256 public sarbTransactionLimit;

    /// @notice Beneficial ownership reporting threshold per FIC Act Section 21 (ZAR, 18 decimals)
    uint256 public ficaBeneficialOwnershipThreshold;

    /// @notice FICA KYC tiers — tierId => FICATier
    mapping(uint8 => FICATier) public ficaTiers;

    /// @notice Transfer duty bands — index => TransferDutyBand
    mapping(uint8 => TransferDutyBand) public transferDutyBands;

    /// @notice Total number of FICA tiers registered
    uint8 public ficaTierCount;

    /// @notice Total number of transfer duty bands registered
    uint8 public transferDutyBandCount;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event FICATierUpdated(uint8 indexed tierId, uint256 minValue, uint256 maxValue);
    event TransferDutyBandUpdated(uint8 indexed bandId, uint256 threshold, uint256 rateBps);
    event SARBLimitUpdated(uint256 oldLimit, uint256 newLimit);
    event FICAThresholdUpdated(uint256 oldThreshold, uint256 newThreshold);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error JurisdictionRegistry__InvalidTierId(uint8 tierId);
    error JurisdictionRegistry__InvalidBandId(uint8 bandId);
    error JurisdictionRegistry__ZeroValue();
    error JurisdictionRegistry__InvalidRange(uint256 min, uint256 max);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Initialises registry with baseline RSA regulatory values
    /// @param _initialOwner Protocol deployer — typically the REITFactory or multisig
    constructor(address _initialOwner) Ownable(_initialOwner) {
        // SARB single transaction limit — R10 million
        sarbTransactionLimit = 10_000_000e18;

        // FIC Act Section 21 beneficial ownership threshold — R25 million
        ficaBeneficialOwnershipThreshold = 25_000_000e18;
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets or updates a FICA KYC tier
    /// @param _tierId Tier identifier (0=basic, 1=standard, 2=enhanced)
    /// @param _minValue Minimum transaction value triggering this tier
    /// @param _maxValue Maximum transaction value for this tier
    /// @param _requiredDocs Number of documents required
    /// @param _requiresBeneficialOwnership Whether FIC Act Section 21 applies
    function setFICATier(
        uint8 _tierId,
        uint256 _minValue,
        uint256 _maxValue,
        uint8 _requiredDocs,
        bool _requiresBeneficialOwnership
    ) external onlyOwner {
        if (_minValue >= _maxValue) revert JurisdictionRegistry__InvalidRange(_minValue, _maxValue);
        if (_requiredDocs == 0) revert JurisdictionRegistry__ZeroValue();

        ficaTiers[_tierId] = FICATier({
            minTransactionValue: _minValue,
            maxTransactionValue: _maxValue,
            requiredDocuments: _requiredDocs,
            requiresBeneficialOwnership: _requiresBeneficialOwnership
        });

        if (_tierId >= ficaTierCount) ficaTierCount = _tierId + 1;

        emit FICATierUpdated(_tierId, _minValue, _maxValue);
    }

    /// @notice Sets or updates a transfer duty band
    /// @param _bandId Band identifier (0=exempt, 1=low, 2=mid, 3=high)
    /// @param _threshold Upper property value bound for this band
    /// @param _rateBps Duty rate in basis points
    function setTransferDutyBand(
        uint8 _bandId,
        uint256 _threshold,
        uint256 _rateBps
    ) external onlyOwner {
        if (_threshold == 0) revert JurisdictionRegistry__ZeroValue();

        transferDutyBands[_bandId] = TransferDutyBand({
            thresholdValue: _threshold,
            dutyRateBps: _rateBps
        });

        if (_bandId >= transferDutyBandCount) transferDutyBandCount = _bandId + 1;

        emit TransferDutyBandUpdated(_bandId, _threshold, _rateBps);
    }

    /// @notice Updates the SARB single transaction limit
    function setSARBLimit(uint256 _newLimit) external onlyOwner {
        if (_newLimit == 0) revert JurisdictionRegistry__ZeroValue();
        emit SARBLimitUpdated(sarbTransactionLimit, _newLimit);
        sarbTransactionLimit = _newLimit;
    }

    /// @notice Updates the FICA beneficial ownership threshold
    function setFICAThreshold(uint256 _newThreshold) external onlyOwner {
        if (_newThreshold == 0) revert JurisdictionRegistry__ZeroValue();
        emit FICAThresholdUpdated(ficaBeneficialOwnershipThreshold, _newThreshold);
        ficaBeneficialOwnershipThreshold = _newThreshold;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the FICA tier applicable to a given transaction value
    /// @param _value Transaction value in ZAR (18 decimals)
    /// @return tierId The applicable tier ID
    /// @return tier The full FICATier struct
    function getApplicableFICATier(uint256 _value)
        external
        view
        returns (uint8 tierId, FICATier memory tier)
    {
        for (uint8 i = 0; i < ficaTierCount; i++) {
            if (
                _value >= ficaTiers[i].minTransactionValue &&
                _value <= ficaTiers[i].maxTransactionValue
            ) {
                return (i, ficaTiers[i]);
            }
        }
        revert JurisdictionRegistry__InvalidTierId(0);
    }

    /// @notice Calculates transfer duty for a given property value
    /// @param _propertyValue Property value in ZAR (18 decimals)
    /// @return dutyAmount Duty payable in ZAR (18 decimals)
    function calculateTransferDuty(uint256 _propertyValue)
        external
        view
        returns (uint256 dutyAmount)
    {
        for (uint8 i = 0; i < transferDutyBandCount; i++) {
            if (_propertyValue <= transferDutyBands[i].thresholdValue) {
                return (_propertyValue * transferDutyBands[i].dutyRateBps) / 10_000;
            }
        }
        // Above all bands — apply highest band rate
        uint8 lastBand = transferDutyBandCount - 1;
        return (_propertyValue * transferDutyBands[lastBand].dutyRateBps) / 10_000;
    }

    /// @notice Checks whether a value exceeds the SARB transaction limit
    function exceedsSARBLimit(uint256 _value) external view returns (bool) {
        return _value > sarbTransactionLimit;
    }

    /// @notice Checks whether beneficial ownership reporting is required
    function requiresBeneficialOwnershipReport(uint256 _value) external view returns (bool) {
        return _value >= ficaBeneficialOwnershipThreshold;
    }
}
