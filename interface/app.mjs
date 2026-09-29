import { investors, starterLedger, parseAmount, pending, recordRent, claim, vaultBalance, money } from './ledger.mjs';
let state = starterLedger();
const el = id => document.getElementById(id);
function render() {
  for(const [id,value] of [['rent-total',state.rent],['investor-total',state.accrued],['treasury-total',state.treasury],['equity-total',state.equity],['vault-balance',vaultBalance(state)],['tenant-01',state.tenants['01']],['tenant-02',state.tenants['02']]]) el(id).textContent=money(value);
  el('investors').replaceChildren();
  for(const investor of investors) {
    const available=pending(state,investor.id), row=document.createElement('tr');
    for(const text of [`${investor.name} / ${investor.id==='A'?'60':'40'}%`,money(state.claimed[investor.id]),money(available)]){const td=document.createElement('td');td.textContent=text;row.append(td);}
    const td=document.createElement('td'),button=document.createElement('button');button.textContent=available>0n?'Claim yield ↗':'Up to date';button.disabled=available===0n;button.setAttribute('aria-label',`Claim yield for ${investor.name}`);button.addEventListener('click',()=>{try{state=claim(state,investor.id);render();message(`${investor.name} claimed ${money(available)} demo units. Tenant reserves are unchanged.`);}catch(e){message(e.message,true);}});td.append(button);row.append(td);el('investors').append(row);
  }
  const outstanding=state.accrued-state.claimed.A-state.claimed.B;
  el('balance-description').textContent=`${money(outstanding)} investor allocation remaining (including rounding dust) + ${money(state.equity)} tenant reserve.`;
  const conserved=state.rent===state.treasury+state.claimed.A+state.claimed.B+vaultBalance(state);
  el('balance-status').textContent=conserved?'Ledger reconciled':'Ledger mismatch';
  el('event-count').textContent=`${state.events.length} ENTRIES`;
  el('history').replaceChildren();
  state.events.slice(-12).reverse().forEach((event,index)=>{const tr=document.createElement('tr');for(const text of [String(state.events.length-index).padStart(2,'0'),event.kind==='rent'?'Rent allocated':'Yield claimed',event.kind==='rent'?`Tenant ${event.tenant}`:`Investor ${event.investor}`,money(event.amount)]){const td=document.createElement('td');td.textContent=text;tr.append(td);}el('history').append(tr);});
}
function message(text,error=false){el('message').textContent=text;el('message').classList.toggle('error',error);}
el('rent-form').addEventListener('submit',event=>{event.preventDefault();try{const amount=parseAmount(el('amount').value.trim());const splits=['split-investors','split-treasury','split-equity'].map(id=>Number(el(id).value)*100);state=recordRent(state,amount,el('tenant').value,splits);render();message(`Recorded ${money(amount)} demo units. Allocations reconcile to the payment.`);}catch(e){message(e.message,true);}});
el('reset').addEventListener('click',()=>{state=starterLedger();el('rent-form').reset();render();message('Reset: one illustrative 1,000.00-unit payment.');});
el('export').addEventListener('click',()=>{const data={model:'HomeInv local demonstration ledger',unit:'Demo token, 2 decimals; integer strings are smallest units',source:'Illustrative user-entered payments, no blockchain connection',...state};const blob=new Blob([JSON.stringify(data,(_,v)=>typeof v==='bigint'?v.toString():v,2)],{type:'application/json'});const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download='homeinv-demo-ledger.json';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);message('Demo ledger exported as JSON.');});
render();
