// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PolicyNFT is ERC721URIStorage, Ownable {
    uint256 private tokenCounter;

    // Mapping to link policy IDs to NFT token IDs
    mapping(uint256 => uint256) public policyToToken;

    // Mapping to link NFT token IDs to policy IDs
    mapping(uint256 => uint256) public tokenToPolicy;

    event PolicyNFTMinted(uint256 indexed policyId, uint256 indexed tokenId, address indexed owner);

    constructor() ERC721("PolicyNFT", "PNFT") {
        tokenCounter = 0;
    }

    /**
     * @dev Mints an NFT for a given policy.
     * @param policyId The ID of the policy for which the NFT is being minted.
     * @param to The address of the user who will own the NFT.
     * @param tokenURI The metadata URI for the NFT.
     */
    function mintPolicyNFT(uint256 policyId, address to, string memory tokenURI) external onlyOwner returns (uint256) {
        require(policyToToken[policyId] == 0, "PolicyNFT: NFT already minted for this policy");

        tokenCounter++;
        uint256 tokenId = tokenCounter;

        // Mint the NFT
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);

        // Map the policy ID to the token ID
        policyToToken[policyId] = tokenId;
        tokenToPolicy[tokenId] = policyId;

        emit PolicyNFTMinted(policyId, tokenId, to);

        return tokenId;
    }

    /**
     * @dev Returns the policy ID associated with a given token ID.
     * @param tokenId The ID of the NFT token.
     */
    function getPolicyIdByTokenId(uint256 tokenId) external view returns (uint256) {
        require(_exists(tokenId), "PolicyNFT: Token does not exist");
        return tokenToPolicy[tokenId];
    }

    /**
     * @dev Returns the token ID associated with a given policy ID.
     * @param policyId The ID of the policy.
     */
    function getTokenIdByPolicyId(uint256 policyId) external view returns (uint256) {
        require(policyToToken[policyId] != 0, "PolicyNFT: No NFT minted for this policy");
        return policyToToken[policyId];
    }
}