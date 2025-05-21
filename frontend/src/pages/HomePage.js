import React, { useState } from 'react';
import { ethers } from 'ethers';
import { useNavigate } from 'react-router-dom';

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
            navigate('/profile')
          } else{
            setError('Please Connect your Wallet First.')
          }
    }
    


    return (
        <>
        <div className="homepage" >
            <div className="header">
                <button className="button-connectWallet" onClick={handleWalletConnect}>
                    {isConnected? "WalletConnected" : "Connect Wallet" }</button>
            </div>
            <div className="content">
        {isError && <p style={{color: 'red'}}>{isError}</p>}
        {isConnected && account &&(
            <p>Connected Account : {account}</p>
        )}
        <button
                    className="btn-upload"
                   
                    onClick={handleGetStarted}
                  >
                    Get Started!
                  </button>
            </div>
        </div>

        </>
    )

};


export default HomePage;