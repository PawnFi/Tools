//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC-1000 standard.
 */
interface IERC1000 {
    /*** ERC20 events ***/

    /**
     * @dev Emitted when `amount` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event ERC20Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event ERC20Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 tokenId);

    /*** ERC721 events ***/

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*** ERC1000 events ***/

    enum TradeType {
        Random,
        Specific
    }

    /**
     * @dev Emitted when `account` exchanges tokens for Nft.
     */
    event Trade(address indexed account, TradeType indexed tradeType, uint256[] tokenId);

    /**
     * @dev Emitted when `borrower` collateralizes Nft to borrow tokens.
     */
    event Borrow(address indexed borrower, uint256[] tokenId, uint256 endBlock, uint256 price, uint256 amount);

    /**
     * @dev Emitted when `payer` redeems Nft.
     */
    event Redeem(address indexed payer, uint256[] tokenIds, uint256[] amounts);

    /**
     * @dev Emitted when `payer` purchases Nft.
     */
    event Purchase(address indexed payer, uint256[] tokenIds, uint256[] amounts);

    /*** ERC20 interfaces ***/

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /*** ERC721 interfaces ***/

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev This function assumes id / native if amount less than or equal to current max id
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC-721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /*** ERC1000 interfaces  ***/

    /**
     * @dev Randomly exchange an Nft and pay the exchange fee.
     */
    function randomTrade(uint256 number) external returns (uint256[] memory tokenIds);

    /**
     * @dev Specify the exchange of an Nft Id and pay the exchange fee.
     */
    function specificTrade(uint256[] calldata tokenIds) external;

    /**
     * @dev Pledge an Nft Id and borrow tokens.
     */
    function borrow(uint256[] calldata tokenIds, uint256 blocks, uint256 price) external;

    /**
     * @dev Purchase/Redeem Nft Id.
     */
    function redeemOrPurchase(uint256[] calldata tokenIds) external;

    /**
     * @dev Return the borrowed amount for the Nft Id.
     */
    function oustandingLoanBalance(uint256 tokenId) external view returns (uint256);

    function fragments() external view returns (uint256);

    function mintNft(address receiver, uint256 amount) external;

    function feeInfo() external view returns (uint256 randomTradeFee, uint256 specificTradeFee, uint256 purchaseFee, address feeReceiver);

    function borrowInfos(uint256 tokenId) external view returns (
        address borrower,
        uint256 loanquantum,
        uint256 startBlockNumber,
        uint256 endBlockNumber,
        uint256 price
    );
}