import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';
import '../styles/HomePage.css'; // Import the CSS (we'll create this next)

function HomePage(){
    const [isConnected, setIsConnected] = useState(false);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [address, setAddress] = useState(null);
    const [isLoading, setLoading] = useState(false);
    const [isError, setError] = useState();
    const [account, setAccount] = useState(null);
    const [isAddressSent, setIsAddressSent] = useState(false);
    const navigate = useNavigate();
    
    const sendingAddress = async(address, navigate, setIsAddressSent) => {
        // this is for sending data to the backend
    }
    
    const handleWalletConnect = async () => {
        try {
            if(window.ethereum) {
                setLoading(true);
                // Request account access using ethers v6 syntax
                const provider = new ethers.BrowserProvider(window.ethereum);
                const accounts = await provider.send('eth_requestAccounts', []);
                
                if (accounts.length > 0) {
                    const userAddress = accounts[0];
                    
                    // Store address in state and localStorage
                    setAddress(userAddress);
                    setAccount(userAddress);
                    setIsConnected(true);
                    localStorage.setItem('userAddress', userAddress);
                    
                    // Setup listeners for account changes
                    window.ethereum.on('accountsChanged', (accounts) => {
                        if (accounts.length === 0) {
                            // User disconnected their wallet
                            localStorage.removeItem('userAddress');
                            setIsConnected(false);
                            setAddress(null);
                            setAccount(null);
                        } else {
                            // User switched accounts
                            const newAddress = accounts[0];
                            setAddress(newAddress);
                            setAccount(newAddress);
                            localStorage.setItem('userAddress', newAddress);
                        }
                    });
                }
            } else {
                setError('Please install MetaMask to connect your wallet');
            }
        } catch (err) {
            setError('Failed to connect wallet: ' + err.message);
        } finally {
            setLoading(false);
        }
    };

    const handleGetStarted = async () => {
        if (isConnected) {
            navigate('/userprofile');
        } else {
            setError('Please Connect your Wallet First.');
        }
    };
    
    return (
        <>
        <div className="homepage">
            <div className="header">
                <button 
                    className="button-connectWallet" 
                    onClick={handleWalletConnect}
                    disabled={isLoading}
                >
                    {isLoading ? "Connecting..." : isConnected ? "Wallet Connected" : "Connect Wallet"}
                </button>
            </div>
            <div className="content">
                {isError && <p className="error-message">{isError}</p>}
                {isConnected && account && (
                    <p className="account-info">Connected Account: {account}</p>
                )}
                <div className="center-content">
                    <h1>Cross-Chain DeFi Insurance</h1>
                    <p>Secure your assets across multiple blockchains</p>
                    <button
                        className="btn-get-started"
                        onClick={handleGetStarted}
                        disabled={!isConnected}
                    >
                        Get Started!
                    </button>
                </div>
            </div>
        </div>
        </>
    );
}

export default HomePage;