export function renderHero() {
    return `
    <section class="relative min-h-screen flex items-center justify-center overflow-hidden pt-20">
        <div class="absolute inset-0 grid-pattern opacity-30"></div>
        <div class="absolute top-20 left-10 w-72 h-72 bg-purple-500 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse orb"></div>
        <div class="absolute bottom-20 right-10 w-96 h-96 bg-indigo-500 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse orb" style="animation-delay:2s;"></div>

        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10 w-full">
            <div class="grid lg:grid-cols-2 gap-12 items-center">
                <div class="space-y-8 hero-content">
                    <div class="inline-flex items-center space-x-2 px-4 py-2 rounded-full glass border border-indigo-500/30">
                        <span class="w-2 h-2 rounded-full bg-green-400 animate-pulse"></span>
                        <span class="text-xs font-medium text-indigo-300">Live on zkSync Era</span>
                    </div>
                    <h1 class="text-5xl md:text-7xl font-bold leading-tight">
                        <span class="block">Decentralized</span>
                        <span class="block gradient-text">Real Estate</span>
                        <span class="block">for Everyone</span>
                    </h1>
                    <p class="text-xl text-gray-400 max-w-lg leading-relaxed">
                        Bridging global liquidity and local spatial justice. Transforming South African townships through blockchain-powered REITs and rent-to-equity smart contracts.
                    </p>
                    <div class="flex flex-wrap gap-4">
                        <button class="btn-primary px-8 py-4 rounded-full font-semibold text-white flex items-center space-x-2 group">
                            <span>Start Investing</span>
                            <i data-lucide="arrow-right" class="w-5 h-5 group-hover:translate-x-1 transition-transform"></i>
                        </button>
                        <button class="btn-secondary px-8 py-4 rounded-full font-semibold text-white flex items-center space-x-2">
                            <i data-lucide="play-circle" class="w-5 h-5"></i>
                            <span>Watch Demo</span>
                        </button>
                    </div>
                    <div class="flex items-center space-x-6 pt-4">
                        <div><div class="text-2xl font-bold">$2.4M</div><div class="text-sm text-gray-500">TVL Locked</div></div>
                        <div class="w-px h-12 bg-gray-800"></div>
                        <div><div class="text-2xl font-bold">847</div><div class="text-sm text-gray-500">Properties</div></div>
                        <div class="w-px h-12 bg-gray-800"></div>
                        <div><div class="text-2xl font-bold">12%</div><div class="text-sm text-gray-500">Avg APY</div></div>
                    </div>
                </div>

                <div class="relative h-[600px] w-full flex items-center justify-center">
                    <div id="canvas-container" class="w-full h-full"></div>
                    <div class="absolute top-10 right-10 glass px-4 py-3 rounded-2xl floating-card" style="animation-delay:0s;">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-full bg-green-500/20 flex items-center justify-center">
                                <i data-lucide="trending-up" class="w-5 h-5 text-green-400"></i>
                            </div>
                            <div><div class="text-xs text-gray-400">Property Value</div><div class="text-lg font-bold text-green-400">+24.5%</div></div>
                        </div>
                    </div>
                    <div class="absolute bottom-20 left-10 glass px-4 py-3 rounded-2xl floating-card" style="animation-delay:1s;">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-full bg-indigo-500/20 flex items-center justify-center">
                                <i data-lucide="shield-check" class="w-5 h-5 text-indigo-400"></i>
                            </div>
                            <div><div class="text-xs text-gray-400">Secured by</div><div class="text-sm font-bold text-white">zkSync Era</div></div>
                        </div>
                    </div>
                    <div class="absolute top-1/2 right-0 glass px-4 py-3 rounded-2xl floating-card" style="animation-delay:2s;">
                        <div class="flex items-center space-x-3">
                            <div class="w-10 h-10 rounded-full bg-pink-500/20 flex items-center justify-center">
                                <i data-lucide="users" class="w-5 h-5 text-pink-400"></i>
                            </div>
                            <div><div class="text-xs text-gray-400">Community</div><div class="text-sm font-bold text-white">2,420 Owners</div></div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div class="absolute bottom-8 left-1/2 transform -translate-x-1/2 animate-bounce">
            <i data-lucide="chevron-down" class="w-6 h-6 text-gray-500"></i>
        </div>
    </section>`;
}
