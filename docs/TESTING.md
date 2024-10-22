# Testing Guide

Comprehensive guide for running and writing tests for Royaltify contracts.

## Test Overview

| Test Suite | Tests | Coverage |
|------------|-------|----------|
| RoyaltifyNFTTest | 41 | NFT functionality |
| RoyaltifyNFTReceiverTest | 1 | Safe mint to contracts |
| RoyaltifyMarketplaceTest | 46 | Marketplace functionality |
| RoyaltifyMarketplaceReentrancyTest | 1 | Security testing |
| **Total** | **89** | Full coverage |

---

## Running Tests

### All Tests

```bash
forge test
```

### With Verbosity

```bash
# Show test names
forge test -v

# Show logs
forge test -vv

# Show traces on failure
forge test -vvv

# Show all traces
forge test -vvvv
```

### Specific Test File

```bash
forge test --match-path test/RoyaltifyNFT.t.sol
forge test --match-path test/RoyaltifyMarketplace.t.sol
```

### Specific Test Function

```bash
forge test --match-test test_SimpleMint_CreatesToken
forge test --match-test "test_.*Mint.*"  # Regex
```

### Specific Contract

```bash
forge test --match-contract RoyaltifyNFTTest
```

---

## Test Configuration

### Fuzz Testing

Default configuration in `foundry.toml`:
```toml
[fuzz]
runs = 256              # Fuzz iterations
max_test_rejects = 65536

[profile.ci]
fuzz = { runs = 1000 }  # More runs in CI
```

Run with more iterations:
```bash
forge test --fuzz-runs 1000
```

### Gas Reporting

```bash
forge test --gas-report
```

Sample output:
```
| Contract            | Function    | Min   | Avg    | Max    |
|---------------------|-------------|-------|--------|--------|
| RoyaltifyNFT        | mint        | 188k  | 194k   | 197k   |
| RoyaltifyMarketplace| buyNFT      | 298k  | 305k   | 312k   |
```

### Coverage

```bash
forge coverage
```

Generate LCOV report:
```bash
forge coverage --report lcov
```

---

## Test Structure

### Test File Organization

```
test/
├── RoyaltifyNFT.t.sol        # NFT tests
│   ├── RoyaltifyNFTTest      # Main test contract
│   └── RoyaltifyNFTReceiverTest  # Contract receiver tests
│
└── RoyaltifyMarketplace.t.sol # Marketplace tests
    ├── RoyaltifyMarketplaceTest  # Main test contract
    └── RoyaltifyMarketplaceReentrancyTest  # Security tests
```

### Test Contract Structure

```solidity
contract RoyaltifyNFTTest is Test {
    // Contracts under test
    RoyaltifyNFT public nft;

    // Test accounts
    address public owner;
    address public creator;
    address public buyer;

    // Constants
    string public constant TOKEN_URI = "ipfs://QmTest123";

    // Setup - runs before each test
    function setUp() public {
        owner = makeAddr("owner");
        creator = makeAddr("creator");
        buyer = makeAddr("buyer");

        vm.prank(owner);
        nft = new RoyaltifyNFT("Test", "TST", owner);
    }

    // Test functions
    function test_DescriptiveName() public {
        // Arrange
        // Act
        // Assert
    }

    function testFuzz_WithRandomInput(uint256 input) public {
        // Fuzz test
    }
}
```

---

## Test Categories

### 1. Deployment Tests

```solidity
function test_DeploymentSetsCorrectName() public view {
    assertEq(nft.name(), NAME);
}

function test_RevertWhen_DeployingWithZeroAddress() public {
    vm.expectRevert(IRoyaltifyNFT.InvalidRecipient.selector);
    new RoyaltifyNFT(NAME, SYMBOL, address(0));
}
```

### 2. State Change Tests

```solidity
function test_SimpleMint_CreatesToken() public {
    vm.prank(creator);
    uint256 tokenId = nft.mint(TOKEN_URI);

    assertEq(tokenId, 0);
    assertEq(nft.ownerOf(tokenId), creator);
    assertEq(nft.tokenURI(tokenId), TOKEN_URI);
}
```

### 3. Event Tests

```solidity
function test_SimpleMint_EmitsCorrectEvents() public {
    vm.expectEmit(true, true, true, true);
    emit Minted(creator, creator, 0, TOKEN_URI);

    vm.prank(creator);
    nft.mint(TOKEN_URI);
}
```

### 4. Revert Tests

```solidity
function test_RevertWhen_NonCreatorUpdatesRoyalty() public {
    vm.prank(creator);
    uint256 tokenId = nft.mint(TOKEN_URI);

    vm.prank(buyer);
    vm.expectRevert(IRoyaltifyNFT.NotTokenCreator.selector);
    nft.setTokenRoyalty(tokenId, buyer, 500);
}
```

### 5. Fuzz Tests

```solidity
function testFuzz_Mint_WithValidRoyalty(uint96 royaltyFee) public {
    royaltyFee = uint96(bound(royaltyFee, 1, MAX_ROYALTY_FEE));

    vm.prank(creator);
    uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, royaltyFee);

    (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
    assertEq(receiver, royaltyReceiver);
    assertEq(amount, royaltyFee);
}
```

### 6. Integration Tests

```solidity
function test_FullTradingFlow() public {
    // Mint
    vm.prank(creator);
    uint256 tokenId = nft.mint(TOKEN_URI);

    // Approve & List
    vm.startPrank(creator);
    nft.approve(address(marketplace), tokenId);
    uint256 listingId = marketplace.listNFT(address(nft), tokenId, 1 ether);
    vm.stopPrank();

    // Buy
    vm.prank(buyer);
    marketplace.buyNFT{value: 1 ether}(listingId);

    // Verify
    assertEq(nft.ownerOf(tokenId), buyer);
}
```

---

## Foundry Cheat Codes

### Account Management

```solidity
// Create labeled address
address user = makeAddr("user");

// Give ETH
vm.deal(user, 100 ether);

// Impersonate
vm.prank(user);           // Single call
vm.startPrank(user);      // Multiple calls
vm.stopPrank();
```

### Time Manipulation

```solidity
// Warp to timestamp
vm.warp(block.timestamp + 1 days);

// Roll to block
vm.roll(block.number + 100);
```

### Expectations

```solidity
// Expect revert
vm.expectRevert();
vm.expectRevert("message");
vm.expectRevert(CustomError.selector);

// Expect emit
vm.expectEmit(true, true, true, true);
emit ExpectedEvent(arg1, arg2);
actualCall();  // Must emit matching event
```

### State Snapshots

```solidity
uint256 snapshot = vm.snapshot();
// ... make changes ...
vm.revertTo(snapshot);
```

---

## Writing New Tests

### Test Naming Convention

```solidity
// Format: test_[Function]_[ExpectedBehavior]
function test_Mint_CreatesToken() public {}
function test_Mint_EmitsEvent() public {}

// Format: test_RevertWhen_[Condition]
function test_RevertWhen_PriceIsZero() public {}
function test_RevertWhen_NotOwner() public {}

// Format: testFuzz_[Function]_[Description]
function testFuzz_Mint_WithRandomRoyalty(uint96 fee) public {}
```

### AAA Pattern

```solidity
function test_Example() public {
    // Arrange - Set up test state
    vm.prank(seller);
    nft.approve(address(marketplace), tokenId);

    // Act - Execute the function
    uint256 listingId = marketplace.listNFT(address(nft), tokenId, 1 ether);

    // Assert - Verify results
    Listing memory listing = marketplace.getListing(listingId);
    assertEq(listing.seller, seller);
    assertEq(listing.price, 1 ether);
}
```

### Testing Events

```solidity
function test_ListNFT_EmitsEvent() public {
    vm.startPrank(seller);
    nft.approve(address(marketplace), 0);

    // Set up event expectation BEFORE the call
    vm.expectEmit(true, true, true, true);
    emit Listed(0, seller, address(nft), 0, LISTING_PRICE);

    // Make the call that should emit
    marketplace.listNFT(address(nft), 0, LISTING_PRICE);
    vm.stopPrank();
}
```

### Testing Reverts

```solidity
function test_RevertWhen_BuyingOwnListing() public {
    vm.deal(seller, 10 ether);

    vm.startPrank(seller);
    nft.approve(address(marketplace), 0);
    uint256 listingId = marketplace.listNFT(address(nft), 0, LISTING_PRICE);

    vm.expectRevert(IRoyaltifyMarketplace.CannotBuyOwnListing.selector);
    marketplace.buyNFT{value: LISTING_PRICE}(listingId);
    vm.stopPrank();
}
```

---

## Debugging Tests

### Trace Failed Test

```bash
forge test --match-test test_FailingTest -vvvv
```

### Console Logging

```solidity
import {console2} from "forge-std/console2.sol";

function test_Debug() public {
    console2.log("Value:", someValue);
    console2.log("Address:", someAddress);
    console2.logBytes32(someBytes);
}
```

### Debug Events

```bash
forge test --match-test test_Example -vvvv 2>&1 | grep -A5 "emit"
```

---

## CI/CD Integration

### GitHub Actions

`.github/workflows/test.yml`:
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Install Foundry
        uses: foundry-rs/foundry-toolchain@v1

      - name: Run tests
        run: forge test -vvv
```

### Run CI Profile

```bash
FOUNDRY_PROFILE=ci forge test
```
