// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/ClaimVerify.sol";

contract DeployClaimVerify is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Input parameters from environment variables
        address policyManagerAddress = vm.envAddress("POLICY_MANAGER_ADDRESS");
        address wormholeRelayerAddress;
        uint16 targetChainId;
        address targetRiskPoolAddress = address(0x1111111111111111111111111111111111111111); 
        
        
        uint256 chainId = block.chainid;
        
        if (chainId == 43113) {
            // Avalanche Fuji Testnet
            wormholeRelayerAddress = 0x7B1bD7a6b4E61c2a123AC6BC2cbfC614437D0470;
            targetChainId = 14; // Celo Alfajores Chain ID in Wormhole
        } else if (chainId == 44787) {
            // Celo Alfajores Testnet
            wormholeRelayerAddress = 0x306B68267Deb7c5DfCDa3619E22E9Ca39C374f84;
            targetChainId = 6; // Avalanche Fuji Chain ID in Wormhole
        } else {
            revert("Unsupported network");
        }
        
        // Deploy ClaimVerify
        ClaimVerify verifier = new ClaimVerify(
            policyManagerAddress,
            wormholeRelayerAddress,
            targetChainId,
            targetRiskPoolAddress
        );
        
        console.log("ClaimVerify deployed at: %s", address(verifier));
        
        vm.stopBroadcast();
    }
}