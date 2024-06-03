// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC2981 } from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Ownable2Step } from "@openzeppelin/contracts/access/Ownable2Step.sol";
import { IRoyaltifyMarketplace } from "./interfaces/IRoyaltifyMarketplace.sol";

/**
 * @title RoyaltifyMarketplace
 * @author Royaltify
 * @notice A secure NFT marketplace with built-in EIP-2981 royalty enforcement
 * @dev Implements reentrancy-safe trading mechanics with pull payment pattern
 *
 * Security Features:
 * - ReentrancyGuard on all state-changing functions
 * - Pull payment pattern for proceeds withdrawal
 * - Checks-Effects-Interactions pattern throughout
 * - Two-step ownership transfer
 * - Automatic EIP-2981 royalty distribution
 *
 * Trading Features:
 * - List NFTs for fixed price sale
 * - Update listing prices
 * - Cancel listings
 * - Buy with automatic royalty distribution
 * - Protocol fee support
 */
contract RoyaltifyMarketplace is ReentrancyGuard, Ownable2Step, IRoyaltifyMarketplace {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Maximum protocol fee allowed (5% = 500 basis points)
    uint256 public constant MAX_PROTOCOL_FEE = 500;

    /// @notice Protocol fee in basis points (1% = 100)
    uint256 public protocolFee;

    /// @notice Address receiving protocol fees
    address public protocolFeeRecipient;

    /// @notice Counter for listing IDs
    uint256 public listingCount;

    /// @notice Mapping of listing ID to listing details
    mapping(uint256 listingId => Listing listing) private _listings;

    /// @notice Mapping of user address to their accumulated proceeds
    mapping(address user => uint256 proceeds) private _proceeds;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deploys the marketplace contract
     * @param initialFee The initial protocol fee in basis points
     * @param feeRecipient The address to receive protocol fees
     */
    constructor(uint256 initialFee, address feeRecipient) Ownable(msg.sender) {
        if (initialFee > MAX_PROTOCOL_FEE) revert ProtocolFeeTooHigh();
        if (feeRecipient == address(0)) revert ZeroAddress();

        protocolFee = initialFee;
        protocolFeeRecipient = feeRecipient;
    }

    /*//////////////////////////////////////////////////////////////
                           LISTING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        external
        nonReentrant
        returns (uint256 listingId)
    {
        if (price == 0) revert PriceCannotBeZero();
        if (!_supportsERC721(nftContract)) revert InvalidNFTContract();

        IERC721 nft = IERC721(nftContract);

        // Verify caller owns the NFT
        if (nft.ownerOf(tokenId) != msg.sender) revert NotApprovedForNFT();

        // Verify marketplace is approved
        if (!nft.isApprovedForAll(msg.sender, address(this)) && nft.getApproved(tokenId) != address(this)) {
            revert NotApprovedForNFT();
        }

        listingId = listingCount++;

        _listings[listingId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            status: ListingStatus.Active,
            listedAt: block.timestamp
        });

        emit Listed(listingId, msg.sender, nftContract, tokenId, price);
    }

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function updateListing(uint256 listingId, uint256 newPrice) external nonReentrant {
        if (newPrice == 0) revert PriceCannotBeZero();

        Listing storage listing = _listings[listingId];

        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.seller != msg.sender) revert NotSeller();

        uint256 oldPrice = listing.price;
        listing.price = newPrice;

        emit ListingUpdated(listingId, oldPrice, newPrice);
    }

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing storage listing = _listings[listingId];

        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.seller != msg.sender) revert NotSeller();

        listing.status = ListingStatus.Cancelled;

        emit ListingCancelled(listingId);
    }

    /*//////////////////////////////////////////////////////////////
                            BUYING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function buyNFT(uint256 listingId) external payable nonReentrant {
        Listing storage listing = _listings[listingId];

        if (listing.seller == address(0)) revert ListingNotFound();
        if (listing.status != ListingStatus.Active) revert ListingNotActive();
        if (listing.seller == msg.sender) revert CannotBuyOwnListing();
        if (msg.value != listing.price) revert IncorrectPayment();

        // Mark as sold immediately (CEI pattern)
        listing.status = ListingStatus.Sold;

        // Calculate payment distribution
        (
            uint256 sellerProceeds,
            uint256 royaltyAmount,
            address royaltyReceiver,
            uint256 protocolFeeAmount
        ) = _calculatePaymentDistribution(listing.nftContract, listing.tokenId, listing.price);

        // Update proceeds (pull payment pattern)
        if (sellerProceeds > 0) {
            _proceeds[listing.seller] += sellerProceeds;
        }
        if (royaltyAmount > 0 && royaltyReceiver != address(0)) {
            _proceeds[royaltyReceiver] += royaltyAmount;
        }
        if (protocolFeeAmount > 0) {
            _proceeds[protocolFeeRecipient] += protocolFeeAmount;
        }

        // Transfer NFT to buyer (external call last - CEI pattern)
        IERC721(listing.nftContract).safeTransferFrom(listing.seller, msg.sender, listing.tokenId);

        emit Sale(
            listingId,
            msg.sender,
            listing.seller,
            listing.nftContract,
            listing.tokenId,
            listing.price,
            royaltyAmount,
            royaltyReceiver
        );
    }

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function withdrawProceeds() external nonReentrant {
        uint256 amount = _proceeds[msg.sender];
        if (amount == 0) revert NoProceeds();

        // Clear proceeds before transfer (CEI pattern)
        _proceeds[msg.sender] = 0;

        // Transfer ETH
        (bool success,) = payable(msg.sender).call{ value: amount }("");
        if (!success) revert TransferFailed();

        emit ProceedsWithdrawn(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                           ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Updates the protocol fee
     * @dev Only owner can call. Fee cannot exceed MAX_PROTOCOL_FEE
     * @param newFee The new fee in basis points
     */
    function setProtocolFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_PROTOCOL_FEE) revert ProtocolFeeTooHigh();

        uint256 oldFee = protocolFee;
        protocolFee = newFee;

        emit ProtocolFeeUpdated(oldFee, newFee);
    }

    /**
     * @notice Updates the protocol fee recipient
     * @dev Only owner can call
     * @param newRecipient The new recipient address
     */
    function setProtocolFeeRecipient(address newRecipient) external onlyOwner {
        if (newRecipient == address(0)) revert ZeroAddress();

        address oldRecipient = protocolFeeRecipient;
        protocolFeeRecipient = newRecipient;

        emit ProtocolFeeRecipientUpdated(oldRecipient, newRecipient);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return _listings[listingId];
    }

    /**
     * @inheritdoc IRoyaltifyMarketplace
     */
    function getProceeds(address user) external view returns (uint256) {
        return _proceeds[user];
    }

    /**
     * @notice Gets all active listings (paginated)
     * @param offset Starting index
     * @param limit Maximum number of listings to return
     * @return listings Array of active listings
     * @return listingIds Array of corresponding listing IDs
     */
    function getActiveListings(
        uint256 offset,
        uint256 limit
    )
        external
        view
        returns (Listing[] memory listings, uint256[] memory listingIds)
    {
        uint256 count = 0;
        uint256 total = listingCount;

        // First pass: count active listings in range
        for (uint256 i = offset; i < total && count < limit; i++) {
            if (_listings[i].status == ListingStatus.Active) {
                count++;
            }
        }

        listings = new Listing[](count);
        listingIds = new uint256[](count);

        // Second pass: populate arrays
        uint256 index = 0;
        for (uint256 i = offset; i < total && index < count; i++) {
            if (_listings[i].status == ListingStatus.Active) {
                listings[index] = _listings[i];
                listingIds[index] = i;
                index++;
            }
        }
    }

    /**
     * @notice Gets listings by seller
     * @param seller The seller address
     * @return listings Array of seller's listings
     * @return listingIds Array of corresponding listing IDs
     */
    function getListingsBySeller(address seller)
        external
        view
        returns (Listing[] memory listings, uint256[] memory listingIds)
    {
        uint256 count = 0;
        uint256 total = listingCount;

        // First pass: count seller's listings
        for (uint256 i = 0; i < total; i++) {
            if (_listings[i].seller == seller) {
                count++;
            }
        }

        listings = new Listing[](count);
        listingIds = new uint256[](count);

        // Second pass: populate arrays
        uint256 index = 0;
        for (uint256 i = 0; i < total; i++) {
            if (_listings[i].seller == seller) {
                listings[index] = _listings[i];
                listingIds[index] = i;
                index++;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Calculates the payment distribution for a sale
     * @param nftContract The NFT contract address
     * @param tokenId The token ID
     * @param salePrice The sale price
     * @return sellerProceeds Amount going to seller
     * @return royaltyAmount Amount going to royalty receiver
     * @return royaltyReceiver Address receiving royalty
     * @return protocolFeeAmount Amount going to protocol
     */
    function _calculatePaymentDistribution(
        address nftContract,
        uint256 tokenId,
        uint256 salePrice
    )
        internal
        view
        returns (uint256 sellerProceeds, uint256 royaltyAmount, address royaltyReceiver, uint256 protocolFeeAmount)
    {
        // Calculate protocol fee
        protocolFeeAmount = (salePrice * protocolFee) / 10_000;

        // Check for EIP-2981 royalty info
        if (_supportsERC2981(nftContract)) {
            try IERC2981(nftContract).royaltyInfo(tokenId, salePrice) returns (
                address receiver, uint256 amount
            ) {
                royaltyReceiver = receiver;
                royaltyAmount = amount;
            } catch {
                // If royaltyInfo fails, proceed without royalty
                royaltyAmount = 0;
                royaltyReceiver = address(0);
            }
        }

        // Calculate seller proceeds (remaining after fees and royalties)
        sellerProceeds = salePrice - protocolFeeAmount - royaltyAmount;
    }

    /**
     * @notice Checks if a contract supports ERC721 interface
     * @param nftContract The contract to check
     * @return True if ERC721 is supported
     */
    function _supportsERC721(address nftContract) internal view returns (bool) {
        try IERC165(nftContract).supportsInterface(type(IERC721).interfaceId) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }

    /**
     * @notice Checks if a contract supports ERC2981 interface
     * @param nftContract The contract to check
     * @return True if ERC2981 is supported
     */
    function _supportsERC2981(address nftContract) internal view returns (bool) {
        try IERC165(nftContract).supportsInterface(type(IERC2981).interfaceId) returns (bool supported) {
            return supported;
        } catch {
            return false;
        }
    }
}
