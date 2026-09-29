import test from 'node:test';
import assert from 'node:assert/strict';
import { freshLedger, starterLedger, recordRent, claim, pending, parseAmount, vaultBalance } from './ledger.mjs';
test('base scenario and repeated claim protection', () => {
  let s = starterLedger();
  assert.equal(pending(s,'A'),42000n); assert.equal(pending(s,'B'),28000n);
  s=claim(s,'A'); assert.throws(()=>claim(s,'A'),/No new yield/);
  s=claim(s,'B'); assert.equal(vaultBalance(s),20000n);
});
test('claim order, later rent, and fund conservation', () => {
  let a=claim(claim(starterLedger(),'A'),'B');
  let b=claim(claim(starterLedger(),'B'),'A');
  assert.deepEqual(a.claimed,b.claimed);
  a=recordRent(a,50000n,'02',[7000,1000,2000]);
  assert.equal(pending(a,'A'),21000n);
  assert.equal(a.tenants['02'],10000n);
  assert.equal(a.rent, a.treasury+a.claimed.A+a.claimed.B+vaultBalance(a));
});
test('rounding remains reserved and donations are not part of this model',()=>{
  let s=recordRent(freshLedger(),11n,'01',[7000,1000,2000]);
  assert.equal(s.equity,3n); s=claim(claim(s,'A'),'B');
  assert.equal(vaultBalance(s),4n);
});
test('split change applies only to subsequent payment',()=>{
  const s=recordRent(starterLedger(),100000n,'01',[5000,1000,4000]);
  assert.equal(pending(s,'A'),72000n); assert.equal(s.equity,60000n);
});
test('input validation rejects ambiguous decimals and invalid splits',()=>{
  assert.equal(parseAmount('10.01'),1001n);
  for(const x of ['-1','0','1e4','1.001','','NaN']) assert.throws(()=>parseAmount(x));
  assert.throws(()=>recordRent(freshLedger(),100n,'01',[7000,1000,1000]));
});
