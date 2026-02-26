export function renderMission() {
    return `
    <section id="mission" class="py-32 relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid md:grid-cols-2 gap-16 items-center">
                <div class="space-y-6 mission-content">
                    <h2 class="text-4xl md:text-5xl font-bold leading-tight">
                        Tackling Housing <span class="gradient-text">Inequality</span> Through Blockchain
                    </h2>
                    <p class="text-lg text-gray-400 leading-relaxed">
                        South Africa's townships face a critical housing shortage with over 2.4 million families on waiting lists. HomeInv Protocol democratizes access to real estate investment while providing dignified housing solutions.
                    </p>
                    <div class="space-y-4 pt-4">
                        ${missionFeature('building-2', 'text-indigo-400', 'High-Density Developments', 'Funding sustainable, community-centered housing projects in underserved areas.')}
                        ${missionFeature('key', 'text-pink-400', 'Rent-to-Equity', 'Smart contracts automatically convert rental payments into ownership stakes.')}
                        ${missionFeature('globe', 'text-amber-400', 'Global Liquidity', 'Connect international impact investors with local housing needs.')}
                    </div>
                </div>
                <div class="relative mission-visual">
                    <div class="aspect-square rounded-3xl overflow-hidden glass p-2">
                        <div class="w-full h-full rounded-2xl bg-gradient-to-br from-indigo-900/50 to-purple-900/50 flex items-center justify-center relative overflow-hidden">
                            <div class="absolute inset-0 grid-pattern opacity-50"></div>
                            <div class="relative z-10 text-center space-y-4">
                                <div class="w-32 h-32 mx-auto rounded-full bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center glow">
                                    <i data-lucide="home" class="w-16 h-16 text-white"></i>
                                </div>
                                <div class="text-3xl font-bold">Spatial Justice</div>
                                <div class="text-gray-400">Powered by zkSync Era</div>
                            </div>
                        </div>
                    </div>
                    <div class="absolute -top-4 -right-4 w-24 h-24 rounded-full border-2 border-indigo-500/30 animate-spin" style="animation-duration:10s;"></div>
                    <div class="absolute -bottom-4 -left-4 w-32 h-32 rounded-full border-2 border-pink-500/30 animate-spin" style="animation-duration:15s;animation-direction:reverse;"></div>
                </div>
            </div>
        </div>
    </section>`;
}

function missionFeature(icon, colorClass, title, desc) {
    return `
    <div class="flex items-start space-x-4">
        <div class="w-12 h-12 rounded-xl feature-icon flex items-center justify-center flex-shrink-0">
            <i data-lucide="${icon}" class="w-6 h-6 ${colorClass}"></i>
        </div>
        <div>
            <h3 class="text-lg font-semibold mb-1">${title}</h3>
            <p class="text-gray-400 text-sm">${desc}</p>
        </div>
    </div>`;
}
