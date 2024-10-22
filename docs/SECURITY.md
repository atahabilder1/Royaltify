# Security Documentation

This document details the security model, threat analysis, and protective measures implemented in the Royaltify contracts.

## Security Overview

Royaltify implements multiple layers of security to protect users and their assets:

| Layer | Protection | Implementation |
|-------|------------|----------------|
| Reentrancy | ReentrancyGuard | OpenZeppelin nonReentrant modifier |
| Access Control | Role-based | Ownable, Ownable2Step, creator checks |
| Payment Safety | Pull Pattern | Proceeds mapping with withdrawals |
| Input Validation | Comprehensive | Custom errors for all edge cases |
| Interface Checks | ERC165 | Verify NFT contract compatibility |

---

## Threat Model

### 1. Reentrancy Attacks

**Threat:** Attacker contract recursively calls back into marketplace during ETH transfer.

**Attack Vector:**
```solidity
// Malicious contract
receive() external payable {
    // Re-enter marketplace
    marketplace.withdrawProceeds();
}
```

**Mitigation:** ReentrancyGuard + Pull Payment Pattern
```solidity
// All state-changing functions are protected
function buyNFT(uint256 listingId) external payable nonReentrant {
    // State updated BEFORE any external calls
    listing.status = ListingStatus.Sold;
    _proceeds[seller] += sellerProceeds;

    // External call LAST (CEI pattern)
    IERC721(nftContract).safeTransferFrom(...);
}

// Withdrawals are separate
function withdrawProceeds() external nonReentrant {
    uint256 amount = _proceeds[msg.sender];
    _proceeds[msg.sender] = 0;  // Clear before transfer
    (bool success,) = payable(msg.sender).call{value: amount}("");
}
```

---

### 2. Front-Running Attacks

**Threat:** Attacker sees pending transaction and submits their own with higher gas.

**Scenarios:**
- Buying NFT before legitimate buyer
- Cancelling listing after seeing incoming purchase

**Mitigation:**
- **Buying:** First valid transaction wins; no mitigation needed as marketplace is competitive
- **Cancelling:** Seller can cancel anytime; if cancel and buy race, one will fail gracefully

**User Guidance:**
- Use private mempools (Flashbots) for high-value purchases
- Set appropriate gas prices

---

### 3. Price Manipulation

**Threat:** Seller updates price during buyer's transaction.

**Scenario:**
1. Listing at 1 ETH
2. Buyer submits buyNFT with 1 ETH
3. Seller front-runs with updateListing to 2 ETH
4. Buyer's transaction fails

**Mitigation:** This is actually safe behavior
- Buyer's transaction reverts with `IncorrectPayment()`
- Buyer's ETH is returned
- No funds lost

---

### 4. Unauthorized Access

**Threat:** Unauthorized users calling restricted functions.

**Protected Functions:**

| Function | Protection | Check |
|----------|------------|-------|
| setDefaultRoyalty | onlyOwner | Ownable modifier |
| setProtocolFee | onlyOwner | Ownable modifier |
| setTokenRoyalty | Creator only | `_tokenCreators[tokenId] == msg.sender` |
| cancelListing | Seller only | `listing.seller == msg.sender` |
| updateListing | Seller only | `listing.seller == msg.sender` |
| burn | Token owner | `ownerOf(tokenId) == msg.sender` |

---

### 5. Integer Overflow/Underflow

**Threat:** Arithmetic operations causing unexpected values.

**Mitigation:** Solidity 0.8.x has built-in overflow checks
```solidity
// Solidity 0.8.28 automatically reverts on overflow
uint256 result = a + b;  // Reverts if overflow
```

**Fee Calculations:**
```solidity
// Safe: Will revert if overflow (impossible with realistic values)
uint256 protocolFeeAmount = (salePrice * protocolFee) / 10_000;
uint256 royaltyAmount = (salePrice * royaltyFee) / 10_000;
```

---

### 6. Denial of Service (DoS)

**Threat:** Blocking contract functionality.

**Scenario 1: Block Gas Limit**
```solidity
// VULNERABLE: Unbounded loop
for (uint i = 0; i < allListings.length; i++) { ... }
```

**Mitigation:** Pagination
```solidity
// SAFE: Paginated queries
function getActiveListings(uint256 offset, uint256 limit) external view {
    // Bounded iteration
}
```

**Scenario 2: Failed ETH Transfer**
```solidity
// VULNERABLE: Direct transfer
payable(seller).transfer(amount);  // Can fail, blocking sales
```

**Mitigation:** Pull payment pattern
```solidity
// SAFE: Accumulate proceeds
_proceeds[seller] += amount;
// User withdraws separately
```

---

### 7. Malicious NFT Contracts

**Threat:** Interacting with malicious ERC721 implementations.

**Attack Vectors:**
- NFT that reverts on transfer
- NFT with callback hooks that reenter
- NFT that returns wrong owner

**Mitigations:**

1. **Interface Verification:**
```solidity
function _supportsERC721(address nftContract) internal view returns (bool) {
    try IERC165(nftContract).supportsInterface(type(IERC721).interfaceId) returns (bool supported) {
        return supported;
    } catch {
        return false;
    }
}
```

2. **Try/Catch for External Calls:**
```solidity
try IERC2981(nftContract).royaltyInfo(tokenId, salePrice) returns (
    address receiver, uint256 amount
) {
    // Use royalty info
} catch {
    // Proceed without royalty
}
```

3. **State Updates Before External Calls:**
```solidity
// Mark as sold BEFORE transfer
listing.status = ListingStatus.Sold;
// Then transfer
IERC721(nftContract).safeTransferFrom(...);
```

---

### 8. Ownership Transfer Risks

**Threat:** Accidental or malicious ownership transfer.

**Mitigation:** Two-step transfer (Ownable2Step)
```solidity
// Step 1: Current owner initiates
transferOwnership(newOwner);
// Ownership NOT transferred yet

// Step 2: New owner must accept
acceptOwnership();
// Only now ownership transfers
```

**Benefits:**
- Prevents accidental transfers to wrong address
- Prevents transfers to contracts that can't manage ownership
- Allows cancellation before acceptance

---

## Security Checklist

### Smart Contract Security

- [x] ReentrancyGuard on all state-changing functions
- [x] Checks-Effects-Interactions pattern
- [x] Pull payment pattern for ETH withdrawals
- [x] Input validation on all public functions
- [x] Custom errors for gas efficiency and clarity
- [x] No unbounded loops in transactions
- [x] Pagination for view functions returning arrays
- [x] Interface verification for external contracts
- [x] Two-step ownership transfer
- [x] Maximum fee caps (10% royalty, 5% protocol)
- [x] No floating pragma
- [x] No deprecated functions
- [x] Events for all state changes

### Access Control

- [x] Owner-only admin functions
- [x] Creator-only royalty updates
- [x] Seller-only listing management
- [x] Token owner-only burns

### Testing

- [x] Unit tests for all functions
- [x] Fuzz testing for edge cases
- [x] Revert condition testing
- [x] Event emission testing
- [x] Access control testing

---

## Known Limitations

### 1. No Auction Support
Current implementation only supports fixed-price listings. Auctions would require additional complexity and security considerations.

### 2. No Offer System
Buyers cannot make offers below listing price. All purchases must match exact price.

### 3. Single Currency (ETH)
Only supports ETH payments. ERC20 token support would require additional security measures.

### 4. No Batch Operations
Listing/buying multiple NFTs requires separate transactions.

### 5. Royalty Bypass
If users trade outside the marketplace (direct transfer), royalties are not enforced. This is a limitation of EIP-2981 being advisory.

---

## Incident Response

### If Vulnerability Discovered

1. **Do NOT** publicly disclose
2. Contact team immediately
3. Assess severity and impact
4. Prepare fix and migration plan
5. Deploy fix
6. Notify users if needed

### Emergency Functions

The contracts do not include pause functionality by design. In an emergency:

1. **Marketplace:** Users can cancel listings and withdraw proceeds
2. **NFT:** Users retain full control of their tokens
3. **Owner:** Can set protocol fee to 0 to disable fee collection

---

## Audit Status

| Audit | Status | Date |
|-------|--------|------|
| Internal Review | Pending | - |
| External Audit | Not Started | - |

---

## Security Contact

For security concerns, please contact:
- Email: [security contact]
- Do not open public issues for security vulnerabilities

---

## References

- [OpenZeppelin Security](https://docs.openzeppelin.com/contracts/5.x/)
- [SWC Registry](https://swcregistry.io/)
- [Consensys Best Practices](https://consensys.github.io/smart-contract-best-practices/)
- [EIP-2981 Standard](https://eips.ethereum.org/EIPS/eip-2981)
