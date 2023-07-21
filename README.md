# ERC-1155 Token Bound Account
## ERC-4337 & ERC-6551 for ERC-1155 tokens
ERC-1155 token bound account (error) is a failed implementation of ERC-4337 & ERC-6551 supporting ERC-1155 tokens instead ERC-721.

## Important info about this README file
- This README file has been created for another [repository](https://github.com/jvaleskadevs/erc1155-token-bound-account) that does not include ERC-4337 support but it works perfectly.
- While this README may be relevant for both repositories, it is important to know that.
- In addition to the original README, these 2 important messages were added. We added the Fund EntryPoint and Send User Operations sections. 

## Important info about the error
- The error itself:
```
Error:
ProviderError: account accesses inaccessible storage at address: 0xa5273ebbc9bdf1201747da5abe7cd73a9d41b43e slot: 0xc019d39e0cccaedbf8f42be09c3f32a6c18582e6ecc00d3949872b669a974bad
```
- Explanation: we are trying to access to non-constant data in an external contract when we try to get the `balanceOf` tokens the signer is holding.

This is essential functionality, so we cannot skip this check, it applies to all ERC-1155/ERC-721, ERC-6551 and ERC4337 combinations. ERC-4337 does not allow us to implement them in combination. Maybe I am missing something or a workaround exists, anyway, I am working on it.

## ERC-1155 Token Bounded Account

The ERC-1155 token bounded accounts supports creating ERC-1155 token bounded accounts trough ERC6551Registry and they are compliant with ERC-165, ERC-1271 and with the ERC-6551Registry, obviously. A pending improvement proposal to ERC6551 may give full compatibility to this implementation in the future. Or it may be reached trough minor changes.
These token bound account are supporting ERC777, ERC1155 and ERC721 receiver interfaces, too.

### Semi-fungibility problematic
The main problem with ERC1155 NFTs and ERC6551 is semi-fungibility. We are proposing 3 basic approaches to deal with that:
- ERC-1155 Ownable -> the basic ERC-1155 sample from the Oz's wizard. (it requires 1 ERC-1155 contract per user)
- ERC-1155 Only First Minter -> the first minter of any ID becomes the owner of this ID, the only one able to mint new tokens with this ID aka the ID owner. This is the most decentralized and efficient of the 3. It requires one token ID per user and allow multiple owners as the previous one.
- ERC-1155 Limited Supply -> ERC-721 fungibility capabilities implemented trough limitation of supply per ID to 1. Only one owner per ID. Does not allow multiples signers by default. A developer may implement this behavior trough other ways, tho.

## Setup
- Clone the repo:
```
git clone https://github.com/jvaleskadevs/erc1155-token-bound-account.git
```
- Install dependencies:
```
npm install
```
- Copy the `.env.sample` and fill it with your environment variables:
```
cp .env.sample .env
```
You will need 3 private keys (signer, helper and non-holder), an RPC url and an optional PolygonScan apiKey.

## Deploy
- Deploy ERC-6551 Registry:
```
npx hardhat run scripts/deployRegistry.ts
```
- Deploy ERC-1155 Token Bound Account implementation:
```
npx hardhat run scripts/deployAccount.ts
```
- Deploy the ERC-1155 NFTs variants, the erc1155BoundedAccount implementation will be bounded to them:
```
npx hardhat run scripts/deployNFTs.ts
```
It will deploy an ERC-721 NFT contract too, we will be minting some of these NFTs to test our ERC-1155 Token Bounded Account.

## Minting the ERC-1155 tokens to bound accounts to
First, we need to mint the ERC-1155 tokens to bound our smart accounts to them.
For testing I have been minting the ERC-1155 tokens trough PolygonScan.
But, a script to do that can be found at `scripts/mintERC1155Nfts.ts`, fill it with the addresses from `deployNfts.ts` and run it:
```
npx hardhat run scripts/mintERC1155Nfts.ts
```
It includes the addresses of `ERC1155FirstMinter` and `ERC1155LimitedSupply`, feel free to use them, but be aware that some tokenIds may have been minted previously. The `ERC1155Ownable` is not included. Obviously, it implements an `onlyOwner` modifier.

## Create Accounts
After that, we are ready to create our Token Bounded Accounts through the ERC6551Registry contract. 
For testing I have been creating the Token Bounded Accounts trough PolygonScan.
But, a script to do that can be found at `scripts/createAccounts.ts`, fill it with the right addresses and run it:
```
npx hardhat run scripts/createAccounts.ts
```
The transaction parameters should look like that (in case you go trough PolygonScan):
```
createAccount(
  implementationAddress, // the erc1155BoundedAccount address from the deployAccount script.
  80001, // chainId, polygon Mumbai.
  nftContractAddress, // address of the erc1155 nft contract to bound the accounts to.
  tokenId, // erc1155 ID of the NFT to bound the account to
  0, // a random salt, any value.
  0x, // initData
)
```
After successfully confirm the transaction, check the address of your account in the event logs in PolygonScan.

## Test
- Minting some NFTs (ERC-721) from our ERC-1155 Token Bounded Account:
```
npx hardhat run scripts/executeMintFromSmartAccount.ts
```
This script includes the ability to connect to any of our Token Bounded Account variants, (ERC1155Ownable, ERC1155OnlyFirstMinter or/and ERC1155LimitedSupply). Just comment/uncomment the `accountAddress` variable with the right one address.
These addresses are easy to find in the Event Logs of the `createAccount` transaction.

- The `useAccount` script does some tests over the signature's validation.

## Fund EntryPoint
- The entrypoint need some native tokens to pay for gas, so we need to fund it:
```
npx hardhat run scripts/fundEntryPoint.ts
```
## Send User Operations
- Account abstraction magic happens here, but we are not great magicians, so it will fail:
```
npx hardhat run scripts/sendUserOps.ts
```

