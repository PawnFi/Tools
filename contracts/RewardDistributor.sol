// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./MerkleVerifier.sol";

contract RewardDistributor is Ownable {
    using SafeERC20 for IERC20;
    uint256 public reclaimPeriod;
    address public token;
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public claimed;

    event Claimed(address account, uint256 amount);

    constructor(address _token, bytes32 _merkleRoot, uint256 reclaimDelay) {
        token = _token;
        merkleRoot = _merkleRoot;
        reclaimPeriod = block.timestamp + reclaimDelay;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function claim(
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) external {
        bytes32 leaf = keccak256(abi.encodePacked(account, amount));
        require(!claimed[leaf], "Airdrop already claimed");
        MerkleVerifier._verifyProof(leaf, merkleRoot, proof);
        claimed[leaf] = true;

        IERC20(token).safeTransfer(account, amount);

        emit Claimed(account, amount);
    }

    function reclaim(uint256 amount) external onlyOwner {
        require(block.timestamp > reclaimPeriod, "Tokens cannot be reclaimed");
        IERC20(token).safeTransfer(msg.sender, amount);
    }
}