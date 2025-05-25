import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';
import '../styles/HomePage.css'; // Import the CSS (we'll create this next)

function HomePage(){
    const [isConnected, setisConnected] = useState(false);
    const [ismodalOpen, setismodalOpen] = useState(false);
    const [Address, setAddress]= useState(null);
    const [isLoading, setLoading] = useState(false);
    const [isError, setError ]= useState();
    const [account, setAccount] = useState(null);
    const [isAddressSent, setIsAddressSent] = useState(false);
    const [isGetStartedDisabled, setGetStartedDisabled] = useState(true);
    const navigate = useNavigate();
    const sendingAddress = async(address, navigate, setIsAddressSent)=>{
// this is for sending data to the backend
    }
    
   // const []= useState();
    const handleWalletConnect = async () =>{
        if(!window.ethereum){
            setError('Metamask not detected. Please Install it.');
            return;
        }
        try{
            setLoading(true);
            const provider = new ethers.BrowserProvider(window.ethereum);
            const accounts = await provider.send('eth_requestAccounts', []);
            setAccount(accounts[0]);
            setisConnected(true);
            setError('');
            } catch (err) {
                setError('Failed to connect wallet: ' + err.message);
            } finally {
                  setLoading(false);
            }
        }

    const handleGetStarted =async ()=>{
        if (isConnected ) {
            navigate('/userprofile')
            
          } else{
            setError('Please Connect your Wallet First.')
          }
    }
    
    return (
        <>
        <div className="homepage">
            <div className="header">
                <button className="button-connectWallet" onClick={handleWalletConnect}>
                    {isConnected? "Wallet Connected" : "Connect Wallet" }</button>
            </div>
            <div className="content">
                {isError && <p className="error-message">{isError}</p>}
                {isConnected && account &&(
                    <p className="account-info">Connected Account: {account}</p>
                )}
                <div className="center-content">
                    <h1>Cross-Chain DeFi Insurance</h1>
                    <p>Secure your assets across multiple blockchains</p>
                    <button
                        className="btn-get-started"
                        onClick={handleGetStarted}
                    >
                        Get Started!
                    </button>
                </div>
            </div>
        </div>
        </>
    );
};

export default HomePage;