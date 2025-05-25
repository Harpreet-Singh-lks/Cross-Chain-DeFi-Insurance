import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import "../styles/userprofile.css";




function Userprofile() {
    const navigate = useNavigate();
    const [userData, setUserData] = useState({
        address: localStorage.getItem('userAddress') || "Not connected",
        balance: "Loading...",
        policies: []
    });
    
    // Text rotation for marketing taglines
    const [currentTextIndex, setCurrentTextIndex] = useState(0);
    const marketingTexts = [
        "You're now insured by the chain. Let's protect your assets.",
        "Policies on-chain. Claims cross-chain. Peace of mind unlocked.",
        "Your digital assets deserve protection across blockchains.",
        "Decentralized protection for a decentralized world."
    ];

    // Text rotation effect
    useEffect(() => {
        const interval = setInterval(() => {
            setCurrentTextIndex((prevIndex) => 
                (prevIndex + 1) % marketingTexts.length
            );
        }, 4000); // Change text every 4 seconds
        
        return () => clearInterval(interval);
    }, []);

    // Check if user is connected (you might want to enhance this check)
    useEffect(() => {
        const userAddress = localStorage.getItem('userAddress');
        if (!userAddress) {
            // Redirect to homepage if not connected
            console.log("what the fuck");
           // setError("the user wallet is discconnected");
             navigate('/');
        } else {
            // Fetch user data from blockchain or API
            fetchUserData(userAddress);
        }
    }, [navigate]);

    const fetchUserData = async (address) => {
        // This is a placeholder - replace with actual blockchain calls
        try {
            // Simulate loading data
            setTimeout(() => {
                setUserData({
                    address: address,
                    balance: "0.5 ETH", // This would come from your blockchain query
                    policies: [
                        // Sample data - replace with actual data from your contract
                        { id: 1, type: "Smart Contract Risk", premium: "0.1 ETH", status: "Active" },
                        { id: 2, type: "RWA", premium: "0.05 ETH", status: "Active" }
                    ]
                });
            }, 1000);
        } catch (error) {
            console.error("Error fetching user data:", error);
        }
    };

    const handleBuyPolicy = () => {
        navigate('/policies');
    };

    const handleViewClaims = () => {
        navigate('/claims');
    };

    return (
        <div className="user-profile-container">
            
            <div className="user-profile-header">
                <div className="welcome-section">
                    <h1>Welcome to Your Insurance Dashboard</h1>
                    <div className="tagline-container">
                        <p className="tagline">{marketingTexts[currentTextIndex]}</p>
                    </div>
                </div>
                <div className="hero-image">
                    <img  alt="DeFi Insurance Protection" />
                </div>
            </div>
            
            <div className="user-profile-content">
                <div className="user-info-card">
                    <h2>Account Information</h2>
                    <div className="info-row">
                        <span className="info-label">Wallet Address:</span>
                        <span className="info-value">{userData.address}</span>
                    </div>
                    <div className="info-row">
                        <span className="info-label">Balance:</span>
                        <span className="info-value">{userData.balance}</span>
                    </div>
                </div>
                
                <div className="user-policies-card">
                    <h2>Your Active Policies</h2>
                    {userData.policies.length > 0 ? (
                        <div className="policies-table">
                            <div className="table-header">
                                <div className="table-cell">ID</div>
                                <div className="table-cell">Type</div>
                                <div className="table-cell">Premium</div>
                                <div className="table-cell">Status</div>
                            </div>
                            {userData.policies.map(policy => (
                                <div className="table-row" key={policy.id}>
                                    <div className="table-cell">{policy.id}</div>
                                    <div className="table-cell">{policy.type}</div>
                                    <div className="table-cell">{policy.premium}</div>
                                    <div className="table-cell">
                                        <span className={`status-badge ${policy.status.toLowerCase()}`}>
                                            {policy.status}
                                        </span>
                                    </div>
                                </div>
                            ))}
                        </div>
                    ) : (
                        <p className="no-policies">No active policies found. Buy your first policy now!</p>
                    )}
                </div>
                
                <div className="actions-container">
                    <button className="action-button buy-policy" onClick={handleBuyPolicy}>
                        Buy New Policy
                    </button>
                    <button className="action-button view-claims" onClick={handleViewClaims}>
                        View Claims
                    </button>
                </div>
            </div>
        </div>
    );
}

export default Userprofile;