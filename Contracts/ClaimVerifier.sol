// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./interfaces/IPolicyManager.sol";
import "./interfaces/IWormholeRelayer.sol";

/**
 * @title ClaimVerifier
 * @dev Verifies insurance claims based on predefined conditions and triggers cross-chain payouts
 * using Wormhole's General Message Passing (GMP) protocol.
 */
contract ClaimVerifier is Ownable, Pausable {
    // Interfaces to communicate with other contracts
    IPolicyManager public policyManager;
    IWormholeRelayer public wormholeRelayer;

    // Wormhole chain IDs for cross-chain communication
    uint16 public targetChainId;
    address public targetRiskPoolAddress;
    
    // Mapping of policy types to verification strategies
    enum VerificationStrategy { PriceFeed, Oracle, Hybrid }
    mapping(uint8 => VerificationStrategy) public verificationStrategies;
    
    // Parameters for different verification types
    struct PriceThreshold {
        address priceFeed;        // Chainlink price feed address
        int256 threshold;         // Price threshold (can be upper or lower)
        bool isUpperBound;        // If true, trigger when price > threshold, else when price < threshold
        uint256 timeWindow;       // Time window to observe (in seconds)
    }
    
    struct OracleThreshold {
        address[] oracles;        // List of oracle addresses
        uint256 requiredVotes;    // Minimum votes required to confirm a claim
        uint256 validityPeriod;   // How long oracle votes are valid (in seconds)
    }
    
    // Store thresholds for different product types
    mapping(uint8 => PriceThreshold) public priceThresholds;
    mapping(uint8 => OracleThreshold) public oracleThresholds;
    
    // Mapping to track claim status
    mapping(uint256 => bool) public claimProcessed;
    mapping(uint256 => uint256) public claimTimestamps;
    
    // Oracle voting tracking
    mapping(uint256 => mapping(address => bool)) public oracleVotes;
    mapping(uint256 => uint256) public oracleVoteCounts;
    
    // Gas limit for cross-chain messages
    uint256 public gasLimit = 300000;
    
    // Events
    event ClaimInitiated(uint256 indexed policyId, address indexed user, uint8 productType);
    event ClaimVerified(uint256 indexed policyId, address indexed user, uint256 amount);
    event ClaimRejected(uint256 indexed policyId, address indexed user, string reason);
    event OracleVoteSubmitted(uint256 indexed policyId, address indexed oracle, bool vote);
    event CrossChainMessageSent(uint256 indexed policyId, uint16 targetChain, bytes32 sequence);
    event VerificationStrategyUpdated(uint8 productType, VerificationStrategy strategy);
    event ThresholdUpdated(uint8 productType, address priceFeed, int256 threshold);
    
    /**
     * @dev Constructor to initialize the ClaimVerifier contract
     * @param _policyManagerAddress Address of the PolicyManager contract
     * @param _wormholeRelayerAddress Address of the WormholeRelayer contract
     * @param _targetChainId Wormhole chain ID of the target chain for payouts
     * @param _targetRiskPoolAddress Address of the RiskPool contract on the target chain
     */
    constructor(
        address _policyManagerAddress,
        address _wormholeRelayerAddress,
        uint16 _targetChainId,
        address _targetRiskPoolAddress
    ) {
        policyManager = IPolicyManager(_policyManagerAddress);
        wormholeRelayer = IWormholeRelayer(_wormholeRelayerAddress);
        targetChainId = _targetChainId;
        targetRiskPoolAddress = _targetRiskPoolAddress;
        
        // Set default verification strategies
        verificationStrategies[uint8(IPolicyManager.ProductType.SmartContractRisk)] = VerificationStrategy.PriceFeed;
        verificationStrategies[uint8(IPolicyManager.ProductType.RWA)] = VerificationStrategy.Oracle;
        verificationStrategies[uint8(IPolicyManager.ProductType.DePIN)] = VerificationStrategy.Hybrid;
    }
    
    /**
     * @dev Function to pause claim verification in case of emergency
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Function to unpause claim verification
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Updates the verification strategy for a product type
     * @param productType Product type enum value
     * @param strategy New verification strategy
     */
    function setVerificationStrategy(uint8 productType, VerificationStrategy strategy) 
        external 
        onlyOwner 
    {
        verificationStrategies[productType] = strategy;
        emit VerificationStrategyUpdated(productType, strategy);
    }
    
    /**
     * @dev Sets a price threshold for a specific product type
     * @param productType Product type to set threshold for
     * @param priceFeed Address of Chainlink price feed
     * @param threshold Price threshold value
     * @param isUpperBound Whether threshold is an upper bound
     * @param timeWindow Time window for observation
     */
    function setPriceThreshold(
        uint8 productType, 
        address priceFeed, 
        int256 threshold, 
        bool isUpperBound,
        uint256 timeWindow
    ) 
        external 
        onlyOwner 
    {
        priceThresholds[productType] = PriceThreshold({
            priceFeed: priceFeed,
            threshold: threshold,
            isUpperBound: isUpperBound,
            timeWindow: timeWindow
        });
        
        emit ThresholdUpdated(productType, priceFeed, threshold);
    }
    
    /**
     * @dev Sets oracle thresholds for a specific product type
     * @param productType Product type to set oracles for
     * @param oracles Array of oracle addresses
     * @param requiredVotes Minimum required votes to approve a claim
     * @param validityPeriod How long oracle votes remain valid
     */
    function setOracleThreshold(
        uint8 productType,
        address[] calldata oracles,
        uint256 requiredVotes,
        uint256 validityPeriod
    ) 
        external 
        onlyOwner 
    {
        require(requiredVotes <= oracles.length, "Required votes exceeds oracle count");
        
        oracleThresholds[productType] = OracleThreshold({
            oracles: oracles,
            requiredVotes: requiredVotes,
            validityPeriod: validityPeriod
        });
    }
    
    /**
     * @dev Update Wormhole target chain and address
     * @param _targetChainId New target chain ID
     * @param _targetRiskPoolAddress New target risk pool address
     */
    function updateCrossChainTarget(uint16 _targetChainId, address _targetRiskPoolAddress) 
        external 
        onlyOwner 
    {
        targetChainId = _targetChainId;
        targetRiskPoolAddress = _targetRiskPoolAddress;
    }
    
    /**
     * @dev Set gas limit for cross-chain messages
     * @param _gasLimit New gas limit
     */
    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }
    
    /**
     * @dev Initiates a claim for a given policy
     * @param policyId ID of the policy to claim
     */
    function initiateClaim(uint256 policyId) 
        external 
        whenNotPaused 
    {
        require(!claimProcessed[policyId], "Claim already processed");
        
        // Get policy details from PolicyManager
        IPolicyManager.Policy memory policy = policyManager.getPolicy(policyId);
        
        require(policy.user_address == msg.sender, "Only policy holder can claim");
        require(policy.status_policy == IPolicyManager.Status.active, "Policy not active");
        require(block.timestamp <= policy.expiryTime, "Policy has expired");
        
        // Record claim initiation time
        claimTimestamps[policyId] = block.timestamp;
        
        // Start verification process based on product type and strategy
        VerificationStrategy strategy = verificationStrategies[uint8(policy.productType)];
        
        if (strategy == VerificationStrategy.PriceFeed) {
            bool verified = verifyPriceFeedCondition(policyId, uint8(policy.productType));
            if (verified) {
                processClaim(policyId);
            } else {
                emit ClaimRejected(policyId, policy.user_address, "Price condition not met");
            }
        } else if (strategy == VerificationStrategy.Oracle) {
            // For oracle verification, we just initiate and wait for oracle votes
            emit ClaimInitiated(policyId, policy.user_address, uint8(policy.productType));
        } else if (strategy == VerificationStrategy.Hybrid) {
            // For hybrid, we check price feed first, then wait for oracle confirmation
            bool priceConditionMet = verifyPriceFeedCondition(policyId, uint8(policy.productType));
            if (priceConditionMet) {
                emit ClaimInitiated(policyId, policy.user_address, uint8(policy.productType));
            } else {
                emit ClaimRejected(policyId, policy.user_address, "Price condition not met for hybrid verification");
            }
        }
    }
    
    /**
     * @dev Submit an oracle vote for a claim
     * @param policyId ID of the policy
     * @param vote True if claim is valid, false otherwise
     */
    function submitOracleVote(uint256 policyId, bool vote) 
        external 
        whenNotPaused 
    {
        IPolicyManager.Policy memory policy = policyManager.getPolicy(policyId);
        uint8 productType = uint8(policy.productType);
        
        // Check if the sender is authorized oracle
        bool isOracle = false;
        for (uint i = 0; i < oracleThresholds[productType].oracles.length; i++) {
            if (oracleThresholds[productType].oracles[i] == msg.sender) {
                isOracle = true;
                break;
            }
        }
        require(isOracle, "Not an authorized oracle");
        
        // Check if vote is still valid
        require(
            block.timestamp <= claimTimestamps[policyId] + oracleThresholds[productType].validityPeriod,
            "Voting period expired"
        );
        
        // Record vote if not already voted
        require(!oracleVotes[policyId][msg.sender], "Oracle already voted");
        oracleVotes[policyId][msg.sender] = true;
        
        if (vote) {
            oracleVoteCounts[policyId]++;
        }
        
        emit OracleVoteSubmitted(policyId, msg.sender, vote);
        
        // If enough votes, process the claim
        if (oracleVoteCounts[policyId] >= oracleThresholds[productType].requiredVotes) {
            processClaim(policyId);
        }
    }
    
    /**
     * @dev Process a verified claim and send cross-chain message
     * @param policyId ID of the policy to process
     */
    function processClaim(uint256 policyId) 
        private 
    {
        require(!claimProcessed[policyId], "Claim already processed");
        
        IPolicyManager.Policy memory policy = policyManager.getPolicy(policyId);
        claimProcessed[policyId] = true;
        
        // Calculate payout amount (could be full coverage or a portion)
        uint256 payoutAmount = policy.premium * 10; // Example: 10x premium as payout
        
        // Emit event for claim verification
        emit ClaimVerified(policyId, policy.user_address, payoutAmount);
        
        // Send cross-chain message via Wormhole
        sendCrossChainMessage(policyId, policy.user_address, payoutAmount);
    }
    
    /**
     * @dev Verify claim using price feed data
     * @param policyId ID of the policy
     * @param productType Type of the product
     * @return Whether claim conditions are met
     */
    function verifyPriceFeedCondition(uint256 policyId, uint8 productType) 
        private 
        view 
        returns (bool) 
    {
        PriceThreshold memory threshold = priceThresholds[productType];
        if (threshold.priceFeed == address(0)) {
            return false; // No price feed configured
        }
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(threshold.priceFeed);
        
        // Get latest price data
        (
            /* uint80 roundID */, 
            int256 price, 
            /* uint startedAt */, 
            uint256 timestamp, 
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();
        
        // Check if price data is fresh enough
        if (block.timestamp - timestamp > threshold.timeWindow) {
            return false; // Price data too old
        }
        
        // Check if price meets threshold condition
        if (threshold.isUpperBound) {
            return price > threshold.threshold;
        } else {
            return price < threshold.threshold;
        }
    }
    
    /**
     * @dev Send cross-chain message via Wormhole
     * @param policyId ID of the policy
     * @param recipient Address to receive the payout
     * @param amount Amount to pay out
     */
    function sendCrossChainMessage(
        uint256 policyId,
        address recipient,
        uint256 amount
    ) 
        private 
    {
        // Calculate the delivery price
        uint256 wormholeFee = wormholeRelayer.quoteEVMDeliveryPrice(
            targetChainId,
            0, // No payload delivery data
            gasLimit
        );
        
        // Pack message data
        bytes memory payload = abi.encode(
            policyId,       // Policy ID for tracking
            recipient,      // Who receives the payout
            amount          // How much to pay out
        );
        
        // Send the message via Wormhole
        bytes32 sequence = wormholeRelayer.sendPayloadToEvm{value: wormholeFee}(
            targetChainId,          // Destination chain (e.g., Ethereum)
            targetRiskPoolAddress,  // Destination contract address (RiskPool)
            payload,                // Encoded payload with claim details
            0,                      // No extra value being sent
            gasLimit                // Gas limit for execution on target chain
        );
        
        emit CrossChainMessageSent(policyId, targetChainId, sequence);
    }
    
    /**
     * @dev Allows the contract to receive ETH for Wormhole fees
     */
    receive() external payable {}
}

/**
 * @dev Interface for interaction with PolicyManager contract
 */
interface IPolicyManager {
    enum ProductType {SmartContractRisk, RWA, DePIN}
    enum Status {active, expired, Claimed}
    
    struct Policy {
        uint256 policy_ID;
        address asset_addrress;
        address user_address;
        ProductType productType;
        Status status_policy;
        uint256 startTime;
        uint256 expiryTime;
        uint256 premium;
    }
    
    function getPolicy(uint256 policyId) external view returns (Policy memory);
}

/**
 * @dev Interface for interaction with WormholeRelayer
 */
interface IWormholeRelayer {
    function quoteEVMDeliveryPrice(
        uint16 targetChain,
        uint256 valueToSend,
        uint256 gasLimit
    ) external view returns (uint256);
    
    function sendPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 valueToSend,
        uint256 gasLimit
    ) external payable returns (bytes32 sequence);
}