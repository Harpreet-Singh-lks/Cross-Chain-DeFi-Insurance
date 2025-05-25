//SPDX License Identifier- MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../Wormhole/lib/wormhole-solidity-sdk/src/interfaces/IWormholeRelayer.sol";


contract policyManager is Ownable{

    IWormholeRelayer public wormholeRelayer;
    uint256 private constant GAS_LIMIT = 300000;

    enum ProductType {SmartContractRisk, RWA, DePIN }
    enum Status {
        active,
        expired,
        Claimed
    }
    uint256 public constant BASE_DENOMINATOR = 1e4;
    struct Policy{
        uint256 policy_ID;
        address asset_addrress;
        address user_address;
        ProductType productType;
        Status status_policy;
        uint256 startTime;
        uint256 expiryTime;
        uint256 premium;
    }
    struct RiskProfile{
        uint256 baseRate;
        uint256 riskFactor;

    }

    mapping(ProductType => RiskProfile) public riskprofiles; 

    mapping(address => uint256[]) public userPolices;// track the user policies
    // create a function for buying the policies 
    mapping(uint256 => Policy) public policies; // Track policies by ID
    uint256 public poolUtilizationFactor; // e.g., 120 = 1.2x if pool is 80% full
     uint256 public Duration =  30 days;
    uint256 private policyCounter;

     event PolicyPurchased(
        uint256 policy_ID,
        address indexed user,
        address asset,
        uint8 productType,
        uint256 startTime,
        uint256 expiryTime,
        uint256 premium
    );
    constructor(address _wormholeRelayer) Ownable(msg.sender) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
        
        // Initialize base rates and default risk factors (scaled by 100)
        riskprofiles[ProductType.SmartContractRisk] = RiskProfile(200, 150); // 2% base, 1.5x risk
        riskprofiles[ProductType.RWA] = RiskProfile(100, 120);               // 1% base, 1.2x risk
        riskprofiles[ProductType.DePIN] = RiskProfile(300, 130);             // 3% base, 1.3x risk

        // Initialize default pool utilization factor (scaled by 100)
        poolUtilizationFactor = 100; // Default to 1.0x (no adjustment)
    }
    
   


    function BuyPolicy(address asset, uint8 productType)external  payable {
        // here the cchallenge is the premium cost 
        require(msg.value > 0, "the premium should be greater than zero");
        require(Duration>0, "the duration can't be negative or zero");

        uint256 start = block.timestamp;
        uint256 end = start + Duration;
        
        policyCounter++;
        uint256 calculatedPremium = CalculatePremium(ProductType(productType), msg.value);

        policies[policyCounter]=Policy({
            policy_ID: policyCounter,
            asset_addrress: asset,
            user_address: msg.sender,
            productType : ProductType(productType),
            status_policy: Status.active,
            startTime: start, 
            expiryTime: end,
            premium: calculatedPremium // Calculate premium based on product type and coverage amount
        });

        userPolices[msg.sender].push(policyCounter);
        emit PolicyPurchased(policyCounter, msg.sender, asset, productType, start, end, calculatedPremium);
    }

    function getUserPolicy(address user) external view returns(uint256[] memory){
        return userPolices[user];

    }

    function getPolicy(uint256 policy_ID) external view returns(Policy memory){
        return policies[policy_ID];
    }
    // event to be created for the event monitoring 
    // function for the premium 
    function CalculatePremium(ProductType product, uint256 coverageAmount)public view returns(uint256){
        RiskProfile memory profiles = riskprofiles[product];

    // calculating the premium
     uint256 premium = (
        coverageAmount *
        profiles.baseRate *
        profiles.riskFactor *
        poolUtilizationFactor
    ) / (BASE_DENOMINATOR**2);

    return premium;
    }
     function quoteCrossChainCost(uint16 targetChain) public view returns (uint256 cost) {
        (cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, 0, GAS_LIMIT);
    }

    function sendMessage(uint16 targetChain, address targetAddress, uint256 policyId) external payable {
        uint256 cost = quoteCrossChainCost(targetChain); // Dynamically calculate the cross-chain cost
        require(msg.value >= cost, "Insufficient funds for cross-chain delivery");

        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            targetAddress,
            abi.encode(policyId, msg.sender, policies[policyId].premium), // Payload contains the message and sender address
            0, // No receiver value needed
            GAS_LIMIT // Gas limit for the transaction
        );

}
}