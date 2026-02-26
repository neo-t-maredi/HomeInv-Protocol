// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IJurisdictionRegistry
 * @author HomeInv Protocol
 * @notice Interface for JurisdictionRegistry — exposes RSA regulatory rule queries
 */
interface IJurisdictionRegistry {
    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct FICATier {
        uint256 minTransactionValue;
        uint256 maxTransactionValue;
        uint8 requiredDocuments;
        bool requiresBeneficialOwnership;
    }

    struct TransferDutyBand {
        uint256 thresholdValue;
        uint256 dutyRateBps;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function sarbTransactionLimit() external view returns (uint256);
    function ficaBeneficialOwnershipThreshold() external view returns (uint256);
    function ficaTierCount() external view returns (uint8);
    function transferDutyBandCount() external view returns (uint8);
    function getApplicableFICATier(uint256 _value) external view returns (uint8 tierId, FICATier memory tier);
    function calculateTransferDuty(uint256 _propertyValue) external view returns (uint256 dutyAmount);
    function exceedsSARBLimit(uint256 _value) external view returns (bool);
    function requiresBeneficialOwnershipReport(uint256 _value) external view returns (bool);
}

