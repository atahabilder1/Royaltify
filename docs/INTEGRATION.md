# Integration Guide

Guide for integrating Royaltify contracts with frontend applications and backends.

## Overview

This guide covers:
1. Contract interaction from JavaScript/TypeScript
2. Event listening and indexing
3. Common integration patterns
4. Frontend examples

---

## Contract ABIs

### Generating ABIs

```bash
# Build contracts (generates ABIs in out/)
forge build

# ABI locations
out/RoyaltifyNFT.sol/RoyaltifyNFT.json
out/RoyaltifyMarketplace.sol/RoyaltifyMarketplace.json
```

### Extracting ABI

```bash
# Extract just the ABI
cat out/RoyaltifyNFT.sol/RoyaltifyNFT.json | jq '.abi' > abi/RoyaltifyNFT.json
cat out/RoyaltifyMarketplace.sol/RoyaltifyMarketplace.json | jq '.abi' > abi/RoyaltifyMarketplace.json
```

---

## JavaScript/TypeScript Integration

### Using ethers.js v6

#### Setup

```typescript
import { ethers } from 'ethers';
import RoyaltifyNFTAbi from './abi/RoyaltifyNFT.json';
import RoyaltifyMarketplaceAbi from './abi/RoyaltifyMarketplace.json';

const NFT_ADDRESS = '0x...';
const MARKETPLACE_ADDRESS = '0x...';

// Connect to provider
const provider = new ethers.BrowserProvider(window.ethereum);
const signer = await provider.getSigner();

// Create contract instances
const nft = new ethers.Contract(NFT_ADDRESS, RoyaltifyNFTAbi, signer);
const marketplace = new ethers.Contract(MARKETPLACE_ADDRESS, RoyaltifyMarketplaceAbi, signer);
```

#### Minting NFT

```typescript
async function mintNFT(tokenURI: string): Promise<number> {
  const tx = await nft.mint(tokenURI);
  const receipt = await tx.wait();

  // Get tokenId from event
  const event = receipt.logs
    .map(log => nft.interface.parseLog(log))
    .find(e => e?.name === 'Minted');

  return Number(event?.args.tokenId);
}

// Usage
const tokenId = await mintNFT('ipfs://QmYourMetadataHash');
console.log('Minted token:', tokenId);
```

#### Advanced Minting

```typescript
async function mintNFTAdvanced(
  recipient: string,
  tokenURI: string,
  royaltyReceiver: string,
  royaltyPercent: number // e.g., 5 for 5%
): Promise<number> {
  const royaltyBasisPoints = royaltyPercent * 100; // 5% = 500

  const tx = await nft['mint(address,string,address,uint96)'](
    recipient,
    tokenURI,
    royaltyReceiver,
    royaltyBasisPoints
  );
  const receipt = await tx.wait();

  const event = receipt.logs
    .map(log => nft.interface.parseLog(log))
    .find(e => e?.name === 'Minted');

  return Number(event?.args.tokenId);
}
```

#### Listing NFT

```typescript
async function listNFT(
  tokenId: number,
  priceInEth: string
): Promise<number> {
  // 1. Approve marketplace
  const approveTx = await nft.approve(MARKETPLACE_ADDRESS, tokenId);
  await approveTx.wait();

  // 2. Create listing
  const priceWei = ethers.parseEther(priceInEth);
  const listTx = await marketplace.listNFT(NFT_ADDRESS, tokenId, priceWei);
  const receipt = await listTx.wait();

  // Get listingId from event
  const event = receipt.logs
    .map(log => marketplace.interface.parseLog(log))
    .find(e => e?.name === 'Listed');

  return Number(event?.args.listingId);
}

// Usage
const listingId = await listNFT(0, '1.5'); // List token 0 for 1.5 ETH
```

#### Buying NFT

```typescript
async function buyNFT(listingId: number): Promise<void> {
  // Get listing details
  const listing = await marketplace.getListing(listingId);

  // Buy with exact price
  const tx = await marketplace.buyNFT(listingId, {
    value: listing.price
  });
  await tx.wait();

  console.log('NFT purchased!');
}
```

#### Withdrawing Proceeds

```typescript
async function withdrawProceeds(): Promise<string> {
  const address = await signer.getAddress();
  const proceeds = await marketplace.getProceeds(address);

  if (proceeds === 0n) {
    throw new Error('No proceeds to withdraw');
  }

  const tx = await marketplace.withdrawProceeds();
  await tx.wait();

  return ethers.formatEther(proceeds);
}

// Usage
const withdrawn = await withdrawProceeds();
console.log(`Withdrawn: ${withdrawn} ETH`);
```

---

### Using viem

```typescript
import { createPublicClient, createWalletClient, http, parseEther } from 'viem';
import { mainnet } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const publicClient = createPublicClient({
  chain: mainnet,
  transport: http()
});

const walletClient = createWalletClient({
  chain: mainnet,
  transport: http()
});

// Read listing
const listing = await publicClient.readContract({
  address: MARKETPLACE_ADDRESS,
  abi: RoyaltifyMarketplaceAbi,
  functionName: 'getListing',
  args: [0n]
});

// Buy NFT
const hash = await walletClient.writeContract({
  address: MARKETPLACE_ADDRESS,
  abi: RoyaltifyMarketplaceAbi,
  functionName: 'buyNFT',
  args: [0n],
  value: listing.price
});
```

---

## Event Listening

### Real-time Events

```typescript
// Listen for new listings
marketplace.on('Listed', (listingId, seller, nftContract, tokenId, price, event) => {
  console.log('New listing:', {
    listingId: Number(listingId),
    seller,
    nftContract,
    tokenId: Number(tokenId),
    price: ethers.formatEther(price)
  });
});

// Listen for sales
marketplace.on('Sale', (listingId, buyer, seller, nftContract, tokenId, price, royaltyAmount, royaltyReceiver) => {
  console.log('Sale:', {
    listingId: Number(listingId),
    buyer,
    seller,
    tokenId: Number(tokenId),
    price: ethers.formatEther(price),
    royalty: ethers.formatEther(royaltyAmount)
  });
});

// Listen for NFT mints
nft.on('Minted', (creator, recipient, tokenId, tokenURI) => {
  console.log('Minted:', {
    creator,
    recipient,
    tokenId: Number(tokenId),
    tokenURI
  });
});
```

### Historical Events

```typescript
// Get all past listings
async function getPastListings(fromBlock: number): Promise<any[]> {
  const filter = marketplace.filters.Listed();
  const events = await marketplace.queryFilter(filter, fromBlock, 'latest');

  return events.map(e => ({
    listingId: Number(e.args.listingId),
    seller: e.args.seller,
    nftContract: e.args.nftContract,
    tokenId: Number(e.args.tokenId),
    price: ethers.formatEther(e.args.price),
    blockNumber: e.blockNumber,
    transactionHash: e.transactionHash
  }));
}
```

---

## Common Queries

### Get All Active Listings

```typescript
async function getActiveListings(page = 0, pageSize = 10) {
  const [listings, ids] = await marketplace.getActiveListings(
    page * pageSize,
    pageSize
  );

  return listings.map((listing, i) => ({
    id: Number(ids[i]),
    seller: listing.seller,
    nftContract: listing.nftContract,
    tokenId: Number(listing.tokenId),
    price: ethers.formatEther(listing.price),
    status: ['Active', 'Sold', 'Cancelled'][listing.status],
    listedAt: new Date(Number(listing.listedAt) * 1000)
  }));
}
```

### Get User's NFTs

```typescript
async function getUserNFTs(address: string) {
  const balance = await nft.balanceOf(address);
  const tokens = [];

  for (let i = 0; i < balance; i++) {
    const tokenId = await nft.tokenOfOwnerByIndex(address, i);
    const tokenURI = await nft.tokenURI(tokenId);
    const creator = await nft.tokenCreator(tokenId);
    const [royaltyReceiver, royaltyAmount] = await nft.royaltyInfo(tokenId, ethers.parseEther('1'));

    tokens.push({
      tokenId: Number(tokenId),
      tokenURI,
      creator,
      royaltyPercent: Number(royaltyAmount) / 100 // Convert from basis points
    });
  }

  return tokens;
}
```

### Get User's Listings

```typescript
async function getUserListings(address: string) {
  const [listings, ids] = await marketplace.getListingsBySeller(address);

  return listings.map((listing, i) => ({
    id: Number(ids[i]),
    tokenId: Number(listing.tokenId),
    price: ethers.formatEther(listing.price),
    status: ['Active', 'Sold', 'Cancelled'][listing.status]
  }));
}
```

### Check Royalty Info

```typescript
async function getRoyaltyInfo(tokenId: number, salePrice: string) {
  const priceWei = ethers.parseEther(salePrice);
  const [receiver, amount] = await nft.royaltyInfo(tokenId, priceWei);

  return {
    receiver,
    amount: ethers.formatEther(amount),
    percentage: (Number(amount) / Number(priceWei)) * 100
  };
}
```

---

## Metadata Handling

### Fetch Token Metadata

```typescript
async function getTokenMetadata(tokenId: number) {
  const tokenURI = await nft.tokenURI(tokenId);

  // Handle IPFS URIs
  const url = tokenURI.replace('ipfs://', 'https://ipfs.io/ipfs/');

  const response = await fetch(url);
  const metadata = await response.json();

  return {
    name: metadata.name,
    description: metadata.description,
    image: metadata.image?.replace('ipfs://', 'https://ipfs.io/ipfs/'),
    attributes: metadata.attributes
  };
}
```

### Upload Metadata to IPFS

```typescript
import { create } from 'ipfs-http-client';

const ipfs = create({ url: 'https://ipfs.infura.io:5001' });

async function uploadMetadata(
  name: string,
  description: string,
  imageFile: File
) {
  // Upload image
  const imageResult = await ipfs.add(imageFile);
  const imageURI = `ipfs://${imageResult.path}`;

  // Create metadata
  const metadata = {
    name,
    description,
    image: imageURI,
    attributes: []
  };

  // Upload metadata
  const metadataResult = await ipfs.add(JSON.stringify(metadata));
  return `ipfs://${metadataResult.path}`;
}
```

---

## Error Handling

### Decoding Contract Errors

```typescript
async function safeContractCall<T>(
  contractCall: Promise<T>,
  contract: ethers.Contract
): Promise<T> {
  try {
    return await contractCall;
  } catch (error: any) {
    // Try to decode custom error
    if (error.data) {
      const decodedError = contract.interface.parseError(error.data);
      if (decodedError) {
        throw new Error(`Contract error: ${decodedError.name}`);
      }
    }
    throw error;
  }
}

// Usage
try {
  await safeContractCall(
    marketplace.buyNFT(listingId, { value: wrongPrice }),
    marketplace
  );
} catch (e) {
  console.error(e.message); // "Contract error: IncorrectPayment"
}
```

### Error Messages Map

```typescript
const ERROR_MESSAGES: Record<string, string> = {
  'PriceCannotBeZero': 'Price must be greater than zero',
  'ListingNotFound': 'This listing does not exist',
  'ListingNotActive': 'This listing is no longer available',
  'NotSeller': 'Only the seller can perform this action',
  'CannotBuyOwnListing': 'You cannot buy your own listing',
  'IncorrectPayment': 'Please send the exact listing price',
  'InvalidNFTContract': 'Invalid NFT contract address',
  'NotApprovedForNFT': 'Please approve the marketplace first',
  'NoProceeds': 'No proceeds available to withdraw',
  'NotTokenCreator': 'Only the creator can update royalties',
  'RoyaltyFeeTooHigh': 'Royalty cannot exceed 10%',
  'EmptyTokenURI': 'Token URI cannot be empty'
};

function getUserFriendlyError(errorName: string): string {
  return ERROR_MESSAGES[errorName] || 'An unexpected error occurred';
}
```

---

## React Hooks Example

```typescript
import { useState, useEffect } from 'react';
import { useContractRead, useContractWrite } from 'wagmi';

// Hook for active listings
function useActiveListings(page = 0, pageSize = 10) {
  const { data, isLoading, refetch } = useContractRead({
    address: MARKETPLACE_ADDRESS,
    abi: RoyaltifyMarketplaceAbi,
    functionName: 'getActiveListings',
    args: [BigInt(page * pageSize), BigInt(pageSize)]
  });

  return {
    listings: data?.[0] || [],
    listingIds: data?.[1] || [],
    isLoading,
    refetch
  };
}

// Hook for buying NFT
function useBuyNFT() {
  const { write, isLoading, isSuccess } = useContractWrite({
    address: MARKETPLACE_ADDRESS,
    abi: RoyaltifyMarketplaceAbi,
    functionName: 'buyNFT'
  });

  const buy = (listingId: number, price: bigint) => {
    write({ args: [BigInt(listingId)], value: price });
  };

  return { buy, isLoading, isSuccess };
}
```

---

## Subgraph Integration

For production applications, consider using The Graph for efficient querying.

### Sample Subgraph Schema

```graphql
type NFT @entity {
  id: ID!
  tokenId: BigInt!
  creator: Bytes!
  owner: Bytes!
  tokenURI: String!
  royaltyReceiver: Bytes!
  royaltyFee: BigInt!
  createdAt: BigInt!
}

type Listing @entity {
  id: ID!
  listingId: BigInt!
  nft: NFT!
  seller: Bytes!
  price: BigInt!
  status: String!
  createdAt: BigInt!
  soldAt: BigInt
  buyer: Bytes
}

type Sale @entity {
  id: ID!
  listing: Listing!
  buyer: Bytes!
  price: BigInt!
  royaltyAmount: BigInt!
  royaltyReceiver: Bytes!
  timestamp: BigInt!
}
```

---

## Best Practices

1. **Always check approvals** before listing
2. **Use multicall** for batch reads
3. **Cache metadata** to reduce IPFS calls
4. **Handle chain reorgs** for event indexing
5. **Validate addresses** before contract calls
6. **Show gas estimates** before transactions
7. **Implement proper error handling** with user-friendly messages
