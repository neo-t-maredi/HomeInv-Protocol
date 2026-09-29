// Local demonstration model. BigInt values are smallest token units (two demo decimals).
export const investors = [{ id: 'A', name: 'Investor A', contribution: 60000n }, { id: 'B', name: 'Investor B', contribution: 40000n }];
export const funding = 100000n;
export const freshLedger = () => ({ rent: 0n, accrued: 0n, treasury: 0n, equity: 0n, claimed: { A: 0n, B: 0n }, tenants: { '01': 0n, '02': 0n }, events: [] });
export function parseAmount(text) {
  if (!/^\d{1,9}(\.\d{1,2})?$/.test(String(text))) throw new Error('Enter a positive amount with at most two decimals (maximum 999,999,999.99).');
  const [whole, fraction = ''] = String(text).split('.');
  const amount = BigInt(whole) * 100n + BigInt(fraction.padEnd(2, '0'));
  if (amount <= 0n) throw new Error('Rent must be greater than zero.');
  return amount;
}
export function validateSplits(splits) {
  if (splits.length !== 3 || splits.some(s => !Number.isInteger(s) || s < 0 || s > 10000) || splits.reduce((a,b) => a+b,0) !== 10000) throw new Error('The three shares must total 100%.');
}
export function pending(state, id) {
  const investor = investors.find(i => i.id === id);
  if (!investor) throw new Error('Unknown investor');
  return state.accrued * investor.contribution / funding - state.claimed[id];
}
export function recordRent(state, amount, tenant, splits) {
  validateSplits(splits);
  if (amount <= 0n || !Object.hasOwn(state.tenants, tenant)) throw new Error('Invalid rent or tenant');
  const investor = amount * BigInt(splits[0]) / 10000n;
  const treasury = amount * BigInt(splits[1]) / 10000n;
  const equity = amount - investor - treasury;
  return { ...state, rent: state.rent + amount, accrued: state.accrued + investor, treasury: state.treasury + treasury, equity: state.equity + equity, tenants: { ...state.tenants, [tenant]: state.tenants[tenant] + equity }, events: [...state.events, { kind: 'rent', tenant, amount, investor, treasury, equity }] };
}
export function claim(state, id) {
  const amount = pending(state, id);
  if (amount <= 0n) throw new Error('No new yield to claim.');
  return { ...state, claimed: { ...state.claimed, [id]: state.claimed[id] + amount }, events: [...state.events, { kind: 'claim', investor: id, amount }] };
}
export const vaultBalance = state => state.accrued - state.claimed.A - state.claimed.B + state.equity;
export const starterLedger = () => recordRent(freshLedger(), 100000n, '01', [7000,1000,2000]);
export const money = amount => `${(amount / 100n).toLocaleString('en-US')}.${(amount % 100n).toString().padStart(2,'0')}`;
