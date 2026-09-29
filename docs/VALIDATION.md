# Accounting repair validation

Date: 29 September 2026. Base revision: f8960d748076d38f46783b6935cb0280bc945e48.

- Foundry 1.7.1: 18 contract tests passed, 0 failed.
- Conservation fuzz test: 256 runs across two rent payments and interleaved claims.
- Coverage includes repeated claims, claim-order independence, multiple payments, donation exclusion, separate tenant reserves, split changes, rounding, final claims after completion, third-party claim destination, identity expiry, unauthorized split changes, and rejection of incoming transfer fees.
- Five Node ledger-model tests passed. They cover initial allocation, repeated-claim protection, claim order and conservation, rounding, subsequent split changes, and input parsing.
- JavaScript syntax check passed.
- Existing Solidity sources were formatted to satisfy the repository's formatting gate. Behaviour changes are in RentVault and PropertyPool; other Solidity changes are formatting/comment corrections.
- No contract deployment, remote commit, or push was performed.
- Browser launch is unavailable in this environment. Desktop/mobile rendering and click-through acceptance need to be checked on the user's machine; no screenshots have been claimed as verified.

The visual model intentionally has no wallet, RPC provider, external font, analytics, third-party script, or npm dependency. The tests do not establish legal compliance, property backing, a full security audit, or production suitability.
