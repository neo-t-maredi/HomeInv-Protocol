const TECH_STACK = [
    { icon: 'zap',       color: 'text-indigo-400', bg: 'bg-indigo-500/20', name: 'zkSync Era',  sub: 'Layer 2 Scaling' },
    { icon: 'file-code', color: 'text-pink-400',   bg: 'bg-pink-500/20',   name: 'Solidity',    sub: 'Smart Contracts' },
    { icon: 'shield',    color: 'text-amber-400',  bg: 'bg-amber-500/20',  name: 'Chainlink',   sub: 'Price Feeds' },
    { icon: 'landmark',  color: 'text-green-400',  bg: 'bg-green-500/20',  name: 'IPFS',        sub: 'Document Storage' },
];

export function renderTechnology() {
    return `
    <section id="technology" class="py-32 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-b from-transparent via-indigo-900/10 to-transparent"></div>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            <div class="grid lg:grid-cols-2 gap-16 items-center">
                <div class="order-2 lg:order-1">
                    <div class="grid grid-cols-2 gap-4">
                        ${TECH_STACK.map(t => `
                        <div class="glass rounded-2xl p-6 text-center hover:bg-white/5 transition-colors cursor-pointer">
                            <div class="w-12 h-12 mx-auto mb-4 rounded-full ${t.bg} flex items-center justify-center">
                                <i data-lucide="${t.icon}" class="w-6 h-6 ${t.color}"></i>
                            </div>
                            <div class="font-semibold mb-1">${t.name}</div>
                            <div class="text-xs text-gray-500">${t.sub}</div>
                        </div>`).join('')}
                    </div>
                </div>
                <div class="order-1 lg:order-2 space-y-6">
                    <h2 class="text-4xl md:text-5xl font-bold leading-tight">
                        Built for <span class="gradient-text">Scale</span> & <span class="gradient-text">Security</span>
                    </h2>
                    <p class="text-lg text-gray-400 leading-relaxed">
                        Leveraging zero-knowledge rollups for gas-efficient transactions, our protocol ensures micro-investments and daily rental distributions remain economically viable.
                    </p>
                    <ul class="space-y-4">
                        ${['99% cheaper transactions than Ethereum mainnet', 'Inherited Ethereum security via zk-proofs', 'Real-time rent distribution automation'].map(item => `
                        <li class="flex items-center space-x-3">
                            <div class="w-6 h-6 rounded-full bg-green-500/20 flex items-center justify-center">
                                <i data-lucide="check" class="w-4 h-4 text-green-400"></i>
                            </div>
                            <span class="text-gray-300">${item}</span>
                        </li>`).join('')}
                    </ul>
                </div>
            </div>
        </div>
    </section>`;
}
