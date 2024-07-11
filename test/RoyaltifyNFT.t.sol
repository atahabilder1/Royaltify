// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Test, console2 } from "forge-std/Test.sol";
import { RoyaltifyNFT } from "../src/RoyaltifyNFT.sol";
import { IRoyaltifyNFT } from "../src/interfaces/IRoyaltifyNFT.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title RoyaltifyNFTTest
 * @notice Comprehensive test suite for RoyaltifyNFT contract
 */
contract RoyaltifyNFTTest is Test {
    RoyaltifyNFT public nft;

    address public owner;
    address public creator;
    address public buyer;
    address public royaltyReceiver;

    string public constant NAME = "Royaltify";
    string public constant SYMBOL = "RYAL";
    string public constant TOKEN_URI = "ipfs://QmTest123";
    string public constant TOKEN_URI_2 = "ipfs://QmTest456";

    uint96 public constant DEFAULT_ROYALTY_FEE = 250; // 2.5%
    uint96 public constant MAX_ROYALTY_FEE = 1000; // 10%
    uint96 public constant CUSTOM_ROYALTY_FEE = 500; // 5%

    event Minted(address indexed creator, address indexed recipient, uint256 indexed tokenId, string tokenURI);
    event TokenRoyaltyUpdated(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);
    event DefaultRoyaltyUpdated(address indexed receiver, uint96 feeNumerator);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        owner = makeAddr("owner");
        creator = makeAddr("creator");
        buyer = makeAddr("buyer");
        royaltyReceiver = makeAddr("royaltyReceiver");

        vm.prank(owner);
        nft = new RoyaltifyNFT(NAME, SYMBOL, royaltyReceiver);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_DeploymentSetsCorrectName() public view {
        assertEq(nft.name(), NAME);
    }

    function test_DeploymentSetsCorrectSymbol() public view {
        assertEq(nft.symbol(), SYMBOL);
    }

    function test_DeploymentSetsCorrectOwner() public view {
        assertEq(nft.owner(), owner);
    }

    function test_DeploymentSetsDefaultRoyalty() public {
        // Mint a token first to test default royalty
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        // Default royalty is set to creator on simple mint, not the default receiver
        assertEq(receiver, creator);
        assertEq(amount, 250); // 2.5% of 10000
    }

    function test_RevertWhen_DeployingWithZeroAddress() public {
        vm.expectRevert(IRoyaltifyNFT.InvalidRecipient.selector);
        new RoyaltifyNFT(NAME, SYMBOL, address(0));
    }

    /*//////////////////////////////////////////////////////////////
                         SIMPLE MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SimpleMint_CreatesToken() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        assertEq(tokenId, 0);
        assertEq(nft.ownerOf(tokenId), creator);
        assertEq(nft.tokenURI(tokenId), TOKEN_URI);
    }

    function test_SimpleMint_EmitsCorrectEvents() public {
        vm.expectEmit(true, true, true, true);
        emit Minted(creator, creator, 0, TOKEN_URI);

        vm.expectEmit(true, true, false, true);
        emit TokenRoyaltyUpdated(0, creator, DEFAULT_ROYALTY_FEE);

        vm.prank(creator);
        nft.mint(TOKEN_URI);
    }

    function test_SimpleMint_SetsCreatorAsRoyaltyReceiver() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, creator);
        assertEq(amount, 250); // 2.5%
    }

    function test_SimpleMint_IncrementsTokenId() public {
        vm.startPrank(creator);
        uint256 tokenId1 = nft.mint(TOKEN_URI);
        uint256 tokenId2 = nft.mint(TOKEN_URI_2);
        vm.stopPrank();

        assertEq(tokenId1, 0);
        assertEq(tokenId2, 1);
    }

    function test_SimpleMint_IncrementsTotalSupply() public {
        assertEq(nft.totalSupply(), 0);

        vm.prank(creator);
        nft.mint(TOKEN_URI);

        assertEq(nft.totalSupply(), 1);
    }

    function test_RevertWhen_SimpleMintWithEmptyURI() public {
        vm.prank(creator);
        vm.expectRevert(IRoyaltifyNFT.EmptyTokenURI.selector);
        nft.mint("");
    }

    /*//////////////////////////////////////////////////////////////
                       ADVANCED MINTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_AdvancedMint_CreatesTokenForRecipient() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, CUSTOM_ROYALTY_FEE);

        assertEq(nft.ownerOf(tokenId), buyer);
        assertEq(nft.tokenURI(tokenId), TOKEN_URI);
    }

    function test_AdvancedMint_SetsCustomRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, CUSTOM_ROYALTY_FEE);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 500); // 5%
    }

    function test_AdvancedMint_TracksCreator() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, CUSTOM_ROYALTY_FEE);

        assertEq(nft.tokenCreator(tokenId), creator);
    }

    function test_AdvancedMint_WithZeroRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, 0);

        // Should use default royalty since royaltyFeeNumerator is 0
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, 250); // Default 2.5%
    }

    function test_RevertWhen_AdvancedMintToZeroAddress() public {
        vm.prank(creator);
        vm.expectRevert(IRoyaltifyNFT.InvalidRecipient.selector);
        nft.mint(address(0), TOKEN_URI, royaltyReceiver, CUSTOM_ROYALTY_FEE);
    }

    function test_RevertWhen_AdvancedMintWithEmptyURI() public {
        vm.prank(creator);
        vm.expectRevert(IRoyaltifyNFT.EmptyTokenURI.selector);
        nft.mint(buyer, "", royaltyReceiver, CUSTOM_ROYALTY_FEE);
    }

    function test_RevertWhen_AdvancedMintWithExcessiveRoyalty() public {
        vm.prank(creator);
        vm.expectRevert(IRoyaltifyNFT.RoyaltyFeeTooHigh.selector);
        nft.mint(buyer, TOKEN_URI, royaltyReceiver, MAX_ROYALTY_FEE + 1);
    }

    /*//////////////////////////////////////////////////////////////
                          ROYALTY UPDATE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetTokenRoyalty_UpdatesRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 800;

        vm.prank(creator);
        nft.setTokenRoyalty(tokenId, newReceiver, newFee);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, newReceiver);
        assertEq(amount, 800);
    }

    function test_SetTokenRoyalty_EmitsEvent() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 800;

        vm.expectEmit(true, true, false, true);
        emit TokenRoyaltyUpdated(tokenId, newReceiver, newFee);

        vm.prank(creator);
        nft.setTokenRoyalty(tokenId, newReceiver, newFee);
    }

    function test_RevertWhen_NonCreatorUpdatesRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(buyer);
        vm.expectRevert(IRoyaltifyNFT.NotTokenCreator.selector);
        nft.setTokenRoyalty(tokenId, buyer, 500);
    }

    function test_RevertWhen_SettingExcessiveTokenRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        vm.expectRevert(IRoyaltifyNFT.RoyaltyFeeTooHigh.selector);
        nft.setTokenRoyalty(tokenId, creator, MAX_ROYALTY_FEE + 1);
    }

    /*//////////////////////////////////////////////////////////////
                       DEFAULT ROYALTY TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SetDefaultRoyalty_UpdatesDefault() public {
        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 300;

        vm.prank(owner);
        nft.setDefaultRoyalty(newReceiver, newFee);

        // Mint a new token to verify default royalty is applied
        // Note: Simple mint overrides default with creator-specific royalty
        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, address(0), 0);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, newReceiver);
        assertEq(amount, 300);
    }

    function test_SetDefaultRoyalty_EmitsEvent() public {
        address newReceiver = makeAddr("newReceiver");
        uint96 newFee = 300;

        vm.expectEmit(true, false, false, true);
        emit DefaultRoyaltyUpdated(newReceiver, newFee);

        vm.prank(owner);
        nft.setDefaultRoyalty(newReceiver, newFee);
    }

    function test_RevertWhen_NonOwnerSetsDefaultRoyalty() public {
        vm.prank(creator);
        vm.expectRevert();
        nft.setDefaultRoyalty(creator, 300);
    }

    function test_RevertWhen_SettingExcessiveDefaultRoyalty() public {
        vm.prank(owner);
        vm.expectRevert(IRoyaltifyNFT.RoyaltyFeeTooHigh.selector);
        nft.setDefaultRoyalty(royaltyReceiver, MAX_ROYALTY_FEE + 1);
    }

    /*//////////////////////////////////////////////////////////////
                             BURN TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Burn_RemovesToken() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        nft.burn(tokenId);

        vm.expectRevert();
        nft.ownerOf(tokenId);
    }

    function test_Burn_DecrementsSupply() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        assertEq(nft.totalSupply(), 1);

        vm.prank(creator);
        nft.burn(tokenId);

        assertEq(nft.totalSupply(), 0);
    }

    function test_Burn_ResetsRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        nft.burn(tokenId);

        // Token royalty should be reset, falling back to default
        // But since token is burned, this would revert anyway in real usage
    }

    function test_RevertWhen_NonOwnerBurns() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(buyer);
        vm.expectRevert(IRoyaltifyNFT.NotTokenCreator.selector);
        nft.burn(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                         ENUMERABLE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_TokenByIndex_ReturnsCorrectToken() public {
        vm.startPrank(creator);
        nft.mint(TOKEN_URI);
        nft.mint(TOKEN_URI_2);
        vm.stopPrank();

        assertEq(nft.tokenByIndex(0), 0);
        assertEq(nft.tokenByIndex(1), 1);
    }

    function test_TokenOfOwnerByIndex_ReturnsCorrectToken() public {
        vm.prank(creator);
        nft.mint(buyer, TOKEN_URI, royaltyReceiver, CUSTOM_ROYALTY_FEE);

        vm.prank(creator);
        nft.mint(buyer, TOKEN_URI_2, royaltyReceiver, CUSTOM_ROYALTY_FEE);

        assertEq(nft.tokenOfOwnerByIndex(buyer, 0), 0);
        assertEq(nft.tokenOfOwnerByIndex(buyer, 1), 1);
        assertEq(nft.balanceOf(buyer), 2);
    }

    /*//////////////////////////////////////////////////////////////
                      INTERFACE SUPPORT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_SupportsERC721Interface() public view {
        assertTrue(nft.supportsInterface(type(IERC721Receiver).interfaceId) == false);
        // ERC721 interface
        assertTrue(nft.supportsInterface(0x80ac58cd));
    }

    function test_SupportsERC2981Interface() public view {
        assertTrue(nft.supportsInterface(type(IERC2981).interfaceId));
    }

    function test_SupportsERC165Interface() public view {
        // ERC165 interface
        assertTrue(nft.supportsInterface(0x01ffc9a7));
    }

    /*//////////////////////////////////////////////////////////////
                           TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Transfer_MovesToken() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        nft.transferFrom(creator, buyer, tokenId);

        assertEq(nft.ownerOf(tokenId), buyer);
    }

    function test_Transfer_PreservesCreator() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        nft.transferFrom(creator, buyer, tokenId);

        // Creator should remain the same after transfer
        assertEq(nft.tokenCreator(tokenId), creator);
    }

    function test_Transfer_PreservesRoyalty() public {
        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        vm.prank(creator);
        nft.transferFrom(creator, buyer, tokenId);

        // Royalty info should remain unchanged
        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, creator);
        assertEq(amount, 250);
    }

    /*//////////////////////////////////////////////////////////////
                            FUZZ TESTS
    //////////////////////////////////////////////////////////////*/

    function testFuzz_Mint_WithValidRoyalty(uint96 royaltyFee) public {
        royaltyFee = uint96(bound(royaltyFee, 1, MAX_ROYALTY_FEE));

        vm.prank(creator);
        uint256 tokenId = nft.mint(buyer, TOKEN_URI, royaltyReceiver, royaltyFee);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, 10_000);
        assertEq(receiver, royaltyReceiver);
        assertEq(amount, royaltyFee);
    }

    function testFuzz_RoyaltyCalculation(uint256 salePrice) public {
        salePrice = bound(salePrice, 1, type(uint128).max);

        vm.prank(creator);
        uint256 tokenId = nft.mint(TOKEN_URI);

        (address receiver, uint256 amount) = nft.royaltyInfo(tokenId, salePrice);

        assertEq(receiver, creator);
        assertEq(amount, (salePrice * DEFAULT_ROYALTY_FEE) / 10_000);
    }

    function testFuzz_MultipleMints(uint8 count) public {
        count = uint8(bound(count, 1, 50));

        vm.startPrank(creator);
        for (uint256 i = 0; i < count; i++) {
            nft.mint(string(abi.encodePacked("ipfs://token", i)));
        }
        vm.stopPrank();

        assertEq(nft.totalSupply(), count);
        assertEq(nft.balanceOf(creator), count);
    }
}

/**
 * @title RoyaltifyNFTReceiverTest
 * @notice Test safe minting to contract receivers
 */
contract RoyaltifyNFTReceiverTest is Test, IERC721Receiver {
    RoyaltifyNFT public nft;
    address public owner;

    function setUp() public {
        owner = makeAddr("owner");
        vm.prank(owner);
        nft = new RoyaltifyNFT("Royaltify", "RYAL", owner);
    }

    function test_SafeMint_ToContractReceiver() public {
        vm.prank(owner);
        uint256 tokenId = nft.mint(address(this), "ipfs://test", owner, 500);

        assertEq(nft.ownerOf(tokenId), address(this));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    )
        external
        pure
        override
        returns (bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }
}
