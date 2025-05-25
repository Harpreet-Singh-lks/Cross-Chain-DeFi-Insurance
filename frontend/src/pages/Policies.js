import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import '../styles/Policies.css';
import { useNavigate } from 'react-router-dom';
import ABI from '../contracts/policyManagerABI';
import contractConfig from '../contracts/contractConfig';

function Policies() {
    const [policies, setPolicies] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);
    const [assetAddress, setAssetAddress] = useState('');
    const [showAssetModal, setShowAssetModal] = useState(false);
    const [selectedPolicyId, setSelectedPolicyId] = useState(null);
    const navigate = useNavigate();
    const CONTRACT_ADDRESS = contractConfig.policyManagerAddress;

    useEffect(() => {
        fetchAvailablePolicies();
    }, []);

    const fetchAvailablePolicies = async () => {
        setLoading(true);
        try {
            console.log("Fetching available policies...");
            
            // Format the policies data to match your contract's enum values
            const formattedPolicies = [
                {
                    id: 1,
                    productType: "SMART_CONTRACT",
                    productTypeValue: 0,  // Maps to enum ProductType.SmartContractRisk
                    name: "Smart Contract Coverage",
                    description: "Insurance against smart contract vulnerabilities and exploits",
                    coverage: "Up to 50 ETH equivalent",
                    premium: "0.1 ETH", 
                    riskLevel: "High",
                    requiresAsset: true
                },
                {
                    id: 2,
                    productType: "RWA",
                    productTypeValue: 1,  // Maps to enum ProductType.RWA
                    name: "Real World Asset Coverage",
                    description: "Protection for tokenized real world assets",
                    coverage: "Up to 100,000 USDC equivalent",
                    premium: "0.05 ETH",
                    riskLevel: "Medium",
                    requiresAsset: true
                },
                {
                    id: 3,
                    productType: "DEPIN", 
                    productTypeValue: 2,  // Maps to enum ProductType.DePIN
                    name: "DePIN Coverage",
                    description: "Insurance for decentralized physical infrastructure",
                    coverage: "Up to asset value",
                    premium: "0.02 ETH",
                    riskLevel: "Low",
                    requiresAsset: true
                }
            ];
            
            console.log("Setting policies:", formattedPolicies);
            setPolicies(formattedPolicies);
            setError(null);
        } catch (err) {
            console.error("Error fetching policies:", err);
            setError("Failed to load available policies. Please try again.");
        } finally {
            setLoading(false);
        }
    };

    const handlePolicySelect = (policyId) => {
        const selectedPolicy = policies.find(policy => policy.id === policyId);
        
        if (selectedPolicy.requiresAsset) {
            // If the policy requires asset address, show modal
            setSelectedPolicyId(policyId);
            setShowAssetModal(true);
        } else {
            // Otherwise proceed with purchase directly
            handlePurchase(policyId, null);
        }
    };

    const handleAssetAddressSubmit = () => {
        // Validate asset address
        if (!ethers.isAddress(assetAddress)) {
            alert("Please enter a valid Ethereum address");
            return;
        }
        
        // Proceed with purchase using the asset address
        handlePurchase(selectedPolicyId, assetAddress);
        setShowAssetModal(false);
    };

    const handlePurchase = async (policyId, assetAddr = null) => {
        try {
            if (!assetAddr) {
                alert("Asset address is required");
                return;
            }
            
            console.log("Starting purchase process...");
            
            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            
            console.log("Contract address:", CONTRACT_ADDRESS);
            console.log("ABI:", ABI);
            
            // Create contract instance
            const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
            
            const selectedPolicy = policies.find(policy => policy.id === policyId);
            
            // Use the productTypeValue directly (this matches the enum in the contract)
            const productTypeValue = selectedPolicy.productTypeValue;
            
            console.log(`Converting premium: ${selectedPolicy.premium}`);
            // Convert premium to wei
            const premiumStr = selectedPolicy.premium.split(" ")[0];
            const premium = ethers.parseEther(premiumStr);
            
            console.log(`About to call contract with: asset=${assetAddr}, productType=${productTypeValue}, premium=${premium.toString()}`);
            
            // Call BuyPolicy function with correct parameters
            const tx = await contract.BuyPolicy(
                assetAddr,             // asset address
                productTypeValue,      // product type as uint8
                { value: premium }     // premium as value
            );
            
            console.log("Transaction submitted:", tx.hash);
            
            // Wait for transaction confirmation
            const receipt = await tx.wait();
            console.log("Transaction confirmed:", receipt);
            
            alert(`Successfully purchased ${selectedPolicy.name}!`);
            navigate('/userprofile');
        } catch (err) {
            console.error("Error purchasing policy:", err);
            console.error("Error details:", err.message);
            alert(`Failed to purchase policy: ${err.message}`);
        }
    };

    return(
        <div className="policies-container">
            <h1>Available Insurance Policies</h1>
            <p className="policies-subtitle">Select a Policy to protect your assets</p>

            {loading ? (
                <div className="loading-container">
                    <p>Loading the policies...</p>
                </div>
            ): error ? (
                <div className="error-container">
                    <p>{error}</p>
                    <button onClick={fetchAvailablePolicies}>Try Again</button>
                </div>
            ) : (
                <div className="policies-grid">
                    {policies.map(policy => (
                        <div className="policy-card" key={policy.id}>
                            <div className={`risk-badge ${policy.riskLevel.toLowerCase()}`}>
                                {policy.riskLevel} Risk
                            </div>
                            <h2>{policy.name}</h2>
                            <p className="policy-description">{policy.description}</p>
                            
                            <div className="policy-details">
                                <div className="detail-item">
                                    <span className="detail-label">Coverage:</span>
                                    <span className="detail-value">{policy.coverage}</span>
                                </div>
                                <div className="detail-item">
                                    <span className="detail-label">Premium:</span>
                                    <span className="detail-value">{policy.premium}</span>
                                </div>
                            </div>
                            
                            <div className="chains-container">
                                <p className="chains-label">Supported Chains: Only EVM based Chains</p>
                            </div>
                            
                            <button 
                                className="purchase-button"
                                onClick={() => handlePolicySelect(policy.id)}
                            >
                                Purchase Policy
                            </button>
                        </div>
                    ))}
                </div>
            )}
            
            {/* Asset Address Modal */}
            {showAssetModal && (
                <div className="modal-overlay">
                    <div className="modal-container">
                        <h2>Enter Asset Address</h2>
                        <p>Please provide the contract address of the asset you want to insure:</p>
                        
                        <input 
                            type="text"
                            placeholder="0x..."
                            value={assetAddress}
                            onChange={(e) => setAssetAddress(e.target.value)}
                            className="asset-address-input"
                        />
                        
                        <div className="modal-buttons">
                            <button 
                                className="cancel-button"
                                onClick={() => setShowAssetModal(false)}
                            >
                                Cancel
                            </button>
                            <button 
                                className="confirm-button"
                                onClick={handleAssetAddressSubmit}
                            >
                                Confirm
                            </button>
                        </div>
                    </div>
                </div>
            )}
            
            <div className="actions">
                <button className="back-button" onClick={() => navigate('/userprofile')}>
                    Back to Dashboard
                </button>
            </div>
        </div>
    );
}

export default Policies;