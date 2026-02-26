const STEPS = [
    {
        num: '01',
        gradient: 'from-indigo-500 to-purple-600',
        color: 'text-indigo-400',
        hoverShadow: 'group-hover:shadow-indigo-500/20',
        title: 'Invest',
        desc: 'Purchase dREIT tokens representing fractional ownership in vetted high-density housing developments across South African townships.',
        cta: 'Learn more',
    },
    {
        num: '02',
        gradient: 'from-pink-500 to-rose-600',
        color: 'text-pink-400',
        hoverShadow: 'group-hover:shadow-pink-500/20',
        title: 'Earn Yield',
        desc: 'Receive monthly rental yield distributions automatically via smart contracts. Transparent, immutable, and instant.',
        cta: 'View Returns',
    },
    {
        num: '03',
        gradient: 'from-amber-500 to-orange-600',
        color: 'text-amber-400',
        hoverShadow: 'group-hover:shadow-amber-500/20',
        title: 'Create Owners',
        desc: 'Tenants build equity through rent payments. After 10 years, they own their home. Investors exit with appreciation.',
        cta: 'See Impact',
    },
];

export function renderHowItWorks() {
    return `
    <section id="how-it-works" class="py-32 relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-20">
                <h2 class="text-4xl md:text-5xl font-bold mb-6">How <span class="gradient-text">HomeInv</span> Works</h2>
                <p class="text-xl text-gray-400 max-w-2xl mx-auto">From investment to ownership, our protocol automates real estate tokenization and rent-to-equity conversion.</p>
            </div>
            <div class="grid md:grid-cols-3 gap-8">
                ${STEPS.map(s => `
                <div class="relative group">
                    <div class="glass rounded-3xl p-8 h-full transition-all duration-500 group-hover:transform group-hover:-translate-y-2 group-hover:shadow-2xl ${s.hoverShadow}">
                        <div class="w-16 h-16 rounded-2xl bg-gradient-to-br ${s.gradient} flex items-center justify-center mb-6 text-2xl font-bold">${s.num}</div>
                        <h3 class="text-2xl font-bold mb-4">${s.title}</h3>
                        <p class="text-gray-400 mb-6">${s.desc}</p>
                        <div class="flex items-center ${s.color} text-sm font-medium">
                            <span>${s.cta}</span>
                            <i data-lucide="arrow-right" class="w-4 h-4 ml-2 group-hover:translate-x-2 transition-transform"></i>
                        </div>
                    </div>
                </div>`).join('')}
            </div>
        </div>
    </section>`;
}
