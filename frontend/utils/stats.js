const STATS = [
    { target: 2400, label: 'Families Housed' },
    { target: 156,  label: 'Properties Funded' },
    { target: 12.5, label: 'Million USD Raised' },
    { target: 89,   label: 'Community DAOs' },
];

export function renderStats() {
    return `
    <section class="py-20 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-r from-indigo-900/20 to-purple-900/20"></div>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-8">
                ${STATS.map(s => `
                <div class="stat-card glass rounded-2xl p-6 text-center">
                    <div class="text-4xl font-bold gradient-text mb-2 counter" data-target="${s.target}">0</div>
                    <div class="text-sm text-gray-400">${s.label}</div>
                </div>`).join('')}
            </div>
        </div>
    </section>`;
}

export function initCounters(gsap, ScrollTrigger) {
    document.querySelectorAll('.counter').forEach(counter => {
        const target = parseFloat(counter.getAttribute('data-target'));
        const isDecimal = target % 1 !== 0;
        gsap.to(counter, {
            scrollTrigger: { trigger: counter, start: 'top 85%', toggleActions: 'play none none reverse' },
            innerHTML: target,
            duration: 2,
            snap: { innerHTML: isDecimal ? 0.1 : 1 },
            ease: 'power2.out',
            onUpdate() {
                counter.innerHTML = isDecimal
                    ? parseFloat(counter.innerHTML).toFixed(1)
                    : Math.ceil(counter.innerHTML).toLocaleString();
            }
        });
    });
}
