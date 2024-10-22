# RoyaltifyNFT Contract Documentation

## Overview

RoyaltifyNFT is an ERC-721 compliant NFT contract with built-in EIP-2981 royalty support. It enables creators to mint NFTs with customizable royalty percentages that are automatically enforced by compatible marketplaces.

## Contract Details

| Property | Value |
|----------|-------|
| Contract Name | RoyaltifyNFT |
| Solidity Version | ^0.8.28 |
| License | MIT |
| Inheritance | ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Ownable |

## Constants

```solidity
uint96 public constant MAX_ROYALTY_FEE = 1000;     // 10% maximum royalty
uint96 public constant DEFAULT_ROYALTY_FEE = 250;  // 2.5% default royalty
```

### Basis Points Explanation
Royalty fees are expressed in basis points where:
- 100 basis points = 1%
- 250 basis points = 2.5%
- 500 basis points = 5%
- 1000 basis points = 10%

## State Variables

| Variable | Type | Visibility | Description |
|----------|------|------------|-------------|
| `_tokenIdCounter` | uint256 | private | Auto-incrementing token ID counter |
| `_tokenCreators` | mapping(uint256 => address) | private | Maps token ID to original creator |

## Events

### Minted
```solidity
event Minted(
    address indexed creator,
    address indexed recipient,
    uint256 indexed tokenId,
    string tokenURI
);
```
Emitted when a new NFT is minted.

**Parameters:**
- `creator`: Address that called the mint function
- `recipient`: Address receiving the NFT
- `tokenId`: ID of the newly minted token
- `tokenURI`: Metadata URI for the token

### TokenRoyaltyUpdated
```solidity
event TokenRoyaltyUpdated(
    uint256 indexed tokenId,
    address indexed receiver,
    uint96 feeNumerator
);
```
Emitted when a token's royalty information is updated.

**Parameters:**
- `tokenId`: ID of the token
- `receiver`: Address that will receive royalties
- `feeNumerator`: Royalty fee in basis points

### DefaultRoyaltyUpdated
```solidity
event DefaultRoyaltyUpdated(
    address indexed receiver,
    uint96 feeNumerator
);
```
Emitted when the default royalty is updated.

## Errors

| Error | Description |
|-------|-------------|
| `NotTokenCreator()` | Caller is not the original token creator |
| `RoyaltyFeeTooHigh()` | Royalty fee exceeds MAX_ROYALTY_FEE (10%) |
| `EmptyTokenURI()` | Token URI string is empty |
| `InvalidRecipient()` | Recipient address is zero address |

## Functions

### Constructor

```solidity
constructor(
    string memory name_,
    string memory symbol_,
    address defaultRoyaltyReceiver
)
```

Deploys the contract with the given name, symbol, and default royalty receiver.

**Parameters:**
- `name_`: Collection name (e.g., "Royaltify")
- `symbol_`: Collection symbol (e.g., "RYAL")
- `defaultRoyaltyReceiver`: Address to receive default royalties

**Reverts:**
- `InvalidRecipient()` if defaultRoyaltyReceiver is zero address

**Example:**
```solidity
RoyaltifyNFT nft = new RoyaltifyNFT(
    "My NFT Collection",
    "MNFT",
    0x1234...  // Royalty receiver
);
```

---

### mint (Simple)

```solidity
function mint(string calldata tokenURI_) external returns (uint256 tokenId)
```

Mints a new NFT to the caller with default royalty settings.

**Parameters:**
- `tokenURI_`: IPFS or HTTP URI pointing to token metadata

**Returns:**
- `tokenId`: The ID of the newly minted token

**Effects:**
- Mints token to msg.sender
- Sets token URI
- Records msg.sender as creator
- Sets royalty to msg.sender at DEFAULT_ROYALTY_FEE (2.5%)

**Reverts:**
- `EmptyTokenURI()` if tokenURI_ is empty

**Example:**
```solidity
uint256 tokenId = nft.mint("ipfs://QmYourMetadataHash");
// tokenId = 0 (first mint)
// Owner = msg.sender
// Royalty receiver = msg.sender
// Royalty fee = 2.5%
```

---

### mint (Advanced)

```solidity
function mint(
    address to,
    string calldata tokenURI_,
    address royaltyReceiver,
    uint96 royaltyFeeNumerator
) external returns (uint256 tokenId)
```

Mints a new NFT with custom recipient and royalty settings.

**Parameters:**
- `to`: Address to receive the NFT
- `tokenURI_`: Metadata URI
- `royaltyReceiver`: Address to receive royalties (can be different from creator)
- `royaltyFeeNumerator`: Royalty fee in basis points (0-1000)

**Returns:**
- `tokenId`: The ID of the newly minted token

**Effects:**
- Mints token to specified address
- Sets token URI
- Records msg.sender as creator
- Sets custom royalty if royaltyReceiver != address(0) && royaltyFeeNumerator > 0

**Reverts:**
- `InvalidRecipient()` if `to` is zero address
- `EmptyTokenURI()` if tokenURI_ is empty
- `RoyaltyFeeTooHigh()` if royaltyFeeNumerator > 1000

**Example:**
```solidity
uint256 tokenId = nft.mint(
    0xBuyer...,           // Recipient
    "ipfs://QmHash",      // Metadata
    0xArtist...,          // Royalty receiver
    500                   // 5% royalty
);
```

---

### setTokenRoyalty

```solidity
function setTokenRoyalty(
    uint256 tokenId,
    address receiver,
    uint96 feeNumerator
) external
```

Updates the royalty information for a specific token. Only callable by the original creator.

**Parameters:**
- `tokenId`: Token ID to update
- `receiver`: New royalty receiver address
- `feeNumerator`: New royalty fee in basis points

**Access Control:**
- Only the original token creator can call this function

**Reverts:**
- `NotTokenCreator()` if caller is not the creator
- `RoyaltyFeeTooHigh()` if feeNumerator > 1000

**Example:**
```solidity
// Creator changes royalty receiver
nft.setTokenRoyalty(
    0,                    // Token ID
    0xNewReceiver...,     // New receiver
    750                   // 7.5% royalty
);
```

---

### setDefaultRoyalty

```solidity
function setDefaultRoyalty(
    address receiver,
    uint96 feeNumerator
) external onlyOwner
```

Updates the default royalty for new tokens that don't have custom royalties set.

**Parameters:**
- `receiver`: Default royalty receiver
- `feeNumerator`: Default royalty fee in basis points

**Access Control:**
- Only contract owner

**Reverts:**
- `RoyaltyFeeTooHigh()` if feeNumerator > 1000
- Ownable error if caller is not owner

---

### burn

```solidity
function burn(uint256 tokenId) external
```

Burns (destroys) a token. Only the token owner can burn their token.

**Parameters:**
- `tokenId`: Token ID to burn

**Effects:**
- Destroys the token
- Resets token royalty info
- Decrements total supply

**Reverts:**
- `NotTokenCreator()` if caller doesn't own the token

---

### tokenCreator

```solidity
function tokenCreator(uint256 tokenId) external view returns (address)
```

Returns the original creator of a token.

**Parameters:**
- `tokenId`: Token ID to query

**Returns:**
- Address of the original creator (minter)

**Reverts:**
- If token doesn't exist

---

### royaltyInfo

```solidity
function royaltyInfo(
    uint256 tokenId,
    uint256 salePrice
) external view returns (address receiver, uint256 royaltyAmount)
```

Returns royalty information for a token sale (EIP-2981).

**Parameters:**
- `tokenId`: Token being sold
- `salePrice`: Sale price in wei

**Returns:**
- `receiver`: Address to receive royalty payment
- `royaltyAmount`: Amount to pay in wei

**Example:**
```solidity
(address receiver, uint256 amount) = nft.royaltyInfo(0, 1 ether);
// If royalty is 5%:
// receiver = creator address
// amount = 0.05 ether
```

---

### supportsInterface

```solidity
function supportsInterface(bytes4 interfaceId) public view returns (bool)
```

Returns true if the contract supports the given interface.

**Supported Interfaces:**
- `IERC721`: 0x80ac58cd
- `IERC721Metadata`: 0x5b5e139f
- `IERC721Enumerable`: 0x780e9d63
- `IERC2981`: 0x2a55205a
- `IERC165`: 0x01ffc9a7

---

## Enumerable Functions

### totalSupply
```solidity
function totalSupply() public view returns (uint256)
```
Returns the total number of tokens in existence.

### tokenByIndex
```solidity
function tokenByIndex(uint256 index) public view returns (uint256)
```
Returns the token ID at a given index of all tokens.

### tokenOfOwnerByIndex
```solidity
function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256)
```
Returns the token ID at a given index of tokens owned by an address.

---

## Usage Examples

### Basic Minting
```solidity
// Deploy contract
RoyaltifyNFT nft = new RoyaltifyNFT("MyNFT", "MNFT", msg.sender);

// Simple mint (caller gets NFT, 2.5% royalty to caller)
uint256 tokenId = nft.mint("ipfs://QmMetadataHash");
```

### Minting for Another Address
```solidity
// Mint to buyer with custom royalty
uint256 tokenId = nft.mint(
    buyerAddress,
    "ipfs://QmMetadataHash",
    artistAddress,  // Royalty goes to artist
    500             // 5% royalty
);
```

### Checking Royalty Info
```solidity
// For a 1 ETH sale
(address receiver, uint256 royalty) = nft.royaltyInfo(tokenId, 1 ether);
// receiver: artist address
// royalty: 0.05 ether (5%)
```

### Updating Royalty (Creator Only)
```solidity
// Only original creator can update
nft.setTokenRoyalty(tokenId, newReceiverAddress, 300); // 3%
```

### Burning a Token
```solidity
// Only token owner can burn
nft.burn(tokenId);
```

---

## Metadata Schema

Token metadata should follow the ERC-721 metadata standard:

```json
{
    "name": "Token Name",
    "description": "Token description",
    "image": "ipfs://QmImageHash",
    "attributes": [
        {
            "trait_type": "Background",
            "value": "Blue"
        },
        {
            "trait_type": "Rarity",
            "value": "Legendary"
        }
    ]
}
```

---

## Gas Costs (Approximate)

| Function | Gas Cost |
|----------|----------|
| mint (simple) | ~190,000 |
| mint (advanced) | ~195,000 |
| setTokenRoyalty | ~30,000 |
| burn | ~50,000 |
| transferFrom | ~65,000 |
| approve | ~45,000 |

*Gas costs vary based on network conditions and state changes.*
