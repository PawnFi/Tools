// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Pawnfi's RewardDistributor Contract
 * @author Pawnfi
 */
contract RewardDistributor is Ownable {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    /// @notice Centralize the address of the signature
    address public signer;

    /// @notice Record the status the signature has become invalid or not
    mapping (bytes32 => bool) public invalidation;

    /// @notice keccak256("Distribute(address receiver,address[] tokens,uint256[] amounts,bytes data,uint256 deadline)")
    bytes32 public immutable DISTRIBUTE_HASH = 0xf92e49e4ca5de79292dd113e6194c7620e8e25678cde2316b229f5d75af1c2b2;

    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice Emitted when distribute ERC-20 token
    event Distribute(bytes32 indexed hash, address indexed receiver, address[] tokens, uint256[] amounts, bytes data);

    /**
     * @notice Initialize parameters
     * @param signer_ signer address
     */
    constructor(address  signer_) {
        signer = signer_;
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("RewardDistributor")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    receive() external payable {}

    /**
     * @notice Withdraw the balance in the contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @notice Token distribution through signature
     * @param receiver Receiver address
     * @param tokens Token address array
     * @param amounts Token distribution amount
     * @param data extra data
     * @param deadline The timestamp of the valid signature
     * @param sig Signature
     */
    function distribute(address receiver, address[] memory tokens, uint[] memory amounts, bytes memory data, uint256 deadline, bytes memory sig) external {
        require(deadline == 0 || deadline >= block.timestamp, "expired deadline");
        bytes32 digest = hashTypeData(receiver, tokens, amounts, data, deadline);
        require(!invalidation[digest],"signature expiration");
        invalidation[digest] = true;
        address _signer = digest.recover(sig);
        require(_signer == signer && _signer != address(0), "invalid signature");
        for(uint i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(receiver, amounts[i]);
        }
        emit Distribute(digest, receiver, tokens, amounts, data);
    }

    /**
     * @notice Getting the digest of the data hash
     * @param receiver Receiver address
     * @param tokens Token address array
     * @param amounts Token distribution amount
     * @param data extra data
     * @param deadline The timestamp of the valid signature
     * @return digest digest
     */
    function hashTypeData(address receiver, address[] memory tokens, uint[] memory amounts, bytes memory data, uint256 deadline) public view returns(bytes32 digest) {
        bytes32 structHash = keccak256(abi.encode(
            DISTRIBUTE_HASH,
            receiver,
            keccak256(abi.encodePacked(tokens)),
            keccak256(abi.encodePacked(amounts)),
            keccak256(data),
            deadline
        ));

        digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    }

    /**
     * @notice Set signature address
     * @param newSigner New signature address
     */
    function setSigner(address newSigner) public onlyOwner {
        signer = newSigner;
    }
}