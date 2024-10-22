# API Reference

Complete function reference for all Royaltify contracts.

## Table of Contents
- [RoyaltifyNFT](#royaltifynft)
- [RoyaltifyMarketplace](#royaltifymarketplace)
- [Interfaces](#interfaces)

---

## RoyaltifyNFT

### Write Functions

#### mint(string)
```solidity
function mint(string calldata tokenURI_) external returns (uint256 tokenId)
```
Mints NFT to caller with default 2.5% royalty.

| Parameter | Type | Description |
|-----------|------|-------------|
| tokenURI_ | string | Metadata URI |

| Returns | Type | Description |
|---------|------|-------------|
| tokenId | uint256 | Minted token ID |

---

#### mint(address,string,address,uint96)
```solidity
function mint(
    address to,
    string calldata tokenURI_,
    address royaltyReceiver,
    uint96 royaltyFeeNumerator
) external returns (uint256 tokenId)
```
Mints NFT with custom recipient and royalty settings.

| Parameter | Type | Description |
|-----------|------|-------------|
| to | address | NFT recipient |
| tokenURI_ | string | Metadata URI |
| royaltyReceiver | address | Royalty recipient |
| royaltyFeeNumerator | uint96 | Royalty in basis points (max 1000) |

---

#### setTokenRoyalty
```solidity
function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
) external
```
Updates token royalty. Creator only.

| Parameter | Type | Description |
|-----------|------|-------------|
| tokenId | uint256 | Token to update |
| receiver | address | New royalty receiver |
| feeNumerator | uint96 | New royalty fee |

---

#### setDefaultRoyalty
```solidity
function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
) external onlyOwner
```
Updates default royalty. Owner only.

---

#### burn
```solidity
function burn(uint256 tokenId) external
```
Burns token. Owner only.

---

#### approve
```solidity
function approve(address to, uint256 tokenId) external
```
Approves address to transfer token.

---

#### setApprovalForAll
```solidity
function setApprovalForAll(address operator, bool approved) external
```
Approves operator for all tokens.

---

#### transferFrom
```solidity
function transferFrom(address from, address to, uint256 tokenId) external
```
Transfers token.

---

#### safeTransferFrom
```solidity
function safeTransferFrom(address from, address to, uint256 tokenId) external
function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external
```
Safely transfers token with receiver check.

---

### Read Functions

#### tokenCreator
```solidity
function tokenCreator(uint256 tokenId) external view returns (address)
```
Returns original creator of token.

---

#### royaltyInfo
```solidity
function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
) external view returns (address receiver, uint256 royaltyAmount)
```
Returns royalty info for sale price (EIP-2981).

---

#### ownerOf
```solidity
function ownerOf(uint256 tokenId) external view returns (address)
```
Returns current owner of token.

---

#### balanceOf
```solidity
function balanceOf(address owner) external view returns (uint256)
```
Returns token count for owner.

---

#### tokenURI
```solidity
function tokenURI(uint256 tokenId) external view returns (string memory)
```
Returns metadata URI.

---

#### totalSupply
```solidity
function totalSupply() external view returns (uint256)
```
Returns total tokens in existence.

---

#### tokenByIndex
```solidity
function tokenByIndex(uint256 index) external view returns (uint256)
```
Returns token ID at global index.

---

#### tokenOfOwnerByIndex
```solidity
function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256)
```
Returns token ID at owner's index.

---

#### getApproved
```solidity
function getApproved(uint256 tokenId) external view returns (address)
```
Returns approved address for token.

---

#### isApprovedForAll
```solidity
function isApprovedForAll(address owner, address operator) external view returns (bool)
```
Returns if operator is approved for owner.

---

#### supportsInterface
```solidity
function supportsInterface(bytes4 interfaceId) external view returns (bool)
```
Returns if interface is supported.

| Interface | ID |
|-----------|-----|
| IERC721 | 0x80ac58cd |
| IERC721Metadata | 0x5b5e139f |
| IERC721Enumerable | 0x780e9d63 |
| IERC2981 | 0x2a55205a |
| IERC165 | 0x01ffc9a7 |

---

#### name
```solidity
function name() external view returns (string memory)
```
Returns collection name.

---

#### symbol
```solidity
function symbol() external view returns (string memory)
```
Returns collection symbol.

---

#### owner
```solidity
function owner() external view returns (address)
```
Returns contract owner.

---

#### MAX_ROYALTY_FEE
```solidity
function MAX_ROYALTY_FEE() external view returns (uint96)
```
Returns maximum royalty (1000 = 10%).

---

#### DEFAULT_ROYALTY_FEE
```solidity
function DEFAULT_ROYALTY_FEE() external view returns (uint96)
```
Returns default royalty (250 = 2.5%).

---

## RoyaltifyMarketplace

### Write Functions

#### listNFT
```solidity
function listNFT(
    address nftContract,
    uint256 tokenId,
    uint256 price
) external returns (uint256 listingId)
```
Creates NFT listing.

| Parameter | Type | Description |
|-----------|------|-------------|
| nftContract | address | NFT contract address |
| tokenId | uint256 | Token ID to list |
| price | uint256 | Price in wei |

---

#### updateListing
```solidity
function updateListing(uint256 listingId, uint256 newPrice) external
```
Updates listing price. Seller only.

---

#### cancelListing
```solidity
function cancelListing(uint256 listingId) external
```
Cancels listing. Seller only.

---

#### buyNFT
```solidity
function buyNFT(uint256 listingId) external payable
```
Purchases NFT. Send exact price as value.

---

#### withdrawProceeds
```solidity
function withdrawProceeds() external
```
Withdraws accumulated proceeds.

---

#### setProtocolFee
```solidity
function setProtocolFee(uint256 newFee) external onlyOwner
```
Updates protocol fee. Owner only. Max 500 (5%).

---

#### setProtocolFeeRecipient
```solidity
function setProtocolFeeRecipient(address newRecipient) external onlyOwner
```
Updates fee recipient. Owner only.

---

#### transferOwnership
```solidity
function transferOwnership(address newOwner) external onlyOwner
```
Initiates ownership transfer (2-step).

---

#### acceptOwnership
```solidity
function acceptOwnership() external
```
Accepts pending ownership transfer.

---

### Read Functions

#### getListing
```solidity
function getListing(uint256 listingId) external view returns (Listing memory)
```
Returns listing details.

**Listing Struct:**
```solidity
struct Listing {
    address seller;
    address nftContract;
    uint256 tokenId;
    uint256 price;
    ListingStatus status;  // 0=Active, 1=Sold, 2=Cancelled
    uint256 listedAt;
}
```

---

#### getProceeds
```solidity
function getProceeds(address user) external view returns (uint256)
```
Returns withdrawable proceeds for user.

---

#### getActiveListings
```solidity
function getActiveListings(
    uint256 offset,
    uint256 limit
) external view returns (Listing[] memory, uint256[] memory)
```
Returns paginated active listings with IDs.

---

#### getListingsBySeller
```solidity
function getListingsBySeller(
    address seller
) external view returns (Listing[] memory, uint256[] memory)
```
Returns all listings by seller.

---

#### listingCount
```solidity
function listingCount() external view returns (uint256)
```
Returns total listings created.

---

#### protocolFee
```solidity
function protocolFee() external view returns (uint256)
```
Returns current protocol fee in basis points.

---

#### protocolFeeRecipient
```solidity
function protocolFeeRecipient() external view returns (address)
```
Returns protocol fee recipient.

---

#### owner
```solidity
function owner() external view returns (address)
```
Returns contract owner.

---

#### pendingOwner
```solidity
function pendingOwner() external view returns (address)
```
Returns pending owner (2-step transfer).

---

#### MAX_PROTOCOL_FEE
```solidity
function MAX_PROTOCOL_FEE() external view returns (uint256)
```
Returns maximum protocol fee (500 = 5%).

---

## Interfaces

### IRoyaltifyNFT

```solidity
interface IRoyaltifyNFT {
    // Events
    event Minted(address indexed creator, address indexed recipient, uint256 indexed tokenId, string tokenURI);
    event TokenRoyaltyUpdated(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event DefaultRoyaltyUpdated(address indexed receiver, uint96 feeNumerator);

    // Errors
    error NotTokenCreator();
    error RoyaltyFeeTooHigh();
    error EmptyTokenURI();
    error InvalidRecipient();

    // Functions
    function mint(address to, string calldata tokenURI_, address royaltyReceiver, uint96 royaltyFeeNumerator) external returns (uint256);
    function mint(string calldata tokenURI_) external returns (uint256);
    function tokenCreator(uint256 tokenId) external view returns (address);
    function MAX_ROYALTY_FEE() external view returns (uint96);
}
```

### IRoyaltifyMarketplace

```solidity
interface IRoyaltifyMarketplace {
    // Enums
    enum ListingStatus { Active, Sold, Cancelled }

    // Structs
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        ListingStatus status;
        uint256 listedAt;
    }

    // Events
    event Listed(uint256 indexed listingId, address indexed seller, address indexed nftContract, uint256 tokenId, uint256 price);
    event ListingUpdated(uint256 indexed listingId, uint256 oldPrice, uint256 newPrice);
    event ListingCancelled(uint256 indexed listingId);
    event Sale(uint256 indexed listingId, address indexed buyer, address indexed seller, address nftContract, uint256 tokenId, uint256 price, uint256 royaltyAmount, address royaltyReceiver);
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);
    event ProtocolFeeRecipientUpdated(address oldRecipient, address newRecipient);
    event ProceedsWithdrawn(address indexed user, uint256 amount);

    // Errors
    error PriceCannotBeZero();
    error ListingNotFound();
    error ListingNotActive();
    error NotSeller();
    error CannotBuyOwnListing();
    error IncorrectPayment();
    error InvalidNFTContract();
    error NotApprovedForNFT();
    error ProtocolFeeTooHigh();
    error NoProceeds();
    error TransferFailed();
    error ZeroAddress();

    // Functions
    function listNFT(address nftContract, uint256 tokenId, uint256 price) external returns (uint256);
    function updateListing(uint256 listingId, uint256 newPrice) external;
    function cancelListing(uint256 listingId) external;
    function buyNFT(uint256 listingId) external payable;
    function withdrawProceeds() external;
    function getListing(uint256 listingId) external view returns (Listing memory);
    function getProceeds(address user) external view returns (uint256);
    function listingCount() external view returns (uint256);
    function protocolFee() external view returns (uint256);
    function protocolFeeRecipient() external view returns (address);
}
```

---

## Error Codes Quick Reference

### RoyaltifyNFT Errors
| Error | Selector | Description |
|-------|----------|-------------|
| NotTokenCreator | 0x... | Caller is not the original creator |
| RoyaltyFeeTooHigh | 0x... | Fee exceeds 10% |
| EmptyTokenURI | 0x... | URI cannot be empty |
| InvalidRecipient | 0x... | Address is zero |

### RoyaltifyMarketplace Errors
| Error | Selector | Description |
|-------|----------|-------------|
| PriceCannotBeZero | 0x... | Price must be > 0 |
| ListingNotFound | 0x... | Invalid listing ID |
| ListingNotActive | 0x... | Listing is sold/cancelled |
| NotSeller | 0x... | Caller is not seller |
| CannotBuyOwnListing | 0x... | Self-purchase not allowed |
| IncorrectPayment | 0x... | Wrong ETH amount |
| InvalidNFTContract | 0x... | Not ERC721 |
| NotApprovedForNFT | 0x... | No approval |
| ProtocolFeeTooHigh | 0x... | Fee exceeds 5% |
| NoProceeds | 0x... | Nothing to withdraw |
| TransferFailed | 0x... | ETH transfer failed |
| ZeroAddress | 0x... | Address is zero |
