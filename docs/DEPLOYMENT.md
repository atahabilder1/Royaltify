# Deployment Guide

Complete guide for deploying Royaltify contracts to various networks.

## Prerequisites

1. **Foundry** installed ([Installation Guide](https://book.getfoundry.sh/getting-started/installation))
2. **ETH** for gas fees on target network
3. **RPC URL** for target network
4. **Private key** for deployer account

## Environment Setup

### 1. Create Environment File

```bash
cp .env.example .env
```

### 2. Configure Variables

Edit `.env`:
```bash
# Deployer private key (without 0x prefix)
PRIVATE_KEY=your_private_key_here

# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY
BASE_RPC_URL=https://mainnet.base.org

# Etherscan API key for verification
ETHERSCAN_API_KEY=your_etherscan_api_key

# Optional: Override fee recipient (defaults to deployer)
FEE_RECIPIENT=0x...
```

### 3. Load Environment

```bash
source .env
```

---

## Deployment Scripts

### Available Scripts

| Script | Network | Description |
|--------|---------|-------------|
| `Deploy` | Any | Generic deployment with env config |
| `DeployLocal` | Local | Anvil/Hardhat local deployment |
| `DeploySepolia` | Sepolia | Testnet deployment |

### Script Location
```
script/Deploy.s.sol
```

---

## Local Deployment

### 1. Start Local Node

```bash
# Terminal 1: Start Anvil
anvil
```

### 2. Deploy

```bash
# Terminal 2: Deploy
forge script script/Deploy.s.sol:DeployLocal \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Expected Output
```
== Logs ==
  Local deployment with test account: 0xf39Fd6...
  RoyaltifyNFT: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  RoyaltifyMarketplace: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

---

## Testnet Deployment (Sepolia)

### 1. Get Testnet ETH

- [Sepolia Faucet](https://sepoliafaucet.com/)
- [Alchemy Faucet](https://sepoliafaucet.com/)

### 2. Verify Balance

```bash
cast balance $DEPLOYER_ADDRESS --rpc-url $SEPOLIA_RPC_URL
```

### 3. Deploy

```bash
forge script script/Deploy.s.sol:DeploySepolia \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### 4. Verify Manually (if needed)

```bash
# RoyaltifyNFT
forge verify-contract \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(string,string,address)" "Royaltify" "RYAL" $FEE_RECIPIENT) \
  $NFT_ADDRESS \
  src/RoyaltifyNFT.sol:RoyaltifyNFT

# RoyaltifyMarketplace
forge verify-contract \
  --chain sepolia \
  --constructor-args $(cast abi-encode "constructor(uint256,address)" 100 $FEE_RECIPIENT) \
  $MARKETPLACE_ADDRESS \
  src/RoyaltifyMarketplace.sol:RoyaltifyMarketplace
```

---

## Mainnet Deployment

### Pre-Deployment Checklist

- [ ] All tests passing
- [ ] Code reviewed
- [ ] Gas estimates acceptable
- [ ] Sufficient ETH for deployment
- [ ] Fee recipient address confirmed
- [ ] Protocol fee percentage confirmed

### 1. Dry Run

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MAINNET_RPC_URL \
  -vvvv
# Note: No --broadcast flag
```

### 2. Estimate Gas

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MAINNET_RPC_URL \
  --gas-estimate
```

### 3. Deploy

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  --slow \
  -vvvv
```

### 4. Save Deployment Info

Record the deployed addresses:
```bash
# Update README.md Contract Addresses table
# Save to deployments/mainnet.json
```

---

## Multi-Chain Deployment

### Base

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $BASE_RPC_URL \
  --broadcast \
  --verify \
  --verifier-url https://api.basescan.org/api
```

### Arbitrum

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $ARBITRUM_RPC_URL \
  --broadcast \
  --verify \
  --verifier-url https://api.arbiscan.io/api
```

### Polygon

```bash
forge script script/Deploy.s.sol:Deploy \
  --rpc-url $POLYGON_RPC_URL \
  --broadcast \
  --verify \
  --verifier-url https://api.polygonscan.com/api
```

---

## Constructor Arguments

### RoyaltifyNFT

```solidity
constructor(
    string memory name_,           // "Royaltify"
    string memory symbol_,         // "RYAL"
    address defaultRoyaltyReceiver // Fee recipient or treasury
)
```

### RoyaltifyMarketplace

```solidity
constructor(
    uint256 initialFee,    // 100 = 1% protocol fee
    address feeRecipient   // Fee recipient or treasury
)
```

---

## Post-Deployment

### 1. Verify Contracts on Block Explorer

Ensure both contracts show as verified with source code.

### 2. Test Basic Operations

```bash
# Check NFT contract
cast call $NFT_ADDRESS "name()" --rpc-url $RPC_URL
cast call $NFT_ADDRESS "symbol()" --rpc-url $RPC_URL
cast call $NFT_ADDRESS "owner()" --rpc-url $RPC_URL

# Check Marketplace contract
cast call $MARKETPLACE_ADDRESS "protocolFee()" --rpc-url $RPC_URL
cast call $MARKETPLACE_ADDRESS "protocolFeeRecipient()" --rpc-url $RPC_URL
```

### 3. Mint Test Token

```bash
cast send $NFT_ADDRESS \
  "mint(string)" \
  "ipfs://QmTestMetadata" \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

### 4. Create Test Listing

```bash
# Approve marketplace
cast send $NFT_ADDRESS \
  "approve(address,uint256)" \
  $MARKETPLACE_ADDRESS \
  0 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL

# Create listing
cast send $MARKETPLACE_ADDRESS \
  "listNFT(address,uint256,uint256)" \
  $NFT_ADDRESS \
  0 \
  1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $RPC_URL
```

---

## Deployment Costs

### Estimated Gas Usage

| Contract | Gas | Cost @ 30 gwei |
|----------|-----|----------------|
| RoyaltifyNFT | ~3,500,000 | ~0.105 ETH |
| RoyaltifyMarketplace | ~2,000,000 | ~0.060 ETH |
| **Total** | ~5,500,000 | **~0.165 ETH** |

*Costs vary based on network congestion and gas prices.*

---

## Troubleshooting

### "Insufficient funds"
- Check deployer balance: `cast balance $ADDRESS`
- Ensure enough ETH for gas

### "Verification failed"
- Wait a few blocks and retry
- Check constructor arguments match exactly
- Ensure compiler settings match

### "Nonce too low"
- Check pending transactions
- Use `--slow` flag for sequential deployment

### "Contract already exists"
- Check if already deployed to this address
- Clear cache: `forge clean`

---

## Deployment Record Template

```json
{
  "network": "mainnet",
  "chainId": 1,
  "deployedAt": "2024-10-18T12:00:00Z",
  "deployer": "0x...",
  "contracts": {
    "RoyaltifyNFT": {
      "address": "0x...",
      "txHash": "0x...",
      "blockNumber": 12345678
    },
    "RoyaltifyMarketplace": {
      "address": "0x...",
      "txHash": "0x...",
      "blockNumber": 12345679
    }
  },
  "configuration": {
    "nftName": "Royaltify",
    "nftSymbol": "RYAL",
    "protocolFee": 100,
    "feeRecipient": "0x..."
  }
}
```
