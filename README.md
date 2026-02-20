# HomeInv Protocol

A Decentralized REIT (dREIT) built on zkSync Era, tackling South African housing inequality through blockchain technology.

## Overview

HomeInv Protocol bridges the gap between global liquidity and local spatial justice. It allows community members and impact investors to fund high-density developments in townships, turning tenants into owners through rent-to-equity smart contracts.

## The Problem

Cape Town's "Missing Middle" housing crisis leaves micro-developers in townships like Khayelitsha and Mitchells Plain without access to formal capital. Traditional banks view these areas as high risk. HomeInv bypasses this entirely.

## How It Works

1. A verified micro-developer submits a property via REITFactory
2. Impact investors contribute stablecoins to the PropertyPool
3. CommunityOracle verifies building completion on the ground
4. Tenants pay rent in stablecoins via RentVault
5. A portion of every rent payment accumulates in EquityVault
6. Over time tenant equity converts to ownership tokens — tenants become owners

## Smart Contracts

| Contract | Description |
|---|---|
| `JurisdictionRegistry` | Stores RSA regulatory rules — FICA, SARB, transfer duty thresholds |
| `IdentityRegistry` | KYC/FICA verification — gates all protocol interactions |
| `REITFactory` | Entry point — accepts property submissions from verified developers |
| `PropertyPool` | One per property — manages funding lifecycle and state machine |
| `RentVault` | Splits rent payments between investors, treasury and equity |
| `EquityVault` | Accumulates tenant equity — converts to ownership tokens over time |
| `CommunityOracle` | Street Committee DAO — verifies physical real-world events |
| `PropertyToken` | ERC-3643 fractional ownership token per property |
| `HINVToken` | ERC-20 governance token |

## Tech Stack

- **Smart Contracts:** Solidity 0.8.20 + Foundry
- **Network:** zkSync Era
- **Standards:** ERC-3643, ERC-20, SafeERC20
- **Monitoring:** Tenderly

## Status

🚧 Active Development — ETH Cape Town 2026

## Built By

Neo — Industrial Automation Engineer turned Blockchain Developer.
Bridging 15 years of energy infrastructure experience with DeFi.