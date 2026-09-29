# Capture and acceptance checks

Start the interface with the README command and open http://127.0.0.1:3003.

1. Starting state: rent 1,000.00; investor allocation 700.00; treasury 100.00; tenant reserve 200.00. A can claim 420.00 and B 280.00.
2. Claim A, then B. Both become Up to date, and held-in-vault becomes 200.00. Tenant reserve stays 200.00.
3. Add another 1,000.00 rent payment. New available yield is again A 420.00 and B 280.00. Treasury and reserves accumulate.
4. Select Tenant 02 and record a payment. That tenant's reserve updates separately.
5. Change splits to 50/10/40. Only the next payment uses them. Invalid totals must not add an entry.
6. Export JSON and inspect its illustrative-data label. Reset returns to the original one-payment scenario.
7. Check a narrow/mobile window for clipped content. Investor tables may scroll horizontally where needed.

Save a hero/overview capture as `docs/screenshots/overview.png` and a ledger-after-claims capture as `docs/screenshots/rent-ledger.png`. Keep the demo labels visible. Add the images to README only after capturing the actual running interface.
