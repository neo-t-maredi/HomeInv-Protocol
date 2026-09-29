# HomeInv Protocol

A property-finance accounting prototype that follows rent into investor yield, treasury payments, and separately recorded tenant reserves.

Part of [RWA Lab](https://github.com/neo-t-maredi/rwa-lab).

## What is implemented

| Component | Current behaviour |
| --- | --- |
| JurisdictionRegistry | Owner-controlled jurisdiction settings |
| IdentityRegistry | Owner-controlled wallet verification and expiry flags |
| REITFactory | Property submission records and links to externally deployed pools |
| PropertyPool | Verified-wallet contributions, fixed contribution records, owner-controlled activation and completion |
| RentVault | Cumulative investor entitlements, prior-claim tracking, treasury transfers, per-tenant reserve accounting |
| Rent ledger interface | Local demonstration of allocations, claims, rounding, and JSON export |

The interface is an illustrative local model, not a wallet-connected application. Registry flags do not establish legal compliance. There is no live property offering, deployed ownership token, or independently verified property dataset in this package.

## Run the rent ledger

No npm install or frontend build is required. From the repository root:

```bash
python3 -m http.server 3003 --bind 127.0.0.1 --directory interface
```

Open **http://127.0.0.1:3003**. Stop the server with Ctrl+C.

The starting scenario records a 1,000.00-unit demo rent payment. Its allocation is 700.00 to investors, 100.00 to treasury, and 200.00 to the tenant reserve. Investor A has a 60% funding share; Investor B has 40%. Available yield is therefore 420.00 and 280.00. Claiming both leaves 200.00 reserved in the vault model.

Record another payment to accrue new yield. Change the splits to affect future payments only. Reset returns to the starting scenario, and export saves the session ledger as JSON. Demo values use two decimals; JSON integer strings represent the smallest demo units. The contracts operate in the configured token's smallest units, without assuming two decimals.

## Contract checks

With Foundry installed:

```bash
git submodule update --init --recursive
forge fmt --check
forge test -vv
```

With Node.js 20 or newer, test the local ledger model:

```bash
node --test interface/ledger.test.mjs
```

Validation on 29 September 2026: **18 contract tests passed**, including 256 fuzz cases; **5 ledger-model tests passed**. See [validation notes](docs/VALIDATION.md). This is a focused accounting repair, not a full protocol audit.

## Accounting rules

1. The rent payer must have an unexpired verification flag, and the pool must be active.
2. Investor and treasury allocations round down; the remainder is assigned to the tenant reserve. This can include rounding dust even when the configured equity share is zero.
3. Investor entitlement is `floor(totalInvestorAccrued × contribution / fundingTarget)` minus prior claimed yield. Funding weights cannot change after activation.
4. Claims pay the investor address, regardless of who triggers them. Recorded entitlements remain claimable after pool completion, subject to identity verification.
5. Tenant reserves are held in the same contract but tracked separately and excluded from the claim formula. There is no equity redemption function.
6. Direct token donations do not create investor entitlement. Investor rounding dust remains in the vault; cumulative accounting may make it claimable after later payments.

## Important remaining boundaries

- PropertyPool has no construction disbursement, contribution refund, or principal redemption path. Do not fund this scaffold with real assets.
- EquityVault, CommunityOracle, PropertyToken, and HINVToken are not implemented.
- Tenant reserve entries are not title deeds, transferable ownership, or redeemable equity.
- Only standard, exact-transfer, non-rebasing ERC-20 tokens are supported. Incoming transfer-fee tokens are rejected; malicious or behaviour-changing tokens are outside the model.
- Identity and jurisdiction parameters are administrator-controlled prototype settings, not verified statements of current law. IdentityRegistry does not recheck jurisdiction activity on every action.
- Production roles, custody, property verification, deployment, and frontend transaction integration remain separate work.
- These source changes do not modify any previously deployed contract.

## Screenshots

The interface is ready for local capture. Follow [the screenshot guide](docs/SCREENSHOTS.md). Screenshots should show the labelled demonstration ledger and its real rendered state; none are fabricated or bundled as proof of a live system.
