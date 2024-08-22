// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import { Script, console2 } from "forge-std/Script.sol";
import { RoyaltifyNFT } from "../src/RoyaltifyNFT.sol";
import { RoyaltifyMarketplace } from "../src/RoyaltifyMarketplace.sol";

/**
 * @title Deploy
 * @notice Deployment script for Royaltify NFT Marketplace
 * @dev Run with: forge script script/Deploy.s.sol:Deploy --rpc-url <RPC_URL> --broadcast
 */
contract Deploy is Script {
    // Configuration
    string public constant NFT_NAME = "Royaltify";
    string public constant NFT_SYMBOL = "RYAL";
    uint256 public constant PROTOCOL_FEE = 100; // 1%

    function run() external {
        // Get deployment configuration from environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        console2.log("Deploying Royaltify contracts...");
        console2.log("Deployer:", deployer);
        console2.log("Fee Recipient:", feeRecipient);

        vm.startBroadcast(deployerPrivateKey);

        // Deploy NFT contract
        RoyaltifyNFT nft = new RoyaltifyNFT(NFT_NAME, NFT_SYMBOL, feeRecipient);
        console2.log("RoyaltifyNFT deployed at:", address(nft));

        // Deploy Marketplace contract
        RoyaltifyMarketplace marketplace = new RoyaltifyMarketplace(PROTOCOL_FEE, feeRecipient);
        console2.log("RoyaltifyMarketplace deployed at:", address(marketplace));

        vm.stopBroadcast();

        // Log deployment summary
        console2.log("\n========== DEPLOYMENT SUMMARY ==========");
        console2.log("Network:", block.chainid);
        console2.log("RoyaltifyNFT:", address(nft));
        console2.log("RoyaltifyMarketplace:", address(marketplace));
        console2.log("Protocol Fee:", PROTOCOL_FEE, "basis points (1%)");
        console2.log("Fee Recipient:", feeRecipient);
        console2.log("=========================================\n");
    }
}

/**
 * @title DeployLocal
 * @notice Local deployment script for testing
 * @dev Run with: forge script script/Deploy.s.sol:DeployLocal --fork-url <RPC_URL> --broadcast
 */
contract DeployLocal is Script {
    function run() external {
        // Use Foundry's default test account
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        address deployer = vm.addr(deployerPrivateKey);

        console2.log("Local deployment with test account:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        RoyaltifyNFT nft = new RoyaltifyNFT("Royaltify", "RYAL", deployer);
        RoyaltifyMarketplace marketplace = new RoyaltifyMarketplace(100, deployer);

        vm.stopBroadcast();

        console2.log("RoyaltifyNFT:", address(nft));
        console2.log("RoyaltifyMarketplace:", address(marketplace));
    }
}

/**
 * @title DeploySepolia
 * @notice Sepolia testnet deployment script
 * @dev Run with: forge script script/Deploy.s.sol:DeploySepolia --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
 */
contract DeploySepolia is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address feeRecipient = vm.envOr("FEE_RECIPIENT", deployer);

        console2.log("Deploying to Sepolia...");
        console2.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        RoyaltifyNFT nft = new RoyaltifyNFT("Royaltify", "RYAL", feeRecipient);
        RoyaltifyMarketplace marketplace = new RoyaltifyMarketplace(100, feeRecipient);

        vm.stopBroadcast();

        console2.log("RoyaltifyNFT:", address(nft));
        console2.log("RoyaltifyMarketplace:", address(marketplace));
    }
}
