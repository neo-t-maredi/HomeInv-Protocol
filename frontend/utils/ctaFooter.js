export function renderCTA() {
    return `
    <section class="py-32 relative overflow-hidden">
        <div class="absolute inset-0 bg-gradient-to-r from-indigo-600/20 to-purple-600/20"></div>
        <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 text-center">
            <h2 class="text-5xl md:text-6xl font-bold mb-8">Ready to Invest in <span class="gradient-text">Change</span>?</h2>
            <p class="text-xl text-gray-300 mb-12 max-w-2xl mx-auto">
                Join the movement to democratize real estate ownership. Start with as little as $50 and become part of the solution to housing inequality.
            </p>
            <div class="flex flex-col sm:flex-row gap-4 justify-center">
                <button class="btn-primary px-10 py-5 rounded-full font-bold text-lg text-white flex items-center justify-center space-x-2 group">
                    <span>Launch Application</span>
                    <i data-lucide="arrow-right" class="w-5 h-5 group-hover:translate-x-1 transition-transform"></i>
                </button>
                <button class="btn-secondary px-10 py-5 rounded-full font-bold text-lg text-white">Read Whitepaper</button>
            </div>
            <div class="mt-12 flex items-center justify-center space-x-8 text-gray-500">
                ${[['shield-check','Audited by CertiK'],['lock','Non-custodial'],['globe','Regulatory Compliant']].map(([icon,label]) => `
                <div class="flex items-center space-x-2">
                    <i data-lucide="${icon}" class="w-5 h-5"></i>
                    <span class="text-sm">${label}</span>
                </div>`).join('')}
            </div>
        </div>
    </section>`;
}

export function renderFooter() {
    return `
    <footer class="border-t border-gray-800 py-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid md:grid-cols-4 gap-12">
                <div class="space-y-4">
                    <div class="flex items-center space-x-2">
                        <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
                            <i data-lucide="home" class="w-5 h-5 text-white"></i>
                        </div>
                        <span class="text-xl font-bold">HomeInv</span>
                    </div>
                    <p class="text-gray-400 text-sm">Decentralized REIT protocol on zkSync Era, enabling global investment in affordable housing.</p>
                </div>
                ${[
                    ['Protocol', ['Documentation','Smart Contracts','Tokenomics','Governance']],
                    ['Community', ['Discord','Twitter','Telegram','Blog']],
                    ['Legal', ['Privacy Policy','Terms of Service','Risk Disclosure']],
                ].map(([title, links]) => `
                <div>
                    <h4 class="font-semibold mb-4">${title}</h4>
                    <ul class="space-y-2 text-sm text-gray-400">
                        ${links.map(l => `<li><a href="#" class="hover:text-white transition-colors">${l}</a></li>`).join('')}
                    </ul>
                </div>`).join('')}
            </div>
            <div class="border-t border-gray-800 mt-12 pt-8 flex flex-col md:flex-row justify-between items-center">
                <p class="text-gray-500 text-sm">© 2026 HomeInv Protocol. ETH Cape Town.</p>
                <div class="flex space-x-6 mt-4 md:mt-0">
                    ${['twitter','github','linkedin'].map(icon => `
                    <a href="#" class="text-gray-400 hover:text-white transition-colors">
                        <i data-lucide="${icon}" class="w-5 h-5"></i>
                    </a>`).join('')}
                </div>
            </div>
        </div>
    </footer>`;
}
