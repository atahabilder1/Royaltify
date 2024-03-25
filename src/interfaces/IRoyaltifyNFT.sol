// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IRoyaltifyNFT
 * @author Royaltify
 * @notice Interface for the Royaltify NFT contract custom functions
 * @dev The contract also implements IERC721, IERC721Enumerable, and IERC2981
 */
interface IRoyaltifyNFT {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new NFT is minted
    event Minted(address indexed creator, address indexed recipient, uint256 indexed tokenId, string tokenURI);

    /// @notice Emitted when token royalty is updated
    event TokenRoyaltyUpdated(uint256 indexed tokenId, address indexed receiver, uint96 feeNumerator);

    /// @notice Emitted when default royalty is updated
    event DefaultRoyaltyUpdated(address indexed receiver, uint96 feeNumerator);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when caller is not the token creator
    error NotTokenCreator();

    /// @notice Thrown when royalty fee exceeds maximum allowed
    error RoyaltyFeeTooHigh();

    /// @notice Thrown when token URI is empty
    error EmptyTokenURI();

    /// @notice Thrown when recipient is zero address
    error InvalidRecipient();

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints a new NFT with royalty information
     * @param to The recipient of the NFT
     * @param tokenURI_ The metadata URI for the token
     * @param royaltyReceiver The address to receive royalties
     * @param royaltyFeeNumerator The royalty fee in basis points (max 10000 = 100%)
     * @return tokenId The ID of the newly minted token
     */
    function mint(
        address to,
        string calldata tokenURI_,
        address royaltyReceiver,
        uint96 royaltyFeeNumerator
    )
        external
        returns (uint256 tokenId);

    /**
     * @notice Mints a new NFT with default royalty to the caller
     * @param tokenURI_ The metadata URI for the token
     * @return tokenId The ID of the newly minted token
     */
    function mint(string calldata tokenURI_) external returns (uint256 tokenId);

    /**
     * @notice Returns the creator of a token
     * @param tokenId The token ID
     * @return creator The address that created/minted the token
     */
    function tokenCreator(uint256 tokenId) external view returns (address creator);

    /**
     * @notice Returns the maximum royalty fee allowed in basis points
     * @return The maximum fee (1000 = 10%)
     */
    function MAX_ROYALTY_FEE() external view returns (uint96);
}
