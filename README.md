# Royaltify

A modern NFT marketplace supporting ERC-721 tokens with built-in creator royalties (EIP-2981). Enables minting, buying, selling, and royalty distribution with reentrancy-safe trade mechanics.

## Features

### RoyaltifyNFT
- **ERC-721 Compliant** - Full NFT standard support with metadata
- **EIP-2981 Royalties** - On-chain royalty information for marketplaces
- **Per-Token Royalties** - Customizable royalty per token (max 10%)
- **Creator Tracking** - Immutable creator record for each token
- **Enumerable** - On-chain token discovery support
- **Burnable** - Token owners can burn their NFTs

### RoyaltifyMarketplace
- **Fixed-Price Listings** - List NFTs at a set price
- **Automatic Royalty Distribution** - EIP-2981 royalties paid automatically
- **Protocol Fees** - Configurable marketplace fee (max 5%)
- **Reentrancy Protection** - OpenZeppelin ReentrancyGuard on all functions
- **Pull Payment Pattern** - Secure withdraw mechanism for proceeds
- **Two-Step Ownership** - Safe ownership transfer for admin functions

## Tech Stack

- **Solidity** 0.8.28 (latest stable)
- **Foundry** - Development framework
- **OpenZeppelin** v5.5.0 - Battle-tested contract libraries
- **EVM** Cancun - Latest EVM version with modern opcodes

## Project Structure

```
royaltify/
├── src/
│   ├── RoyaltifyNFT.sol          # ERC-721 + EIP-2981 NFT contract
│   ├── RoyaltifyMarketplace.sol  # Marketplace with royalty enforcement
│   └── interfaces/
│       ├── IRoyaltifyNFT.sol
│       └── IRoyaltifyMarketplace.sol
├── test/
│   ├── RoyaltifyNFT.t.sol        # NFT contract tests
│   └── RoyaltifyMarketplace.t.sol # Marketplace tests
├── script/
│   └── Deploy.s.sol              # Deployment scripts
└── foundry.toml                  # Foundry configuration
```

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

```bash
# Clone the repository
git clone https://github.com/atahabilder1/royaltify.git
cd royaltify

# Install dependencies
forge install

# Build contracts
forge build
```

### Testing

```bash
# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run tests with gas reporting
forge test --gas-report

# Run fuzz tests with more iterations
forge test --fuzz-runs 1000

# Run coverage
forge coverage
```

### Deployment

1. Copy `.env.example` to `.env` and fill in your values:
```bash
cp .env.example .env
```

2. Deploy to local network:
```bash
forge script script/Deploy.s.sol:DeployLocal --fork-url http://localhost:8545 --broadcast
```

3. Deploy to Sepolia testnet:
```bash
forge script script/Deploy.s.sol:DeploySepolia \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```

4. Deploy to mainnet:
```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify
```

## Contract Addresses

| Network | RoyaltifyNFT | RoyaltifyMarketplace |
|---------|--------------|----------------------|
| Sepolia | TBD          | TBD                  |
| Mainnet | TBD          | TBD                  |

## Usage

### Minting NFTs

```solidity
// Simple mint (creator receives royalties)
uint256 tokenId = nft.mint("ipfs://your-metadata-uri");

// Advanced mint with custom royalty recipient
uint256 tokenId = nft.mint(
    recipientAddress,
    "ipfs://your-metadata-uri",
    royaltyReceiverAddress,
    500 // 5% royalty
);
```

### Listing and Buying

```solidity
// Approve marketplace
nft.approve(address(marketplace), tokenId);

// List NFT for sale
uint256 listingId = marketplace.listNFT(address(nft), tokenId, 1 ether);

// Buy NFT (royalties distributed automatically)
marketplace.buyNFT{value: 1 ether}(listingId);

// Withdraw proceeds
marketplace.withdrawProceeds();
```

## Security

### Audit Status
- [ ] Internal review completed
- [ ] External audit pending

### Security Features
- ReentrancyGuard on all state-changing functions
- Pull payment pattern for ETH withdrawals
- Checks-Effects-Interactions pattern
- Two-step ownership transfer
- Maximum fee caps (10% royalty, 5% protocol fee)
- Input validation and custom errors

## Gas Optimization

The contracts are optimized for gas efficiency:
- Solidity optimizer enabled (200 runs)
- `via_ir` compilation for better optimization
- Custom errors instead of require strings
- Efficient storage packing

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [OpenZeppelin](https://openzeppelin.com/) for secure contract libraries
- [Foundry](https://github.com/foundry-rs/foundry) for the development framework
- [EIP-2981](https://eips.ethereum.org/EIPS/eip-2981) NFT Royalty Standard
