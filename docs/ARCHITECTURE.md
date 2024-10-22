# Architecture Overview

This document describes the overall architecture of the Royaltify NFT marketplace system.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              ROYALTIFY ECOSYSTEM                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────────────┐         ┌─────────────────────────────────────┐   │
│  │                     │         │                                     │   │
│  │   RoyaltifyNFT      │◄───────►│      RoyaltifyMarketplace           │   │
│  │                     │         │                                     │   │
│  │  ┌───────────────┐  │         │  ┌─────────────────────────────┐   │   │
│  │  │ ERC-721       │  │         │  │ Listing Management          │   │   │
│  │  │ ERC-721Enum   │  │         │  │ - Create listings           │   │   │
│  │  │ ERC-721URI    │  │         │  │ - Update prices             │   │   │
│  │  │ EIP-2981      │  │         │  │ - Cancel listings           │   │   │
│  │  │ Ownable       │  │         │  └─────────────────────────────┘   │   │
│  │  └───────────────┘  │         │                                     │   │
│  │                     │         │  ┌─────────────────────────────┐   │   │
│  │  ┌───────────────┐  │         │  │ Trading Engine              │   │   │
│  │  │ Mint Tokens   │  │         │  │ - Execute purchases         │   │   │
│  │  │ Set Royalties │  │         │  │ - Distribute royalties      │   │   │
│  │  │ Track Creators│  │         │  │ - Collect protocol fees     │   │   │
│  │  │ Burn Tokens   │  │         │  └─────────────────────────────┘   │   │
│  │  └───────────────┘  │         │                                     │   │
│  │                     │         │  ┌─────────────────────────────┐   │   │
│  └─────────────────────┘         │  │ Payment System              │   │   │
│                                  │  │ - Pull payment pattern      │   │   │
│                                  │  │ - Proceeds tracking         │   │   │
│                                  │  │ - Secure withdrawals        │   │   │
│                                  │  └─────────────────────────────┘   │   │
│                                  │                                     │   │
│                                  └─────────────────────────────────────┘   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Contract Relationships

### Inheritance Hierarchy

#### RoyaltifyNFT
```
                    ┌──────────────┐
                    │   ERC721     │
                    └──────┬───────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
┌──────────────────┐ ┌──────────────┐ ┌──────────────┐
│ ERC721Enumerable │ │ERC721URIStore│ │   ERC2981    │
└────────┬─────────┘ └──────┬───────┘ └──────┬───────┘
         │                  │                │
         └──────────────────┼────────────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │    Ownable      │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ IRoyaltifyNFT   │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │  RoyaltifyNFT   │
                  └─────────────────┘
```

#### RoyaltifyMarketplace
```
         ┌──────────────────┐     ┌──────────────────┐
         │ ReentrancyGuard  │     │   Ownable2Step   │
         └────────┬─────────┘     └────────┬─────────┘
                  │                        │
                  └───────────┬────────────┘
                              │
                              ▼
                 ┌────────────────────────┐
                 │ IRoyaltifyMarketplace  │
                 └───────────┬────────────┘
                             │
                             ▼
                 ┌────────────────────────┐
                 │  RoyaltifyMarketplace  │
                 └────────────────────────┘
```

## Data Flow

### Minting Flow
```
User                    RoyaltifyNFT                    Blockchain
 │                           │                              │
 │  mint(uri, royalty)       │                              │
 │──────────────────────────►│                              │
 │                           │  _safeMint()                 │
 │                           │─────────────────────────────►│
 │                           │  _setTokenURI()              │
 │                           │─────────────────────────────►│
 │                           │  _setTokenRoyalty()          │
 │                           │─────────────────────────────►│
 │                           │  Store creator               │
 │                           │─────────────────────────────►│
 │  tokenId                  │                              │
 │◄──────────────────────────│                              │
 │                           │                              │
```

### Trading Flow
```
Seller              Marketplace              NFT Contract           Buyer
  │                      │                        │                   │
  │ approve(marketplace) │                        │                   │
  │─────────────────────────────────────────────►│                   │
  │                      │                        │                   │
  │ listNFT(nft,id,price)│                        │                   │
  │─────────────────────►│                        │                   │
  │                      │ verify ownership       │                   │
  │                      │───────────────────────►│                   │
  │  listingId           │                        │                   │
  │◄─────────────────────│                        │                   │
  │                      │                        │                   │
  │                      │                        │  buyNFT{value}    │
  │                      │◄───────────────────────────────────────────│
  │                      │                        │                   │
  │                      │ royaltyInfo(id,price)  │                   │
  │                      │───────────────────────►│                   │
  │                      │ (receiver, amount)     │                   │
  │                      │◄───────────────────────│                   │
  │                      │                        │                   │
  │                      │ Calculate distribution │                   │
  │                      │ - Seller proceeds      │                   │
  │                      │ - Royalty amount       │                   │
  │                      │ - Protocol fee         │                   │
  │                      │                        │                   │
  │                      │ safeTransferFrom       │                   │
  │                      │───────────────────────►│                   │
  │                      │                        │──────────────────►│
  │                      │                        │   NFT transferred │
  │                      │                        │                   │
```

### Payment Distribution Flow
```
Sale Price: 1 ETH
├── Protocol Fee (1%): 0.01 ETH → Fee Recipient proceeds
├── Creator Royalty (5%): 0.05 ETH → Creator proceeds
└── Seller Proceeds (94%): 0.94 ETH → Seller proceeds

                    ┌─────────────────┐
                    │   Sale: 1 ETH   │
                    └────────┬────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│  Protocol Fee   │ │ Creator Royalty │ │ Seller Proceeds │
│    0.01 ETH     │ │    0.05 ETH     │ │    0.94 ETH     │
└────────┬────────┘ └────────┬────────┘ └────────┬────────┘
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ _proceeds[fee]  │ │_proceeds[creator]│ │_proceeds[seller]│
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
                             ▼
                   ┌─────────────────┐
                   │withdrawProceeds()│
                   └─────────────────┘
```

## State Management

### RoyaltifyNFT State
```solidity
// Token ID counter
uint256 private _tokenIdCounter;

// Creator tracking
mapping(uint256 tokenId => address creator) private _tokenCreators;

// Inherited state from ERC721
mapping(uint256 => address) private _owners;
mapping(address => uint256) private _balances;
mapping(uint256 => address) private _tokenApprovals;
mapping(address => mapping(address => bool)) private _operatorApprovals;

// Inherited state from ERC721URIStorage
mapping(uint256 tokenId => string) private _tokenURIs;

// Inherited state from ERC2981
struct RoyaltyInfo {
    address receiver;
    uint96 royaltyFraction;
}
RoyaltyInfo private _defaultRoyaltyInfo;
mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;
```

### RoyaltifyMarketplace State
```solidity
// Configuration
uint256 public protocolFee;          // Fee in basis points
address public protocolFeeRecipient; // Fee recipient address

// Listing management
uint256 public listingCount;         // Total listings created
mapping(uint256 listingId => Listing) private _listings;

// Payment tracking
mapping(address user => uint256 proceeds) private _proceeds;

// Listing structure
struct Listing {
    address seller;      // NFT owner
    address nftContract; // NFT contract address
    uint256 tokenId;     // Token ID
    uint256 price;       // Listing price in wei
    ListingStatus status;// Active, Sold, or Cancelled
    uint256 listedAt;    // Timestamp
}
```

## Gas Optimization Strategies

### 1. Storage Packing
```solidity
// Listing struct is packed efficiently
struct Listing {
    address seller;      // 20 bytes
    address nftContract; // 20 bytes (new slot)
    uint256 tokenId;     // 32 bytes (new slot)
    uint256 price;       // 32 bytes (new slot)
    ListingStatus status;// 1 byte
    uint256 listedAt;    // 32 bytes (new slot)
}
```

### 2. Custom Errors
```solidity
// Gas efficient (no string storage)
error PriceCannotBeZero();
error ListingNotFound();
error NotSeller();

// vs. traditional require (stores string)
require(price > 0, "Price cannot be zero"); // More expensive
```

### 3. Unchecked Arithmetic
Where overflow is impossible (e.g., loop counters), unchecked blocks save gas:
```solidity
unchecked {
    ++i; // Saves ~60 gas per iteration
}
```

### 4. Compiler Optimizations
```toml
[profile.default]
optimizer = true
optimizer_runs = 200
via_ir = true        # Enables Yul IR pipeline
evm_version = "cancun" # Latest opcodes
```

## Security Architecture

### Defense in Depth
```
┌─────────────────────────────────────────────────────────────┐
│                    Security Layers                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Layer 1: Access Control                                    │
│  ├── Ownable/Ownable2Step for admin functions              │
│  ├── Creator-only royalty updates                          │
│  └── Owner-only token burns                                │
│                                                             │
│  Layer 2: Reentrancy Protection                            │
│  ├── ReentrancyGuard on all external functions             │
│  └── nonReentrant modifier                                 │
│                                                             │
│  Layer 3: CEI Pattern                                       │
│  ├── Checks: Validate all inputs first                     │
│  ├── Effects: Update state before external calls           │
│  └── Interactions: External calls last                     │
│                                                             │
│  Layer 4: Pull Payment Pattern                             │
│  ├── No direct ETH transfers on buy                        │
│  ├── Accumulate proceeds in mapping                        │
│  └── Users withdraw their own funds                        │
│                                                             │
│  Layer 5: Input Validation                                 │
│  ├── Zero address checks                                   │
│  ├── Price validation                                      │
│  ├── Fee cap enforcement                                   │
│  └── Interface verification (ERC165)                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Upgrade Considerations

The current contracts are **non-upgradeable** by design for simplicity and security. For future upgradeable versions, consider:

1. **Proxy Patterns**: UUPS or Transparent Proxy
2. **Storage Gaps**: Reserve storage slots for future variables
3. **Initializers**: Replace constructors with initialize functions

## Network Compatibility

The contracts are compatible with:
- Ethereum Mainnet
- Ethereum Sepolia (testnet)
- Base
- Arbitrum
- Optimism
- Polygon
- Any EVM-compatible chain supporting Cancun opcodes
