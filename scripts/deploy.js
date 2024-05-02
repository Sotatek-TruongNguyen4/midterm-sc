const { ethers } = require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();

  const Token = await ethers.getContractFactory("Token");
  const SwapContract = await ethers.getContractFactory("SwapContract");

  await Token.connect(signer).deploy("TokenA", "TKA");

  await Token.connect(signer).deploy("TokenB", "TKB");

  const swapContract = await SwapContract.connect(signer).deploy(signer.address);
  console.log(
    `${await swapContract.getAddress()} \n${signer.address
    }`
  );
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.log(err);
    process.exit(1);
  });