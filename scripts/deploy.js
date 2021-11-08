
const hre = require("hardhat");
const fs = require("fs");

async function main() {

  const NFTMarket = await hre.ethers.getContractFactory("Market");
  const nftmarket = await NFTMarket.deploy();
  await nftmarket.deployed();

  console.log("nftmarket deployed to:", nftmarket.address);


  const NFT = await hre.ethers.getContractFactory("NFT");
  const nft = await NFT.deploy(nftmarket.address);
  await nft.deployed();

  console.log("nft deployed to:", nft.address);

  let config = `
  export const nftMarketAddress = ${nftmarket.address}
  export const nftAddress = ${nft.address}
  `
  let data = JSON.stringify(config)
  fs.writeFileSync('config.js', JSON.parse(data))
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
