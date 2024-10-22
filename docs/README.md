# Royaltify Documentation

Welcome to the Royaltify documentation. This documentation provides comprehensive details about the NFT marketplace system with built-in creator royalties.

## Table of Contents

1. [Architecture Overview](./ARCHITECTURE.md) - System design and contract interactions
2. [RoyaltifyNFT Contract](./ROYALTIFY_NFT.md) - ERC-721 NFT with EIP-2981 royalties
3. [RoyaltifyMarketplace Contract](./ROYALTIFY_MARKETPLACE.md) - Marketplace with royalty enforcement
4. [API Reference](./API_REFERENCE.md) - Complete function reference
5. [Security](./SECURITY.md) - Security model and considerations
6. [Deployment Guide](./DEPLOYMENT.md) - How to deploy contracts
7. [Testing Guide](./TESTING.md) - Running and writing tests
8. [Integration Guide](./INTEGRATION.md) - Integrating with frontend/backend

## Quick Links

- **GitHub Repository**: https://github.com/atahabilder1/royaltify
- **EIP-2981 Standard**: https://eips.ethereum.org/EIPS/eip-2981
- **OpenZeppelin Docs**: https://docs.openzeppelin.com/contracts/5.x/

## Project Overview

Royaltify is a decentralized NFT marketplace that enforces creator royalties on-chain using the EIP-2981 standard. The system consists of two main contracts:

### RoyaltifyNFT
An ERC-721 compliant NFT contract with:
- Built-in EIP-2981 royalty support
- Per-token customizable royalties (up to 10%)
- Creator tracking for provenance
- Enumerable extension for on-chain discovery

### RoyaltifyMarketplace
A secure marketplace contract with:
- Fixed-price NFT listings
- Automatic royalty distribution
- Protocol fee support (up to 5%)
- Reentrancy-safe trade mechanics
- Pull payment pattern for withdrawals

## Standards Compliance

| Standard | Description | Implementation |
|----------|-------------|----------------|
| ERC-721 | NFT Standard | Full compliance via OpenZeppelin |
| ERC-165 | Interface Detection | Supported for all interfaces |
| EIP-2981 | NFT Royalty Standard | Per-token and default royalties |
| ERC-721Enumerable | Token Enumeration | On-chain token discovery |
| ERC-721URIStorage | Metadata Storage | Per-token URI storage |

## Version Information

| Component | Version |
|-----------|---------|
| Solidity | 0.8.28 |
| OpenZeppelin Contracts | 5.5.0 |
| Foundry | Latest |
| EVM Target | Cancun |

## License

This project is licensed under the MIT License.
