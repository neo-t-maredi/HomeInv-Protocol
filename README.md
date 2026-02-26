# HomeInv Protocol

> **Decentralised REIT infrastructure for South African residential property**  
> ETH Cape Town 2026 — Built on zkSync Era

---

## What is HomeInv?

HomeInv tokenises South African residential property into on-chain REITs, giving previously excluded communities fractional ownership and yield access.

The protocol encodes real RSA regulatory compliance — FICA, SARB, Transfer Duty Act — directly on-chain. Every interaction is gated by KYC verification. Every rent payment distributes yield automatically. Every tenant accumulates equity over time.

**The core mechanic:** Tenants pay rent. A portion of that rent converts into PropertyTokens. Over time, tenants become fractional owners of the property they live in. Renter to owner — trustlessly, transparently, on-chain.

---

## Architecture

### Contract Layers

```
L0 — Foundation (no dependencies)
├── HINVToken.sol           — ERC-20 governance token (100M fixed supply, ERC20Votes)
└── JurisdictionRegistry.sol — RSA regulatory rules (FICA tiers, SARB limits, Transfer Duty bands)

L1 — Compliance
└── IdentityRegistry.sol    — KYC/FICA verification registry, gates all protocol interactions

L2 — Ownership
└── PropertyToken.sol       — ERC-20 fractional ownership token per property, compliance-gated transfers

L3 — Lifecycle
└── PropertyPool.sol        — Four-stage state machine (PENDING → FUNDING → ACTIVE → CLOSED)

L4 — Yield & Equity
├── RentVault.sol           — Splits rent: investors (yield) + manager (ops) + treasury (protocol)
└── EquityVault.sol         — Accumulates tenant equity credits, converts to PropertyTokens

L5 — Orchestration
├── CommunityOracle.sol     — Street Committee DAO, verifies real-world property events on-chain
└── REITFactory.sol         — Entry point, deploys and wires full property investment instance
```

### Interfaces

```
src/interfaces/
├── IJurisdictionRegistry.sol
├── IIdentityRegistry.sol
├── IPropertyToken.sol
├── IPropertyPool.sol
├── IRentVault.sol
├── IEquityVault.sol
└── IREITFactory.sol
```

### Dependency Graph

```
REITFactory ──────────────────────────────────────────┐
    │                                                  │
    ├──► IdentityRegistry ──► JurisdictionRegistry     │
    ├──► PropertyToken    ──► IdentityRegistry          │
    ├──► PropertyPool     ──► PropertyToken             │
    ├──► RentVault        ──► PropertyToken             │
    └──► EquityVault      ──► PropertyToken             │
                                                       │
CommunityOracle ◄──────────────────────────────────────┘
```

---

## Regulatory Framework (On-Chain)

HomeInv encodes South African law directly into smart contracts:

| Regulation | Contract | Implementation |
|---|---|---|
| FICA — KYC tiers | `JurisdictionRegistry` | Three-tier verification system (Basic / Standard / Enhanced Due Diligence) |
| SARB — transaction limits | `JurisdictionRegistry` | R10M single transaction ceiling |
| FIC Act Section 21 | `JurisdictionRegistry` | R25M beneficial ownership reporting threshold |
| Transfer Duty Act | `JurisdictionRegistry` | Banded duty rates in basis points |
| FICA compliance | `IdentityRegistry` | Expiring KYC with document hashes, sanctions screening |

---

## Key Mechanics

### Yield Distribution — Reward Per Token Share
```
accumulatedYieldPerToken += (rentAmount * 1e18) / totalSupply

investorYield = (balance * (accumulated - snapshot)) / 1e18
```
No loops. Constant gas regardless of investor count. Same pattern as Synthetix and Uniswap.

### Rent Split
```
Rent payment
    ├── Property Manager  — up to 20% (operational costs)
    ├── Protocol Treasury — up to 20% (reserve + development)
    └── Investors         — remainder (yield, distributed via reward-per-token)
```

### Tenant → Owner Conversion
```
Tenant pays rent
    └── EquityVault receives equity portion (configurable %)
            └── Credits accumulate per tenant per property
                    └── Threshold hit → PropertyTokens transferred to tenant
```

### Compliance Gating
Every `PropertyToken` transfer checks:
- Sender verified in `IdentityRegistry` ✓
- Receiver verified in `IdentityRegistry` ✓  
- Neither party sanctioned ✓
- Neither party's KYC expired ✓
- Transfers not paused ✓

Enforced at the `_update` hook — invisible to users, impossible to bypass.

---

## CommunityOracle — Spatial Justice On-Chain

The Street Committee DAO verifies real-world property events that no centralised oracle can:

```
MAINTENANCE_COMPLETED       — repairs done, property habitable
LEGAL_OCCUPANCY_CONFIRMED   — tenant legally occupying  
CONSTRUCTION_MILESTONE      — development phase verified
COMPLIANCE_BREACH           — flags issue, can pause distributions
VACANCY_REPORTED            — property unoccupied
```

Committee members propose events with IPFS evidence hashes. Quorum vote approves. Verified events are immutable on-chain. Truth comes from the community, not a corporation.

---

## Property Lifecycle

```
PENDING  ──► Due diligence, compliance checks
    │
    ▼ (owner approves)
FUNDING  ──► Capital raise open, investors purchase PropertyTokens
    │
    ▼ (funding target met — self-triggers)
ACTIVE   ──► Operational, rent flowing, yield distributing, equity accumulating
    │
    ▼ (owner closes)
CLOSED   ──► Lifecycle complete, transfers paused, proceeds distributed
```

---

## Stack

| Layer | Technology |
|---|---|
| Smart Contracts | Solidity ^0.8.24 |
| Framework | Foundry (foundry-zksync fork) |
| Network | zkSync Era |
| DevOps | Tenderly (simulation + monitoring) |
| Dependencies | OpenZeppelin v5, Chainlink |
| Token Standards | ERC-20, ERC20Votes, ERC20Permit |

---

## Project Structure

```
homeinv-protocol/
├── src/
│   ├── core/
│   │   └── PropertyPool.sol
│   ├── factory/
│   │   └── REITFactory.sol
│   ├── interfaces/
│   │   ├── ICommunityOracle.sol
│   │   ├── IEquityVault.sol
│   │   ├── IIdentityRegistry.sol
│   │   ├── IJurisdictionRegistry.sol
│   │   ├── IPropertyPool.sol
│   │   ├── IPropertyToken.sol
│   │   └── IRentVault.sol
│   ├── oracle/
│   │   └── CommunityOracle.sol
│   ├── registries/
│   │   ├── IdentityRegistry.sol
│   │   └── JurisdictionRegistry.sol
│   ├── tokens/
│   │   ├── HINVToken.sol
│   │   └── PropertyToken.sol
│   └── vaults/
│       ├── EquityVault.sol
│       └── RentVault.sol
├── test/
├── script/
├── lib/
└── foundry.toml
```

---

## Getting Started

### Prerequisites

```bash
# Install foundry-zksync (required for zkSync compilation)
curl -L https://raw.githubusercontent.com/matter-labs/foundry-zksync/main/install-foundry-zksync | bash
```

### Install

```bash
git clone https://github.com/homeinv/homeinv-protocol
cd homeinv-protocol
forge install
```

### Build

```bash
forge build --zksync
```

### Test

```bash
forge test --zksync
```

---

## Deployment Order

```
1. JurisdictionRegistry
2. HINVToken
3. IdentityRegistry  (needs JurisdictionRegistry)
4. RentVault         (needs treasury address)
5. EquityVault
6. CommunityOracle
7. REITFactory       (needs all of the above)
```

After deployment, call `REITFactory.submitProperty()` to deploy a complete property investment instance in a single transaction.

---

## Security

- `ReentrancyGuard` on all value-moving functions
- Checks → Effects → Interactions enforced throughout
- `immutable` trust anchors — core protocol addresses locked at deployment
- Role-based access control — `VERIFIER_ROLE`, `COMMITTEE_MEMBER_ROLE` independently revocable
- KYC expiry enforced on every token transfer
- Sanctions screening hard-blocks regardless of verification status
- Emergency pause mechanism on all `PropertyToken` contracts
- Max 20% split cap on manager and treasury — investor yield protected by code

---

## Social Impact

South Africa has one of the highest housing inequality rates in the world. HomeInv addresses this by:

- Removing the lump-sum barrier to property ownership
- Enabling fractional investment from any verified wallet
- Converting rent payments into equity — tenants become owners over time
- Encoding community governance via Street Committee DAO
- Making compliance transparent and auditable on-chain

*Built for ETH Cape Town 2026.*

---

## Licence

