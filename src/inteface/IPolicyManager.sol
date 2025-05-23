//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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