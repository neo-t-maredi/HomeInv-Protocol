// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title HINVToken
 * @author HomeInv Protocol
 * @notice Governance token for the HomeInv decentralised REIT protocol
 * @dev ERC-20 with voting snapshots (ERC20Votes) and gasless approvals (ERC20Permit)
 *
 * HomeInv tokenises South African residential property into on-chain REITs,
 * giving previously excluded communities fractional ownership and yield access.
 *
 * HINV holders govern:
 *  - Property approvals via REITFactory
 *  - Street Committee DAO (CommunityOracle) proposals
 *  - Protocol treasury and fee parameters
 *
 * Supply:   100,000,000 HINV (fixed, no inflation)
 * Standard: ERC-20 + ERC20Votes + ERC20Permit
 * Network:  zkSync Era (EVM-compatible)
 *
 * @custom:security-contact security@homeinv.io
 * @custom:hackathon ETH Cape Town 2026
 */

import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Votes} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {ERC20Permit} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Nonces} from "lib/openzeppelin-contracts/contracts/utils/Nonces.sol";

contract HINVToken is ERC20, ERC20Votes, ERC20Permit, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint256 public constant MAX_SUPPLY = 100_000_000e18; // 100 million HINV


    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploys HINV and mints entire fixed supply to deployer
    /// @param _initialOwner Address that receives initial supply and admin rights
    constructor(address _initialOwner)
        ERC20("HomeInv", "HINV")
        ERC20Permit("HomeInv")
        Ownable(_initialOwner)
    {
        _mint(_initialOwner, MAX_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                              OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Required by Solidity — ERC20Votes hooks into every token transfer
    /// to update voting snapshots
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    /// @dev Required by Solidity — ERC20Permit needs access to nonces
    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}