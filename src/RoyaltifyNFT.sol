// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721URIStorage } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import { ERC2981 } from "@openzeppelin/contracts/token/common/ERC2981.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRoyaltifyNFT } from "./interfaces/IRoyaltifyNFT.sol";

/**
 * @title RoyaltifyNFT
 * @author Royaltify
 * @notice ERC-721 NFT contract with built-in EIP-2981 royalty support
 * @dev Implements creator royalties that are automatically enforced by compatible marketplaces
 *
 * Key Features:
 * - ERC-721 compliant NFT with metadata support
 * - EIP-2981 royalty standard for on-chain royalty information
 * - Per-token royalty configuration
 * - Creator tracking for each token
 * - Maximum 10% royalty cap to prevent abuse
 * - Enumerable for on-chain token discovery
 */
contract RoyaltifyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981, Ownable, IRoyaltifyNFT {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum royalty fee allowed (10% = 1000 basis points)
    uint96 public constant MAX_ROYALTY_FEE = 1000;

    /// @notice Default royalty fee for new tokens (2.5% = 250 basis points)
    uint96 public constant DEFAULT_ROYALTY_FEE = 250;

    /// @notice Counter for generating unique token IDs
    uint256 private _tokenIdCounter;

    /// @notice Mapping from token ID to creator address
    mapping(uint256 tokenId => address creator) private _tokenCreators;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys the RoyaltifyNFT contract
     * @param name_ The name of the NFT collection
     * @param symbol_ The symbol of the NFT collection
     * @param defaultRoyaltyReceiver The default address to receive royalties
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address defaultRoyaltyReceiver
    )
        ERC721(name_, symbol_)
        Ownable(msg.sender)
    {
        if (defaultRoyaltyReceiver == address(0)) revert InvalidRecipient();
        _setDefaultRoyalty(defaultRoyaltyReceiver, DEFAULT_ROYALTY_FEE);
    }

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltifyNFT
     */
    function mint(
        address to,
        string calldata tokenURI_,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    )
        external
        returns (uint256 tokenId)
    {
        if (to == address(0)) revert InvalidRecipient();
        if (bytes(tokenURI_).length == 0) revert EmptyTokenURI();
        if (royaltyFeeNumerator > MAX_ROYALTY_FEE) revert RoyaltyFeeTooHigh();

        tokenId = _tokenIdCounter++;

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _tokenCreators[tokenId] = msg.sender;

        if (royaltyReceiver != address(0) && royaltyFeeNumerator > 0) {
            _setTokenRoyalty(tokenId, royaltyReceiver, royaltyFeeNumerator);
            emit TokenRoyaltyUpdated(tokenId, royaltyReceiver, royaltyFeeNumerator);
        }

        emit Minted(msg.sender, to, tokenId, tokenURI_);
    }

    /**
     * @inheritdoc IRoyaltifyNFT
     */
    function mint(string calldata tokenURI_) external returns (uint256 tokenId) {
        if (bytes(tokenURI_).length == 0) revert EmptyTokenURI();

        tokenId = _tokenIdCounter++;

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, tokenURI_);
        _tokenCreators[tokenId] = msg.sender;

        // Set royalty to creator with default fee
        _setTokenRoyalty(tokenId, msg.sender, DEFAULT_ROYALTY_FEE);

        emit Minted(msg.sender, msg.sender, tokenId, tokenURI_);
        emit TokenRoyaltyUpdated(tokenId, msg.sender, DEFAULT_ROYALTY_FEE);
    }

    /**
     * @notice Updates the royalty information for a specific token
     * @dev Only the original creator can update the royalty
     * @param tokenId The token ID to update
     * @param receiver The new royalty receiver
     * @param feeNumerator The new royalty fee in basis points
     */
    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) external {
        if (_tokenCreators[tokenId] != msg.sender) revert NotTokenCreator();
        if (feeNumerator > MAX_ROYALTY_FEE) revert RoyaltyFeeTooHigh();

        _setTokenRoyalty(tokenId, receiver, feeNumerator);
        emit TokenRoyaltyUpdated(tokenId, receiver, feeNumerator);
    }

    /**
     * @notice Updates the default royalty for new tokens
     * @dev Only owner can update default royalty
     * @param receiver The default royalty receiver
     * @param feeNumerator The default royalty fee in basis points
     */
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        if (feeNumerator > MAX_ROYALTY_FEE) revert RoyaltyFeeTooHigh();

        _setDefaultRoyalty(receiver, feeNumerator);
        emit DefaultRoyaltyUpdated(receiver, feeNumerator);
    }

    /**
     * @notice Burns a token
     * @dev Only the token owner can burn their token
     * @param tokenId The token ID to burn
     */
    function burn(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert NotTokenCreator();

        _burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltifyNFT
     */
    function tokenCreator(uint256 tokenId) external view returns (address) {
        _requireOwned(tokenId);
        return _tokenCreators[tokenId];
    }

    /**
     * @notice Returns the total number of tokens minted
     * @return The total supply
     */
    function totalSupply() public view override(ERC721Enumerable) returns (uint256) {
        return ERC721Enumerable.totalSupply();
    }

    /**
     * @notice Returns the metadata URI for a token
     * @param tokenId The token ID
     * @return The metadata URI
     */
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }

    /**
     * @notice Checks if contract supports an interface
     * @param interfaceId The interface identifier
     * @return True if the interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Hook that is called before any token transfer
     */
    function _update(
        address to,
        uint256 tokenId,
        address auth
    )
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    /**
     * @dev Increases the balance of `account` by `amount`
     */
    function _increaseBalance(address account, uint128 amount) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, amount);
    }
}
