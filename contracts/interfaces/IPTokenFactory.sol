// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

interface IPTokenFactory {
    function controller() external view returns(address);
    function nftTransferManager() external view returns(address);
    function getNftAddress(address ptokenAddr) external view returns(address);
}