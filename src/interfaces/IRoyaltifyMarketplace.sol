// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IRoyaltifyMarketplace
 * @author Royaltify
 * @notice Interface for the Royaltify NFT Marketplace with EIP-2981 royalty support
 */
interface IRoyaltifyMarketplace {
    /*//////////////////////////////////////////////////////////////
                                 ENUMS
    //////////////////////////////////////////////////////////////*/

    /// @notice The status of a listing
    enum ListingStatus {
        Active,
        Sold,
        Cancelled
    }

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Represents a marketplace listing
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        ListingStatus status;
        uint256 listedAt;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an NFT is listed for sale
    event Listed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /// @notice Emitted when a listing price is updated
    event ListingUpdated(uint256 indexed listingId, uint256 oldPrice, uint256 newPrice);

    /// @notice Emitted when a listing is cancelled
    event ListingCancelled(uint256 indexed listingId);

    /// @notice Emitted when an NFT is sold
    event Sale(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 royaltyAmount,
        address royaltyReceiver
    );

    /// @notice Emitted when protocol fee is updated
    event ProtocolFeeUpdated(uint256 oldFee, uint256 newFee);

    /// @notice Emitted when protocol fee recipient is updated
    event ProtocolFeeRecipientUpdated(address oldRecipient, address newRecipient);

    /// @notice Emitted when proceeds are withdrawn
    event ProceedsWithdrawn(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Thrown when price is zero
    error PriceCannotBeZero();

    /// @notice Thrown when listing does not exist
    error ListingNotFound();

    /// @notice Thrown when listing is not active
    error ListingNotActive();

    /// @notice Thrown when caller is not the seller
    error NotSeller();

    /// @notice Thrown when caller is the seller (cannot buy own listing)
    error CannotBuyOwnListing();

    /// @notice Thrown when payment amount is incorrect
    error IncorrectPayment();

    /// @notice Thrown when NFT contract doesn't support required interfaces
    error InvalidNFTContract();

    /// @notice Thrown when caller is not approved for NFT
    error NotApprovedForNFT();

    /// @notice Thrown when protocol fee is too high
    error ProtocolFeeTooHigh();

    /// @notice Thrown when there are no proceeds to withdraw
    error NoProceeds();

    /// @notice Thrown when transfer fails
    error TransferFailed();

    /// @notice Thrown when address is zero
    error ZeroAddress();

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Lists an NFT for sale
     * @param nftContract The address of the NFT contract
     * @param tokenId The ID of the NFT to list
     * @param price The listing price in wei
     * @return listingId The ID of the created listing
     */
    function listNFT(address nftContract, uint256 tokenId, uint256 price) external returns (uint256 listingId);

    /**
     * @notice Updates the price of an existing listing
     * @param listingId The ID of the listing to update
     * @param newPrice The new price in wei
     */
    function updateListing(uint256 listingId, uint256 newPrice) external;

    /**
     * @notice Cancels a listing
     * @param listingId The ID of the listing to cancel
     */
    function cancelListing(uint256 listingId) external;

    /**
     * @notice Buys an NFT from a listing
     * @param listingId The ID of the listing to buy
     */
    function buyNFT(uint256 listingId) external payable;

    /**
     * @notice Withdraws accumulated proceeds for the caller
     */
    function withdrawProceeds() external;

    /**
     * @notice Returns the listing details
     * @param listingId The listing ID
     * @return The listing struct
     */
    function getListing(uint256 listingId) external view returns (Listing memory);

    /**
     * @notice Returns the proceeds available for withdrawal
     * @param user The user address
     * @return The amount of proceeds in wei
     */
    function getProceeds(address user) external view returns (uint256);

    /**
     * @notice Returns the total number of listings created
     * @return The listing count
     */
    function listingCount() external view returns (uint256);

    /**
     * @notice Returns the protocol fee in basis points
     * @return The protocol fee
     */
    function protocolFee() external view returns (uint256);

    /**
     * @notice Returns the protocol fee recipient
     * @return The recipient address
     */
    function protocolFeeRecipient() external view returns (address);
}
