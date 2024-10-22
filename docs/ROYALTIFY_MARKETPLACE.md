# RoyaltifyMarketplace Contract Documentation

## Overview

RoyaltifyMarketplace is a secure NFT marketplace contract that automatically enforces EIP-2981 royalties on all sales. It features reentrancy protection, pull payment pattern, and configurable protocol fees.

## Contract Details

| Property | Value |
|----------|-------|
| Contract Name | RoyaltifyMarketplace |
| Solidity Version | ^0.8.28 |
| License | MIT |
| Inheritance | ReentrancyGuard, Ownable2Step |

## Constants

```solidity
uint256 public constant MAX_PROTOCOL_FEE = 500;  // 5% maximum protocol fee
```

## State Variables

| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `protocolFee` | uint256 | public | Current protocol fee in basis points |
| `protocolFeeRecipient` | address | public | Address receiving protocol fees |
| `listingCount` | uint256 | public | Total number of listings created |
| `_listings` | mapping(uint256 => Listing) | private | Listing ID to listing data |
| `_proceeds` | mapping(address => uint256) | private | User address to withdrawable proceeds |

## Data Structures

### ListingStatus
```solidity
enum ListingStatus {
    Active,     // 0 - Available for purchase
    Sold,       // 1 - Successfully sold
    Cancelled   // 2 - Cancelled by seller
}
```

### Listing
```solidity
struct Listing {
    address seller;       // NFT owner who created listing
    address nftContract;  // Address of the NFT contract
    uint256 tokenId;      // Token ID being sold
    uint256 price;        // Price in wei
    ListingStatus status; // Current status
    uint256 listedAt;     // Block timestamp when listed
}
```

## Events

### Listed
```solidity
event Listed(
    uint256 indexed listingId,
    address indexed seller,
    address indexed nftContract,
    uint256 tokenId,
    uint256 price
);
```
Emitted when a new listing is created.

### ListingUpdated
```solidity
event ListingUpdated(
    uint256 indexed listingId,
    uint256 oldPrice,
    uint256 newPrice
);
```
Emitted when a listing price is changed.

### ListingCancelled
```solidity
event ListingCancelled(uint256 indexed listingId);
```
Emitted when a listing is cancelled.

### Sale
```solidity
event Sale(
    uint256 indexed listingId,
    address indexed buyer,
    address indexed seller,
    address nftContract,
    uint256 tokenId,
    uint256 price,
    uint256 royaltyAmount,
    address royaltyReceiver
);
```
Emitted when an NFT is sold.

### ProtocolFeeUpdated
```solidity
event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);
```

### ProtocolFeeRecipientUpdated
```solidity
event ProtocolFeeRecipientUpdated(address oldRecipient, address newRecipient);
```

### ProceedsWithdrawn
```solidity
event ProceedsWithdrawn(address indexed user, uint256 amount);
```

## Errors

| Error | Description |
|-------|-------------|
| `PriceCannotBeZero()` | Listing price must be greater than 0 |
| `ListingNotFound()` | Listing ID doesn't exist |
| `ListingNotActive()` | Listing is sold or cancelled |
| `NotSeller()` | Caller is not the listing seller |
| `CannotBuyOwnListing()` | Seller cannot buy their own listing |
| `IncorrectPayment()` | ETH sent doesn't match listing price |
| `InvalidNFTContract()` | Contract doesn't support ERC721 |
| `NotApprovedForNFT()` | Marketplace not approved for NFT |
| `ProtocolFeeTooHigh()` | Fee exceeds MAX_PROTOCOL_FEE |
| `NoProceeds()` | No proceeds available to withdraw |
| `TransferFailed()` | ETH transfer failed |
| `ZeroAddress()` | Address cannot be zero |

## Functions

### Constructor

```solidity
constructor(uint256 initialFee, address feeRecipient)
```

Deploys the marketplace with initial configuration.

**Parameters:**
- `initialFee`: Protocol fee in basis points (max 500 = 5%)
- `feeRecipient`: Address to receive protocol fees

**Reverts:**
- `ProtocolFeeTooHigh()` if initialFee > 500
- `ZeroAddress()` if feeRecipient is zero address

**Example:**
```solidity
RoyaltifyMarketplace marketplace = new RoyaltifyMarketplace(
    100,              // 1% protocol fee
    treasuryAddress   // Fee recipient
);
```

---

### listNFT

```solidity
function listNFT(
    address nftContract,
    uint256 tokenId,
    uint256 price
) external nonReentrant returns (uint256 listingId)
```

Creates a new listing for an NFT.

**Parameters:**
- `nftContract`: Address of the ERC721 contract
- `tokenId`: Token ID to list
- `price`: Sale price in wei

**Returns:**
- `listingId`: ID of the created listing

**Requirements:**
- Price must be > 0
- NFT contract must support ERC721 interface
- Caller must own the NFT
- Marketplace must be approved (approve or setApprovalForAll)

**Reverts:**
- `PriceCannotBeZero()` if price is 0
- `InvalidNFTContract()` if contract doesn't support ERC721
- `NotApprovedForNFT()` if caller doesn't own or marketplace not approved

**Example:**
```solidity
// First approve marketplace
nft.approve(address(marketplace), tokenId);
// Or: nft.setApprovalForAll(address(marketplace), true);

// Then list
uint256 listingId = marketplace.listNFT(
    address(nft),
    tokenId,
    1 ether  // Price
);
```

---

### updateListing

```solidity
function updateListing(
    uint256 listingId,
    uint256 newPrice
) external nonReentrant
```

Updates the price of an existing listing.

**Parameters:**
- `listingId`: ID of the listing to update
- `newPrice`: New price in wei

**Requirements:**
- Listing must exist
- Listing must be active
- Caller must be the seller
- New price must be > 0

**Reverts:**
- `PriceCannotBeZero()` if newPrice is 0
- `ListingNotFound()` if listing doesn't exist
- `ListingNotActive()` if listing is sold/cancelled
- `NotSeller()` if caller is not the seller

**Example:**
```solidity
marketplace.updateListing(listingId, 2 ether);
```

---

### cancelListing

```solidity
function cancelListing(uint256 listingId) external nonReentrant
```

Cancels an active listing.

**Parameters:**
- `listingId`: ID of the listing to cancel

**Requirements:**
- Listing must exist
- Listing must be active
- Caller must be the seller

**Effects:**
- Sets listing status to Cancelled
- NFT remains with seller (no transfer needed)

**Reverts:**
- `ListingNotFound()` if listing doesn't exist
- `ListingNotActive()` if already sold/cancelled
- `NotSeller()` if caller is not the seller

---

### buyNFT

```solidity
function buyNFT(uint256 listingId) external payable nonReentrant
```

Purchases an NFT from an active listing.

**Parameters:**
- `listingId`: ID of the listing to buy

**Value:**
- Must send exact listing price in ETH

**Requirements:**
- Listing must exist and be active
- Buyer cannot be the seller
- Exact payment required
- Seller must still own NFT and have approval active

**Effects:**
1. Marks listing as Sold
2. Calculates payment distribution:
   - Protocol fee to fee recipient
   - Royalty to creator (via EIP-2981)
   - Remainder to seller
3. Credits proceeds to respective addresses
4. Transfers NFT to buyer

**Reverts:**
- `ListingNotFound()` if listing doesn't exist
- `ListingNotActive()` if sold/cancelled
- `CannotBuyOwnListing()` if buyer is seller
- `IncorrectPayment()` if msg.value != price

**Example:**
```solidity
marketplace.buyNFT{value: 1 ether}(listingId);
```

---

### withdrawProceeds

```solidity
function withdrawProceeds() external nonReentrant
```

Withdraws all accumulated proceeds for the caller.

**Requirements:**
- Caller must have proceeds > 0

**Effects:**
- Transfers all proceeds to caller
- Resets caller's proceeds to 0

**Reverts:**
- `NoProceeds()` if caller has no proceeds
- `TransferFailed()` if ETH transfer fails

**Example:**
```solidity
// After selling NFTs
uint256 myProceeds = marketplace.getProceeds(msg.sender);
marketplace.withdrawProceeds();
// Receives myProceeds in ETH
```

---

### setProtocolFee (Admin)

```solidity
function setProtocolFee(uint256 newFee) external onlyOwner
```

Updates the protocol fee percentage.

**Parameters:**
- `newFee`: New fee in basis points (max 500)

**Access Control:**
- Only contract owner

**Reverts:**
- `ProtocolFeeTooHigh()` if newFee > 500

---

### setProtocolFeeRecipient (Admin)

```solidity
function setProtocolFeeRecipient(address newRecipient) external onlyOwner
```

Updates the protocol fee recipient.

**Parameters:**
- `newRecipient`: New recipient address

**Access Control:**
- Only contract owner

**Reverts:**
- `ZeroAddress()` if newRecipient is zero address

---

### getListing

```solidity
function getListing(uint256 listingId) external view returns (Listing memory)
```

Returns the full listing data for a given ID.

---

### getProceeds

```solidity
function getProceeds(address user) external view returns (uint256)
```

Returns the withdrawable proceeds for a user.

---

### getActiveListings

```solidity
function getActiveListings(
    uint256 offset,
    uint256 limit
) external view returns (
    Listing[] memory listings,
    uint256[] memory listingIds
)
```

Returns paginated list of active listings.

**Parameters:**
- `offset`: Starting index
- `limit`: Maximum number of results

**Returns:**
- `listings`: Array of Listing structs
- `listingIds`: Corresponding listing IDs

---

### getListingsBySeller

```solidity
function getListingsBySeller(
    address seller
) external view returns (
    Listing[] memory listings,
    uint256[] memory listingIds
)
```

Returns all listings created by a specific seller.

---

## Payment Distribution

When an NFT is sold, the payment is distributed as follows:

```
Sale Price
    │
    ├──► Protocol Fee (e.g., 1%)
    │         │
    │         └──► protocolFeeRecipient proceeds
    │
    ├──► Creator Royalty (e.g., 5%)
    │         │
    │         └──► royaltyReceiver proceeds (from EIP-2981)
    │
    └──► Seller Proceeds (e.g., 94%)
              │
              └──► seller proceeds
```

### Calculation Example

```
Sale Price: 1 ETH (1,000,000,000,000,000,000 wei)
Protocol Fee: 1% (100 basis points)
Creator Royalty: 5% (500 basis points)

Protocol Fee Amount:  1 ETH × 100 / 10000 = 0.01 ETH
Royalty Amount:       1 ETH × 500 / 10000 = 0.05 ETH
Seller Proceeds:      1 ETH - 0.01 - 0.05 = 0.94 ETH

Result:
- Fee Recipient:    +0.01 ETH
- Creator:          +0.05 ETH
- Seller:           +0.94 ETH
```

---

## Security Features

### 1. ReentrancyGuard
All state-changing functions use the `nonReentrant` modifier:
```solidity
function buyNFT(uint256 listingId) external payable nonReentrant { ... }
```

### 2. Pull Payment Pattern
Instead of pushing ETH directly:
```solidity
// BAD: Direct transfer (vulnerable)
payable(seller).transfer(amount);

// GOOD: Pull pattern (secure)
_proceeds[seller] += amount;
// Later: seller calls withdrawProceeds()
```

### 3. Checks-Effects-Interactions (CEI)
```solidity
function buyNFT(uint256 listingId) external payable nonReentrant {
    // CHECKS
    if (listing.status != ListingStatus.Active) revert ListingNotActive();
    if (msg.value != listing.price) revert IncorrectPayment();

    // EFFECTS
    listing.status = ListingStatus.Sold;
    _proceeds[seller] += sellerProceeds;

    // INTERACTIONS (last)
    IERC721(nftContract).safeTransferFrom(seller, buyer, tokenId);
}
```

### 4. Two-Step Ownership Transfer
Uses `Ownable2Step` for safer ownership transfer:
```solidity
// Step 1: Current owner initiates transfer
marketplace.transferOwnership(newOwner);

// Step 2: New owner must accept
marketplace.acceptOwnership();
```

---

## Gas Costs (Approximate)

| Function | Gas Cost |
|----------|----------|
| listNFT | ~170,000 |
| updateListing | ~35,000 |
| cancelListing | ~30,000 |
| buyNFT | ~300,000 |
| withdrawProceeds | ~35,000 |

---

## Usage Examples

### Complete Trading Flow

```solidity
// 1. Seller approves marketplace
nft.approve(address(marketplace), tokenId);

// 2. Seller creates listing
uint256 listingId = marketplace.listNFT(
    address(nft),
    tokenId,
    1 ether
);

// 3. Buyer purchases NFT
marketplace.buyNFT{value: 1 ether}(listingId);

// 4. Seller withdraws proceeds
marketplace.withdrawProceeds();

// 5. Creator withdraws royalties
// (if creator != seller)
marketplace.withdrawProceeds(); // from creator address
```

### Querying Listings

```solidity
// Get specific listing
Listing memory listing = marketplace.getListing(0);

// Get all active listings (first 10)
(Listing[] memory listings, uint256[] memory ids) =
    marketplace.getActiveListings(0, 10);

// Get seller's listings
(Listing[] memory myListings, uint256[] memory myIds) =
    marketplace.getListingsBySeller(msg.sender);
```

### Checking Proceeds

```solidity
uint256 myProceeds = marketplace.getProceeds(msg.sender);
if (myProceeds > 0) {
    marketplace.withdrawProceeds();
}
```
