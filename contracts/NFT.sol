//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

contract NFT is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter private tokenIds; // keep track of token IDs
    address marketplaceAddress; // address of Marketplace for NFT interraction

    constructor(address _marketplaceAddress) ERC721('KryptoBirdz', 'KBT') {
        marketplaceAddress = _marketplaceAddress;
    }

    function mintToken(string memory _tokenURI) public returns(uint256) {
        tokenIds.increment();
        uint256 newItemId = tokenIds.current();
        _mint(msg.sender, newItemId);
        // set the token URI, id and url
        _setTokenURI(newItemId, _tokenURI);
        // give marketplace the approval to transact between users
        setApprovalForAll(marketplaceAddress, true);
        // mint the token and set it for sale - return the id to do so
        return newItemId;
    }

}

