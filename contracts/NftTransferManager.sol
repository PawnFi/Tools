// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

/**
 * @title Pawnfi's NftTransferManager Contract
 * @author Pawnfi
 */
contract NftTransferManager is OwnableUpgradeable, Multicall {

    // keccak256("TRANSFER_IN")
    bytes32 private constant TRANSFER_IN = 0xe69a0828d85fdb5875ad77f7b8a0e2275447a64f18daaf58f34b3af9b7b691da;

    // keccak256("TRANSFER_OUT")
    bytes32 private constant TRANSFER_OUT = 0x2b6780fa84213a97faf5c6208861692a9b75df0c4afffad07a2dc98411dfe785;

    // keccak256("APPROVAL")
    bytes32 private constant APPROVAL = 0x2acd155ba8c67e9321668716d05aae1ff9e47e502b6b2f301b6f41e3a57ee2ef;

    /**
     * @notice The set of operations for transferring NFT
     * @member selector Function selector
     * @member byteLength Length of byte in call parameters
     * @member parameters Fill in parameters (from, to, tokenId) => (true, true, true)
     */
    struct OperationSet {
        bytes4 selector;
        uint256 byteLength;
        bool[] parameters;
    }

    /// @notice Data set of different NFT operations
    mapping(address => mapping(bytes32 => OperationSet)) public operationSet;

    /**
     * @notice Initialize contract parameters
     * @param owner_ Owner
     */
    function initialize(address owner_) external initializer {
        _transferOwnership(owner_);
    }
    
    /**
     * @notice Set corresponding data of NFT operation - exclusive to owner
     * @param nftAddress Token address
     * @param transerIn Data structure of transfer-in operation
     * @param transferOut Data structure of transfer-out operation
     * @param approval Data structure of approval
     */
    function setOperationSet(address nftAddress, OperationSet memory transerIn, OperationSet memory transferOut, OperationSet memory approval) external onlyOwner {
        operationSet[nftAddress][TRANSFER_IN] = transerIn;
        operationSet[nftAddress][TRANSFER_OUT] = transferOut;
        operationSet[nftAddress][APPROVAL] = approval;
    }

    /**
     * @notice The call data of different operations on NFTs
     * @param nftAddress nft address
     * @param from The sender address
     * @param to The recipient address
     * @param tokenId Nft Id
     * @param operateType Operation type
     * @return data The call data of operation
     */
    function getInputData(address nftAddress, address from, address to, uint256 tokenId, bytes32 operateType) public view returns (bytes memory data) {
        OperationSet memory opSet = operationSet[nftAddress][operateType];

        if(opSet.selector == bytes4(0)) {
            bool[] memory parameters = new bool[](3);
            if(operateType == APPROVAL) {
                // keccak256('approve(address,uint256)')
                parameters[0] = false; parameters[1] = true; parameters[2] = true;
                opSet = OperationSet({selector: bytes4(0x095ea7b3), byteLength: 68, parameters: parameters});
            } else {
                // keccak256('safeTransferFrom(address,address,uint256)')
                parameters[0] = true; parameters[1] = true; parameters[2] = true;
                opSet = OperationSet({selector: bytes4(0x42842e0e), byteLength: 100, parameters: parameters});
            }
        }

        bytes memory params = abi.encode(from, to, tokenId);
        data = new bytes(opSet.byteLength);
        uint index = 0;
        for(uint i = 0; i < opSet.selector.length; i++) {
            data[index] = opSet.selector[i];
            index++;
        }
        for(uint i = 0; i < opSet.parameters.length; i++) {
            if(opSet.parameters[i]) {
                uint startIndex = i *  32;
                for(uint j = startIndex; j < startIndex + 32; j++) {
                    data[index] = params[j];
                    index++;
                }
            }
        }
    }

    /**
     * @notice Transfer nft in batch
     * @param nftAddress nft address
     * @param to The recipient address
     * @param nftIds ID array of NFTs to be transferred
     */
    function batchTransferNft(address nftAddress, address to, uint256[] calldata nftIds) external {
        for(uint i = 0; i < nftIds.length; i++) {
            transferNft(nftAddress, to, nftIds[i]);
        }
    }

    /**
     * @notice Transfer single nft
     * @param nftAddress nft address
     * @param to The recipient address
     * @param nftId id of NFT to be transferred
     */
    function transferNft(address nftAddress, address to, uint256 nftId) public {
        Address.functionCall(nftAddress, getInputData(nftAddress, msg.sender, to, nftId, TRANSFER_OUT));
    }
}