// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;
pragma abicoder v2;

interface IApproveTrade {

    struct Order {
        address maker; // maker of the order
        address taker; // taker of the order
        address collection; // collection address
        address assetClass; // asset class (e.g., ERC721)
        address currency; // currency (e.g., WETH)
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        uint256 deadline; // deadline in timestamp - 0 for no expiry
        bytes sig;
    }

    function matchAskWithTakerBid(Order memory buy, Order memory sell) external payable;
}