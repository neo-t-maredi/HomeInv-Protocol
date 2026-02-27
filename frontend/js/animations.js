// ── GSAP Animations ──────────────────────────────────────────────
// Attaches to window — loaded before app.js

function initAnimations() {
    gsap.registerPlugin(ScrollTrigger);

    // Hero
    gsap.from('.hero-content > *', {
        y: 50, opacity: 0, duration: 1, stagger: 0.2, ease: 'power3.out'
    });

    // Mission
    gsap.from('.mission-content', {
        scrollTrigger: { trigger: '#mission', start: 'top 80%', toggleActions: 'play none none reverse' },
        x: -50, opacity: 0, duration: 1, ease: 'power3.out'
    });
    gsap.from('.mission-visual', {
        scrollTrigger: { trigger: '#mission', start: 'top 80%', toggleActions: 'play none none reverse' },
        x: 50, opacity: 0, duration: 1, ease: 'power3.out'
    });

    // Counters
    document.querySelectorAll('.counter').forEach(function(counter) {
        var target    = parseFloat(counter.getAttribute('data-target'));
        var isDecimal = target % 1 !== 0;
        gsap.to(counter, {
            scrollTrigger: { trigger: counter, start: 'top 85%', toggleActions: 'play none none reverse' },
            innerHTML: target,
            duration: 2,
            snap: { innerHTML: isDecimal ? 0.1 : 1 },
            ease: 'power2.out',
            onUpdate: function() {
                counter.innerHTML = isDecimal
                    ? parseFloat(counter.innerHTML).toFixed(1)
                    : Math.ceil(counter.innerHTML).toLocaleString();
            }
        });
    });

    // How it works
    gsap.from('#how-it-works .group', {
        scrollTrigger: { trigger: '#how-it-works', start: 'top 75%', toggleActions: 'play none none reverse' },
        y: 100, opacity: 0, duration: 0.8, stagger: 0.2, ease: 'power3.out'
    });

    // Technology
    gsap.from('#technology .glass', {
        scrollTrigger: { trigger: '#technology', start: 'top 75%', toggleActions: 'play none none reverse' },
        scale: 0.8, opacity: 0, duration: 0.6, stagger: 0.1, ease: 'back.out(1.7)'
    });

    // Navbar scroll
    var navbar = document.getElementById('navbar');
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 100) {
            navbar.classList.add('shadow-lg');
            navbar.style.background = 'rgba(2, 6, 23, 0.95)';
        } else {
            navbar.classList.remove('shadow-lg');
            navbar.style.background = 'rgba(15, 23, 42, 0.8)';
        }
    });

    // Orb parallax
    document.addEventListener('mousemove', function(e) {
        var orbs = document.querySelectorAll('.orb');
        var x = e.clientX / window.innerWidth;
        var y = e.clientY / window.innerHeight;
        orbs.forEach(function(orb, i) {
            var speed = (i + 1) * 20;
            orb.style.transform = 'translate(' + (0.5 - x) * speed + 'px, ' + (0.5 - y) * speed + 'px)';
        });
    });
}
