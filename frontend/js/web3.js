// ── HomeInv Web3 Integration ─────────────────────────────────────
// Plain global object — no import/export

var HomeInvWeb3 = {

    // ── Config ────────────────────────────────────────────────────
    NETWORK: {
        chainId:  '0x270F',   // 9991
        name:     'HomeInv-evm',
        rpcUrl:   'https://virtual.mainnet.eu.rpc.tenderly.co/7a064ab8-46f5-4651-9538-83ca2f6919f7',
        currency: 'ETH',
    },

    ADDRESSES: {
        jurisdictionRegistry: '0x37a3a1b31bbaee86e8e307240bfb4d1e7f227a57',
        hinvToken:            '0x472fe102833fab6d06d8391fbe2a544aa10257cf',
        identityRegistry:     '0x1d53f45a37eb832e8c1e951dd1ca03355ed40064',
        rentVault:            '0xbca59c8d90b4e2b46db4436e406f88311e77a7df',
        equityVault:          '0x8b80ac4a1ed9fcc1800fac045a84fd654909b6db',
        communityOracle:      '0xee53d75b4c890d1e11ab84987bd83edcf8e967cc',
        reitFactory:          '0x320a6aa54352cf573cf177439ce13b5372572889',
    },

    // Minimal ABIs — only functions we call from the frontend
    ABIS: {
        identityRegistry: [
            'function isVerified(address _account) external view returns (bool)',
            'function meetsKYCTier(address _account, uint8 _requiredTier) external view returns (bool)',
        ],
        reitFactory: [
            'function propertyCount() external view returns (uint256)',
        ],
        rentVault: [
            'function pendingYield(address _token, address _account) external view returns (uint256)',
        ],
        hinvToken: [
            'function balanceOf(address account) external view returns (uint256)',
            'function symbol() external view returns (string)',
        ],
    },

    // ── State ─────────────────────────────────────────────────────
    provider:  null,
    signer:    null,
    connected: false,
    address:   null,

    // ── Network ───────────────────────────────────────────────────
    switchNetwork: async function() {
        try {
            await window.ethereum.request({
                method: 'wallet_switchEthereumChain',
                params: [{ chainId: this.NETWORK.chainId }],
            });
        } catch (err) {
            if (err.code === 4902) {
                await window.ethereum.request({
                    method: 'wallet_addEthereumChain',
                    params: [{
                        chainId:           this.NETWORK.chainId,
                        chainName:         this.NETWORK.name,
                        nativeCurrency:    { name: 'ETH', symbol: 'ETH', decimals: 18 },
                        rpcUrls:           [this.NETWORK.rpcUrl],
                        blockExplorerUrls: [],
                    }],
                });
            } else {
                throw err;
            }
        }
    },

    // ── Connect ───────────────────────────────────────────────────
    connect: async function() {
        if (!window.ethereum) throw new Error('No wallet detected. Install MetaMask.');
        await this.switchNetwork();
        this.provider = new ethers.providers.Web3Provider(window.ethereum);
        await this.provider.send('eth_requestAccounts', []);
        this.signer   = this.provider.getSigner();
        this.address  = await this.signer.getAddress();
        var balance   = await this.provider.getBalance(this.address);
        this.connected = true;
        return {
            address: this.address,
            balance: ethers.utils.formatEther(balance),
        };
    },

    // ── Disconnect ────────────────────────────────────────────────
    disconnect: function() {
        this.provider  = null;
        this.signer    = null;
        this.address   = null;
        this.connected = false;
    },

    // ── Contract helpers ──────────────────────────────────────────
    getContract: function(name) {
        if (!this.provider) throw new Error('Not connected');
        return new ethers.Contract(
            this.ADDRESSES[name],
            this.ABIS[name],
            this.signer || this.provider
        );
    },

    isVerified: async function(address) {
        var c = this.getContract('identityRegistry');
        return c.isVerified(address);
    },

    getPropertyCount: async function() {
        var c = this.getContract('reitFactory');
        var n = await c.propertyCount();
        return n.toNumber();
    },

    getHINVBalance: async function(address) {
        var c = this.getContract('hinvToken');
        var b = await c.balanceOf(address);
        return ethers.utils.formatEther(b);
    },
};
