// ── App Bootstrap ────────────────────────────────────────────────
// Runs after all other scripts are loaded

document.addEventListener('DOMContentLoaded', function() {

    // Icons
    lucide.createIcons();

    // Three.js scene
    initScene();

    // GSAP animations
    initAnimations();

    // ── Wallet button ─────────────────────────────────────────────
    var btn   = document.getElementById('wallet-btn');
    var label = document.getElementById('wallet-label');

    btn.addEventListener('click', async function() {
        if (HomeInvWeb3.connected) {
            HomeInvWeb3.disconnect();
            label.textContent  = 'Connect Wallet';
            btn.style.background = '';
            btn.classList.add('btn-primary');
            return;
        }

        try {
            label.textContent = 'Connecting…';
            btn.disabled = true;

            var wallet = await HomeInvWeb3.connect();
            var short  = wallet.address.slice(0, 6) + '…' + wallet.address.slice(-4);

            label.textContent    = short;
            btn.style.background = 'linear-gradient(135deg, #10b981, #059669)';

            console.log('✅ Connected:', wallet.address);
            console.log('💰 Balance:', wallet.balance, 'ETH');

            // Example contract reads after connect
            try {
                var count = await HomeInvWeb3.getPropertyCount();
                console.log('🏠 Properties on-chain:', count);

                var verified = await HomeInvWeb3.isVerified(wallet.address);
                console.log('🔐 KYC verified:', verified);

                var hinvBal = await HomeInvWeb3.getHINVBalance(wallet.address);
                console.log('🪙 HINV Balance:', hinvBal);
            } catch (readErr) {
                console.warn('Contract read failed (expected if not KYC\'d):', readErr.message);
            }

        } catch (err) {
            label.textContent = 'Connect Wallet';
            console.error('Connection failed:', err.message);
            alert(err.message);
        } finally {
            btn.disabled = false;
        }
    });

    // Account change listener
    if (window.ethereum) {
        window.ethereum.on('accountsChanged', function() {
            if (HomeInvWeb3.connected) {
                HomeInvWeb3.disconnect();
                label.textContent    = 'Connect Wallet';
                btn.style.background = '';
            }
        });

        window.ethereum.on('chainChanged', function() {
            window.location.reload();
        });
    }
});
