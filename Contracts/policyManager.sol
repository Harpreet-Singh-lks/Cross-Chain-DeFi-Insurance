//SPDX License Identifier- MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract policyManager is Ownable{
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
    constructor() {
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
        require(duration>0, "the duration can't be negative or zero");

        uint256 start = block.timestamp;
        uint256 end = start + duration;
        
        policyCounter++;

        policies[policyCounter]=Policy{
            policy_ID: policyCounter,
            asset_addrress: asset,
            user_address: meg.sender,
            productType : productType,
            status_policy: Status.active,
            startTime: start, 
            expiryTime: end,
            premium: CalculatePremium(ProductType(productType), msg.value) // Calculate premium based on product type and coverage amount
        };

        userPolices[msg.sender].push(policyCounter);
        emit PolicyPurchased(policyCounter, msg.sender, asset, productType, start, end, premium);
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
        profile.baseRate *
        profile.riskFactor *
        poolUtilizationFactor
    ) / (BASE_DENOMINATOR**2);

    return premium;
    }

    /*  function calculatePremium(ProductType productType) public view returns (uint256) {
        // Placeholder logic — you can enhance this based on risk level, pool health, etc.
        if (productType == ProductType.SmartContractRisk) {
            return basePremium;
        } else if (productType == ProductType.RWA) {
            return basePremium * 2;
        } else if (productType == ProductType.DePIN) {
            return basePremium * 3 / 2;
        } else {
            revert("Invalid product type");
        }
    } 
    */
}