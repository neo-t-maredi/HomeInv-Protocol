// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {HINVToken} from "../src/tokens/HINVToken.sol";
import {JurisdictionRegistry} from "../src/registries/JurisdictionRegistry.sol";
import {IdentityRegistry} from "../src/registries/IdentityRegistry.sol";
import {RentVault} from "../src/vaults/RentVault.sol";
import {EquityVault} from "../src/vaults/EquityVault.sol";
import {CommunityOracle} from "../src/oracle/CommunityOracle.sol";
import {REITFactory} from "../src/factory/REITFactory.sol";

contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying HomeInv Protocol...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        // L0 — Foundation
        JurisdictionRegistry jurisdictionRegistry = new JurisdictionRegistry(deployer);
        console.log("JurisdictionRegistry:", address(jurisdictionRegistry));

        HINVToken hinvToken = new HINVToken(deployer);
        console.log("HINVToken:", address(hinvToken));

        // L1 — Compliance
        IdentityRegistry identityRegistry = new IdentityRegistry(
            deployer,
            address(jurisdictionRegistry)
        );
        console.log("IdentityRegistry:", address(identityRegistry));

        // L4 — Vaults
        RentVault rentVault = new RentVault(deployer, deployer);
        console.log("RentVault:", address(rentVault));

        EquityVault equityVault = new EquityVault(deployer);
        console.log("EquityVault:", address(equityVault));

        // L5 — Oracle
        CommunityOracle communityOracle = new CommunityOracle(
            deployer,
            3,        // quorum — 3 votes required
            7 days    // voting period
        );
        console.log("CommunityOracle:", address(communityOracle));

        // L5 — Factory
        REITFactory reitFactory = new REITFactory(
            address(identityRegistry),
            address(jurisdictionRegistry),
            address(rentVault),
            address(equityVault),
            deployer, // treasury
            deployer
        );
        console.log("REITFactory:", address(reitFactory));

        vm.stopBroadcast();

        console.log("\n=== HomeInv Protocol Deployed ===");
        console.log("JurisdictionRegistry:", address(jurisdictionRegistry));
        console.log("HINVToken:           ", address(hinvToken));
        console.log("IdentityRegistry:    ", address(identityRegistry));
        console.log("RentVault:           ", address(rentVault));
        console.log("EquityVault:         ", address(equityVault));
        console.log("CommunityOracle:     ", address(communityOracle));
        console.log("REITFactory:         ", address(reitFactory));
    }
}