async function main() {
  const PresaleFactory = await ethers.getContractFactory("presaleFactory");
  const nativeTokenAddress = "";
  const minBlocksStaked = 0;
  
  // Start deployment, returning a promise that resolves to a contract object
  const presaleFactory = await PresaleFactory.deploy(
    nativeTokenAddress,
    minBlocksStaked
  );
  
  console.log("Contract deployed to address:", presaleFactory.address);
}

main()
.then(() => process.exit(0))
.catch(error => {
  console.error(error);
  process.exit(1);
});