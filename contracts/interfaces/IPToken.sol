// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IPToken {

    function pieceCount() external view returns(uint256);

    function randomTrade(uint256 nftIdCount) external returns(uint256[] memory nftIds);

    function specificTrade(uint256[] memory nftIds) external;

    function deposit(uint256[] memory nftIds) external returns(uint256 tokenAmount);
}
    