//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Counters.sol';

import 'hardhat/console.sol';

contract Market is ReentrancyGuard {

    using Counters for Counters.Counter;

    // number of items minting, number of txs, not sold tokens
    // keep track of tokens total number-tokenID
    // arrays need to know the length-help to keep track of arrays

    Counters.Counter private _tokenIds;
    Counters.Counter private _tokensSold;

    // determine who is the contract owner
    // charge a listing fee so the owner makes a commission

    address payable owner;

    // we are deploying to matic (polygon), the API is tha same so you can use ether the same as matic
    // both have 18 decimals
    uint256 listingPrice = 0.045 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketToken {
        uint itemId;
        address nftContract;
        uint256 tokenId; // which marketToken 
        address payable seller; // who sells it 
        address payable owner; // who buys it
        uint256 price;
        bool sold;
    }

    // token ID returns which MarketToken
    mapping(uint256 => MarketToken) private idToMarketToken;

    // listen to events from frontend apps
    event MarketTokenMinted(
        uint indexed itemId, 
        address indexed nftContract, 
        uint256 indexed tokenId,
        address payable seller,
        address payable owner,
        uint256 price, 
        bool sold
    );

    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    // two functions to interact with contract
    // 1. create a market item to put it for sale
    // 2. create a market sale for buying/selling

    function makeMarketItem(
        address nftContract,
        uint tokenId,
        uint price
    ) public payable nonReentrant {
        require(price>0, 'Price must be at list 1 wei');
        require(msg.value == listingPrice, 'value must be equal to listing price');
                console.log('listingPrice', listingPrice);
                console.log('msg.value', msg.value);
        _tokenIds.increment();
        uint itemId = _tokenIds.current();

        // put item for sale - bool - no owner
        idToMarketToken[itemId] = MarketToken(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender), 
            payable(address(0)),
            price,
            false
        );

        // nft transaction
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit MarketTokenMinted(
            itemId,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );
    }

    // function to conduct txs and market sales

    function createMarketSale(
        address nftContract,
        uint itemId
    ) public payable nonReentrant {
        uint price = idToMarketToken[itemId].price;
        uint tokenId = idToMarketToken[itemId].tokenId;

        require( msg.value == price, 'please submit the asking price');

        // transfer the ammount to the seller
        idToMarketToken[itemId].seller.transfer(msg.value);

        // transfer the token from contract address to the buyer
        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idToMarketToken[itemId].owner = payable(msg.sender);
        idToMarketToken[itemId].sold = true;

        _tokensSold.increment();

        payable(owner).transfer(listingPrice);
    }

    // function to fetchMarketItems - minting, buying/selling
    // returns the number of unsold items

    function fetchMarketTokens() public view returns(MarketToken[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _tokensSold.current();
        uint currentIndex = 0;

        // looping over the number od items created (if number has not been sold)
        MarketToken[] memory items = new MarketToken[](unsoldItemCount);
        for(uint i=0; i < itemCount; i++) {
            if(idToMarketToken[i+1].owner == address(0)) {
                uint currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }

    // function to return the nfts user purchased

    function fetchMyNFTs() public view returns(MarketToken[] memory) {
        uint totalItemsCount = _tokenIds.current();
        // second counter for each individual user
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i=0; i < totalItemsCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                itemCount += 1;                
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        // second loop though the amount you have purchased with itemCount
        // check to see if onwer == msg.sender

        for (uint i=0; i < totalItemsCount; i++) {
            if(idToMarketToken[i+1].owner == msg.sender) {
                uint currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }

    // function to return the nfts user created

    function fetchItemsCreated() public view returns(MarketToken[] memory) {
        uint totalItemsCount = _tokenIds.current();
        uint itemCount = 0;
        uint currentIndex = 0;

        for (uint i=0; i < totalItemsCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                itemCount += 1;                
            }
        }

        MarketToken[] memory items = new MarketToken[](itemCount);

        for (uint i=0; i < totalItemsCount; i++) {
            if(idToMarketToken[i+1].seller == msg.sender) {
                uint currentId = i + 1;
                MarketToken storage currentItem = idToMarketToken[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }
        return items;
    }
}