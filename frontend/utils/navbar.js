export function renderNavbar() {
    return `
    <nav class="fixed w-full z-50 glass-strong transition-all duration-300" id="navbar">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex justify-between items-center h-20">
                <div class="flex items-center space-x-2">
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-500 to-purple-600 flex items-center justify-center">
                        <i data-lucide="home" class="w-6 h-6 text-white"></i>
                    </div>
                    <span class="text-2xl font-bold tracking-tight">HomeInv</span>
                </div>
                <div class="hidden md:flex items-center space-x-8">
                    <a href="#mission" class="nav-link text-sm font-medium text-gray-300 hover:text-white transition-colors">Mission</a>
                    <a href="#how-it-works" class="nav-link text-sm font-medium text-gray-300 hover:text-white transition-colors">How it Works</a>
                    <a href="#technology" class="nav-link text-sm font-medium text-gray-300 hover:text-white transition-colors">Technology</a>
                    <a href="#impact" class="nav-link text-sm font-medium text-gray-300 hover:text-white transition-colors">Impact</a>
                </div>
                <div class="flex items-center space-x-4">
                    <button class="hidden md:block text-sm font-medium text-gray-300 hover:text-white transition-colors">Docs</button>
                    <button class="btn-primary px-6 py-2.5 rounded-full text-sm font-semibold text-white">Launch App</button>
                </div>
            </div>
        </div>
    </nav>`;
}

export function initNavbarScroll() {
    const navbar = document.getElementById('navbar');
    window.addEventListener('scroll', () => {
        if (window.pageYOffset > 100) {
            navbar.classList.add('shadow-lg');
            navbar.style.background = 'rgba(2,6,23,0.95)';
        } else {
            navbar.classList.remove('shadow-lg');
            navbar.style.background = 'rgba(15,23,42,0.8)';
        }
    });
}
