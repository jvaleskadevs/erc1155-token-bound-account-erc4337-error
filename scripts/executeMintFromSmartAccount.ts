import { ethers } from "hardhat";

async function main() {
  const [signer, helper, nonHolder] = await ethers.getSigners();
   
  // ERC721 Mintable 
  const ERC721Mintable = "0x6bf3640F53D67cFF564272675181C5d6AF92C868";
  const ERC721MintableABI = ["function safeMint(address to) public"];
  const ERC721MintableIface = new ethers.Interface(ERC721MintableABI);
  
  // ERC1155 Bounded Account
  // Comment and uncomment to test different variants of ERC1155
  // ERC1155Ownable
  const accountAddress = "0xa1F1f1f31BC62058cBCfDb84A263ebb8cE11f282";
  // ERC1155OnlyFirstMinter
  //const accountAddress = "0x0ece10E4aC8f32e414B1bED9D17818c420Aa891a";
  // ERC1155LimitedSupply
  //const accountAddress = "0x183db5BDB3b3ba52978F204846315F44722eDd03";
  const account = await ethers.getContractAt(
    "ERC1155BoundedAccount", accountAddress
  );
   
  // Mint with the signer signature
  // ERC1155Ownable · the account should mint
  // ERC1155OnlyFirstMinter · the account should mint
  // ERC1155LimitedSupply · the account should mint
  try {
    let tx = await account.executeCall(
      ERC721Mintable,
      0n,
      ERC721MintableIface.encodeFunctionData(
        "safeMint",
        [account.target],
        0n
      ),
      { gasLimit: 500000 }
    );
    
    await tx.wait();
    
    console.log("Tx 0:");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 0: failed");
  }
  
  // Mint with the helper signature
  // ERC1155Ownable · the account should mint
  // ERC1155OnlyFirstMinter · the account should mint
  // ERC1155LimitedSupply · helper is a non holder, should fail!
  try {
    let tx = await account.connect(helper).executeCall(
      ERC721Mintable,
      0n,
      ERC721MintableIface.encodeFunctionData(
        "safeMint",
        [account.target],
        0n
      ),
      { gasLimit: 500000 }
    );
    
    await tx.wait();
    
    console.log("Tx 1:");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 1: failed");
  }    
  
  // Mint with a non holder signature
  // the next call SHOULD revert and break the script execution
  // Not token owner/forbidden error, for all ERC1155 samples
  try { 
    let tx = await account.connect(nonHolder).executeCall(
      ERC721Mintable,
      0n,
      ERC721MintableIface.encodeFunctionData(
        "safeMint",
        [account.target],
        0n
      ),
      { gasLimit: 500000 }
    );
    
    await tx.wait();
    
    console.log("Tx 2:");
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
