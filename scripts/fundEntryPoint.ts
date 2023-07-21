import { ethers } from "hardhat";

async function main() {
  const [signer] = await ethers.getSigners();
  
  // ERC1155Ownable Bounded Account
  try {
    const ERC1155Ownable = "0xa1F1f1f31BC62058cBCfDb84A263ebb8cE11f282";
    
    const account = await ethers.getContractAt(
      "ERC1155BoundedAccount", ERC1155Ownable
    );
 
    let tx = await account.addDeposit(
      { value: ethers.parseEther('0.01') }
    );
    
    await tx.wait();
    
    console.log("EntryPoint for ERC1155Ownable account funded successfully");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 0: failed");
  }
  
  // ERC1155OnlyFirstMinter Bounded Account
  try {
    const ERC1155OnlyFirstMinter = "0x0ece10E4aC8f32e414B1bED9D17818c420Aa891a";
    
    const account = await ethers.getContractAt(
      "ERC1155BoundedAccount", ERC1155OnlyFirstMinter
    );
 
    let tx = await account.addDeposit(
      { value: ethers.parseEther('0.01') }
    );
    
    await tx.wait();
    
    console.log("EntryPoint for ERC1155OnlyFirstMinter account funded successfully");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 1: failed");
  }  

  // ERC1155LimitedSupply Bounded Account
  try {
    const ERC1155LimitedSupply = "0x183db5BDB3b3ba52978F204846315F44722eDd03";
    
    const account = await ethers.getContractAt(
      "ERC1155BoundedAccount", ERC1155LimitedSupply
    );
 
    let tx = await account.addDeposit(
      { value: ethers.parseEther('0.01') }
    );
    
    await tx.wait();
    
    console.log("EntryPoint for ERC1155LimitedSupply account funded successfully");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 2: failed");
  }   
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
