// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;
pragma abicoder v2;

interface INftSale {

    struct SaleInfo {
        address userAddr;
        address nftAddr;
        uint256 nftId;
        uint256 salePrice; // 0:borrowing
        uint256 startBlock;
        uint256 endBlock;
        uint256 lockEndBlock;
        uint256 lockFeeRate;
        uint256 lockFeePayed;
        uint256 piecePayed; // Prepaid fee
    }

    function delegateCreate(address userAddr, address nftAddr, uint256 nftId, uint256 blockCount, uint256 salePrice) external;

    function buy(address,uint256) external;

    function getNftSaleInfo(address nftAddr, uint256 nftId) external view returns(SaleInfo memory);

    function DELEGATE_ROLE() external view returns(bytes32);
    function grantRole(bytes32 role, address account) external;
}
