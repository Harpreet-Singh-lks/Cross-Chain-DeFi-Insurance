

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "../src/policyManager.sol";

contract DeployPolicyManager is Script{
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Get Wormhole Relayer address based on the network
        address wormholeRelayerAddress;
        uint256 chainId = block.chainid;
        
        if (chainId == 43113) {
            // Avalanche Fuji Testnet
            wormholeRelayerAddress = 0x7B1bD7a6b4E61c2a123AC6BC2cbfC614437D0470;
        } else if (chainId == 44787) {
            // Celo Alfajores Testnet
            wormholeRelayerAddress = 0x306B68267Deb7c5DfCDa3619E22E9Ca39C374f84;
        } else {
            revert("Unsupported network");
        }
        
        // Deploy PolicyManager
        policyManager manager = new policyManager(wormholeRelayerAddress);
        
        console.log("PolicyManager deployed at: %s", address(manager));
        
        vm.stopBroadcast();
    }
}