export function initAnimations(gsap, ScrollTrigger) {
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

    // Orb parallax
    document.addEventListener('mousemove', e => {
        const x = e.clientX / window.innerWidth;
        const y = e.clientY / window.innerHeight;
        document.querySelectorAll('.orb').forEach((orb, i) => {
            const speed = (i + 1) * 20;
            orb.style.transform = `translate(${(0.5 - x) * speed}px, ${(0.5 - y) * speed}px)`;
        });
    });
}
