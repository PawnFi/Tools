// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;
pragma abicoder v2;

interface INftController {
    function getFeeInfo(address nftAddr) external view returns(uint256 randFee, uint256 noRandFee);
}