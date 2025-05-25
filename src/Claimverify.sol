//SPDX license Identifier-MIT

pragma solidity ^0.8.0;

import "../Wormhole/lib/wormhole-solidity-sdk/src/interfaces/IWormhole.sol";//contracts/interfaces/IWormhole.so;
import "../Wormhole/lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";
import "./inteface/IPolicyManager.sol";

contract ClaimVerify{
     IWormhole public wormhole;
     IPolicyManager public policyManager;
     IWormholeRelayer public wormholeRelayer;

      uint16 public targetChainId;
    address public targetRiskPoolAddress;
    uint256 private constant GAS_LIMIT = 300000;

     //mapping to track the claims


     mapping(uint256 => bool) public claimProcessed;

     event ClaimInitiated(uint256 indexed policyId, address indexed user, uint8 productType);
    event ClaimVerified(uint256 indexed policyId, address indexed user, uint256 amount);
    
   
    event MessageSent(uint256 indexed policyId, uint16 targetChain, bytes32 sequence);
   
    event ThresholdUpdated(uint8 productType, address priceFeed, int256 threshold);

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
    }
    
       
    

    function receiveMessage(bytes memory payload) external {
        // Decode the payload
        (uint256 policyId, address userAddress, uint256 premium) = abi.decode(payload, (uint256, address, uint256));

      
  
    
    // Log the received message
    emit MessageReceived(string(abi.encodePacked("Processed claim for policy: ", policyId)));

    claimInitiated(policyId);
    }

    function claimInitiated(uint256 policyId) public {
        require(!claimProcessed[policyId], "claim already proceessed");
        IPolicyManager.Policy memory policy = policyManager.getPolicy(policyId);

        // thing that necessary
         require(policy.user_address == msg.sender, "Only policy holder can claim");
        require(policy.status_policy == IPolicyManager.Status.active, "Policy not active");
        require(block.timestamp <= policy.expiryTime, "Policy has expired");
        
         processClaim(policyId);

    }
    function processClaim(uint256 policyId) 
        private 
    {
        require(!claimProcessed[policyId], "Claim already processed");
        
        IPolicyManager.Policy memory policy = policyManager.getPolicy(policyId);
        claimProcessed[policyId] = true;
        
        // Calculate payout amount (could be full coverage or a portion)
        uint256 payoutAmount = policy.premium * 3; // Example: 5x premium as payout
        
        // Emit event for claim verification
        emit ClaimVerified(policyId, policy.user_address, payoutAmount);
        
        // Send cross-chain message via Wormhole
        sendMessage(policyId, policy.user_address, payoutAmount);
    }

    function quoteCrossChainCost(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }
    function sendMessage( uint256 policyId,
        address recipient,
        uint256 amount) private {
        uint256 cost = quoteCrossChainCost(targetChainId); // Dynamically calculate the cross-chain cost
        //require(msg.value >= cost, "Insufficient funds for cross-chain delivery");

        uint64 sequence = wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChainId,
            targetRiskPoolAddress,
            abi.encode(  policyId, recipient, amount ), 
            0, // No receiver value needed
            GAS_LIMIT // Gas limit for the transaction
        );

        emit MessageSent(policyId, targetChainId, bytes32(abi.encodePacked(sequence)));

        
    }

    event MessageReceived(string message);

    
    
}


// first mssg recieve => claim is initaited and claim is status is updated and is stored 