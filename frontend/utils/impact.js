const COMMUNITIES = [
    {
        name: 'Khayelitsha',
        bg: 'from-indigo-900 to-purple-900',
        iconColor: 'text-indigo-400',
        linkColor: 'text-indigo-400',
        desc: "Cape Town's largest township. 340 units funded, creating 1,200 new homeowners.",
    },
    {
        name: 'Soweto',
        bg: 'from-pink-900 to-rose-900',
        iconColor: 'text-pink-400',
        linkColor: 'text-pink-400',
        desc: 'Johannesburg historic township. 280 units in development with community DAO governance.',
    },
    {
        name: 'Alexandra',
        bg: 'from-amber-900 to-orange-900',
        iconColor: 'text-amber-400',
        linkColor: 'text-amber-400',
        desc: 'High-density urban renewal. 180 units transforming informal settlements.',
    },
];

export function renderImpact() {
    return `
    <section id="impact" class="py-32 relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-16">
                <h2 class="text-4xl md:text-5xl font-bold mb-6">Real <span class="gradient-text">Impact</span>, Real <span class="gradient-text">Communities</span></h2>
                <p class="text-xl text-gray-400">Transforming lives in South African townships through decentralized finance.</p>
            </div>
            <div class="glass rounded-3xl p-8 md:p-12 relative overflow-hidden">
                <div class="grid md:grid-cols-3 gap-8">
                    ${COMMUNITIES.map(c => `
                    <div class="space-y-4">
                        <div class="w-full h-48 rounded-2xl bg-gradient-to-br ${c.bg} flex items-center justify-center">
                            <i data-lucide="map-pin" class="w-12 h-12 ${c.iconColor}"></i>
                        </div>
                        <h3 class="text-xl font-bold">${c.name}</h3>
                        <p class="text-gray-400 text-sm">${c.desc}</p>
                        <div class="flex items-center space-x-2 ${c.linkColor} text-sm cursor-pointer">
                            <span>View Project</span>
                            <i data-lucide="external-link" class="w-4 h-4"></i>
                        </div>
                    </div>`).join('')}
                </div>
            </div>
        </div>
    </section>`;
}
