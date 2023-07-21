import { ethers } from "hardhat";
import { signUserOp, fillUserOpDefaults, getUserOpHash } from "./userOpsUtils";
import { BytesLike, hexValue } from '@ethersproject/bytes'


// This script will fail
// The Token Bound Account needs to check whether the signer is a token owner or not,
// but looks like it is not allowed by the ERC4337 rules (?!)

// Maybe a work around exists, or maybe I am missing something, anyway, I am working on it.

// Error:
// ProviderError: account accesses inaccessible storage at address: 0xa5273ebbc9bdf1201747da5abe7cd73a9d41b43e slot: 0xc019d39e0cccaedbf8f42be09c3f32a6c18582e6ecc00d3949872b669a974bad

async function main() {
  const [signer] = await ethers.getSigners();
  const entrypoint = "0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789";
  const chainId = 80001;
  
  // ERC721 Mintable 
  const ERC721Mintable = "0x6bf3640F53D67cFF564272675181C5d6AF92C868";
  const ERC721MintableABI = ["function safeMint(address to) public"];
  const ERC721MintableIface = new ethers.Interface(ERC721MintableABI);
  
  
  // ERC1155Ownable Bounded Account
  try {
    const ERC1155Ownable = "0xa1F1f1f31BC62058cBCfDb84A263ebb8cE11f282";
    
    const account = await ethers.getContractAt(
      "ERC1155BoundedAccount", ERC1155Ownable
    );
    
    const userOp = signUserOp(fillUserOpDefaults({
      sender: account.target,
      callGasLimit: 200000,
      verificationGasLimit: 100000,
      maxFeePerGas: 3e9,
      maxPriorityFeePerGas: 1500000000,
      preVerificationGas: 50000,
      callData: ERC721MintableIface
        .encodeFunctionData(
          "safeMint",
          [account.target],
          0n
        )
    }), new ethers.Wallet(process.env.PK as string, signer), entrypoint, chainId)
    
    const userOpHash = await getUserOpHash(userOp, entrypoint, chainId)
    console.log(userOp)
    console.log(userOpHash)
    

    const cleanUserOp = Object.keys(userOp).map(key => {
      let val = (userOp as any)[key]
      if (typeof val !== 'string' || !val.startsWith('0x')) {
        val = hexValue(val)
      }
      return [key, val]
    })
      .reduce((set, [k, v]) => ({ ...set, [k]: v }), {})
      console.log(signer.provider)
    let tx = await signer.provider.send('eth_sendUserOperation', [cleanUserOp, entrypoint]);
    
    await tx.wait();
    
    console.log("successfully");
    console.log(tx);
  } catch (err) {
    console.log(err);
    console.log("Tx 0: failed");
  }  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
