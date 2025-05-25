const contractConfig = {
    // From your deployment output
    policyManagerAddress: '0x841babec1b083ff6d8452242b6d477ab25d6792a',
    
    // Network information
    networks: {
        fuji: {
            chainId: '0xa869', // 43113 in decimal
            chainName: 'Avalanche Fuji Testnet',
            rpcUrl: 'https://api.avax-test.network/ext/bc/C/rpc',
            blockExplorerUrl: 'https://testnet.snowtrace.io'
        },
        alfajores: {
            chainId: '0xaef3', // 44787 in decimal
            chainName: 'Celo Alfajores Testnet',
            rpcUrl: 'https://alfajores-forno.celo-testnet.org',
            blockExplorerUrl: 'https://alfajores.celoscan.io'
        }
    }
};

export default contractConfig;