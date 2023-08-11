// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "./uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "./uniswap/v3-periphery/contracts/libraries/Path.sol";
import "./interfaces/IV3SwapRouter.sol";
import "./interfaces/IPTokenFactory.sol";
import "./interfaces/INftController.sol";
import "./interfaces/IPToken.sol";
import "./interfaces/INftSale.sol";
import "./interfaces/IApproveTrade.sol";
import "./libraries/TransferHelper.sol";

/**
 * @title Pawnfi's NftFastSwapForSwapV3 Contract
 * @author Pawnfi
 */
contract NftFastSwapForSwapV3 is OwnableUpgradeable, ERC721HolderUpgradeable, ERC1155HolderUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Path for bytes;

    // Identifier of ERC721
    address private constant ERC721 = 0x0000000000000000000000000000000000000721;

    // Identifier of ERC1155
    address private constant ERC1155 = 0x0000000000000000000000000000000000001155;

    /// @notice WETH contract address
    address public WETH;

    /// @notice univ3 swap contract address
    address public uniswapRouter;

    /// @notice univ3 quoter contract address
    address public quoter;

    /// @notice ptoken factory contract address
    address public pieceFactory;

    /// @notice nft controller contract address
    address public nftController;

    /// @notice nft transfer manager contract address
    address public transferManager;

    /// @notice nft consign contract address
    address public nftSale;
    
    /// @notice Listing/offer contract address
    address public approveTrade;

    /// @notice Token whitelist for swap nft to ERC-20 tokens
    mapping(address => bool) public tokenWhitelist;

    /// @notice Emitted when setting token whitelist
    event SetTokenWhitelist(address indexed token, bool added);

    /**
     * @notice Initialize contract parameters - only execute once
     * @param uniswapRouter_ univ3 swap contract address
     * @param quoter_ univ3 quoter contract address
     * @param pieceFactory_ ptoken factory contract address
     * @param nftSale_ nft consign contract address
     * @param approveTrade_ Listing/offer contract address
     */
    function initialize(address owner_, address uniswapRouter_, address quoter_, address pieceFactory_, address nftSale_, address approveTrade_) external initializer {
        _transferOwnership(owner_);
        __ERC721Holder_init();
        __ERC1155Holder_init();
        uniswapRouter = uniswapRouter_;
        quoter = quoter_;
        pieceFactory = pieceFactory_;
        nftController = IPTokenFactory(pieceFactory_).controller();
        transferManager = IPTokenFactory(pieceFactory_).nftTransferManager();
        WETH = IV3SwapRouter(uniswapRouter_).WETH9();
        nftSale = nftSale_;
        approveTrade = approveTrade_;
    }

    /**
     * @notice Set token whitelist
     * @param token token address
     * @param added Set token whitelist
     */
    function setTokenWhitelist(address token, bool added) external onlyOwner {
        _setTokenWhitelist(token, added);
    }

    /**
     * @notice Set token whitelist
     * @param tokens token address array
     * @param added Set token whitelist
     */
    function setMultipleTokenWhitelist(address[] calldata tokens, bool added) external onlyOwner {
        for(uint i = 0; i < tokens.length; i++) {
            _setTokenWhitelist(tokens[i], added);
        }
    }

    /**
     * @notice Set token whitelist
     * @param token token address
     * @param added Set token whitelist
     */
    function _setTokenWhitelist(address token, bool added) private {
        tokenWhitelist[token] = added;
        emit SetTokenWhitelist(token, added);
    }

    /**
     * @notice Swap nft to token(random)
     * @param nftIds nft id array
     * @param amountOutMin Min output amount
     * @param path token swap router
     */
    function swapNFTForTokens(uint256[] memory nftIds, uint256 amountOutMin, bytes memory path) external onlyEOA {
        require(nftIds.length > 0, "nft ids incorrect length");

        (address tokenIn, address tokenOut) = getFirstAndLastToken(path);
        require(tokenWhitelist[tokenOut], "tokenOut is not in the token whitelist");
        address nftAddr = getNftAddress(tokenIn);

        _swapNFTForTokenBefore(nftAddr, tokenIn, nftIds);

        IPToken(tokenIn).deposit(nftIds);

        _swapNFTForTokenAfter(tokenIn, tokenOut, msg.sender, path, amountOutMin);
        
    }

    /**
     * @notice Swap nft to token(consign)
     * @param nftId nft id
     * @param amountOutMin Min output amount
     * @param path token swap router
     * @param blockCount Lock-up block amount
     * @param salePrice Sale price in ptoken
     */
    function swapSingleNFTForTokens(uint256 nftId, uint256 amountOutMin, bytes memory path, uint256 blockCount, uint256 salePrice) external onlyEOA {

        (address tokenIn, address tokenOut) = getFirstAndLastToken(path);
        require(tokenWhitelist[tokenOut], "tokenOut is not in the token whitelist");
        address nftAddr = getNftAddress(tokenIn);

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;
        _swapNFTForTokenBefore(nftAddr, nftSale, nftIds);
        
        INftSale(nftSale).delegateCreate(msg.sender, nftAddr, nftId, blockCount, salePrice);

        _swapNFTForTokenAfter(tokenIn, tokenOut, msg.sender, path, amountOutMin);
    }

    /**
     * @notice Receive nft
     * @param nftAddr nft address
     * @param spender nft sender
     * @param nftIds nft id list
     */
    function _swapNFTForTokenBefore(address nftAddr, address spender, uint256[] memory nftIds) private {
        for(uint i = 0; i < nftIds.length; i++) {
            TransferHelper.transferInNonFungibleToken(transferManager, nftAddr, msg.sender, address(this), nftIds[i]);
            TransferHelper.approveNonFungibleToken(transferManager, nftAddr, address(this), spender, nftIds[i]);
        }
    }

    /**
     * @notice Swap ptoken to specific token
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param to The recipient of the output token
     * @param path token swap router
     * @param amountOutMin Min output amount
     */
    function _swapNFTForTokenAfter(address tokenIn, address tokenOut, address to, bytes memory path, uint256 amountOutMin) private {
        uint256 balance = _tokenApprove(tokenIn, uniswapRouter);
        address recipient = tokenOut == WETH ? address(this) : to;
        
        IV3SwapRouter.ExactInputParams memory params = IV3SwapRouter.ExactInputParams({
            path: path,
            recipient: recipient,
            amountIn: balance,
            amountOutMinimum: amountOutMin
        });
        IV3SwapRouter(uniswapRouter).exactInput(params);
        _sweepToken(tokenIn, to);
        _sweepToken(tokenOut, to);
    }

    /**
     * @notice Swap token to NFT (random)
     * @param number NFT swap amount
     * @param amountInMax Max input amount
     * @param path token swap router
     */
    function swapTokensForNFT(uint256 number, uint256 amountInMax, bytes memory path) external payable onlyEOA {
        require(number > 0, "number must greater than zero");

        (address tokenOut, address tokenIn) = getFirstAndLastToken(path);

        (uint256 randAmount, ) = calculatePtokenAmount(tokenOut, number);
        _swapTokenForNFTBefore(tokenIn, amountInMax, randAmount, path);

        uint256[] memory nftIds = IPToken(tokenOut).randomTrade(number);

        address nftAddr = getNftAddress(tokenOut);
        _swapTokenForNFTAfter(tokenIn, tokenOut, nftAddr, msg.sender, nftIds);
    }

    /**
     * @notice Swap token to NFT (specific)
     * @param nftIds nft id array
     * @param amountInMax Max input amount
     * @param path token swap router
     */
    function swapTokensForSpecifiedNFT(uint256[] memory nftIds, uint256 amountInMax, bytes memory path) external payable onlyEOA {
        uint256 length = nftIds.length;
        require(length > 0, "length must greater than zero");

        (address tokenOut, address tokenIn) = getFirstAndLastToken(path);

        (, uint256 specifiedAmount) = calculatePtokenAmount(tokenOut, length);
        _swapTokenForNFTBefore(tokenIn, amountInMax, specifiedAmount, path);

        IPToken(tokenOut).specificTrade(nftIds);
        address nftAddr = getNftAddress(tokenOut);
        _swapTokenForNFTAfter(tokenIn, tokenOut, nftAddr, msg.sender, nftIds);
    }

    /**
     * @notice Swap token to NFT (consign)
     * @param nftId token id
     * @param amountInMax Max input amount
     * @param path token swap router
     */
    function swapTokensForSingleNFT(uint256 nftId, uint256 amountInMax, bytes memory path) external payable onlyEOA {
        (address tokenOut, address tokenIn) = getFirstAndLastToken(path);
        address nftAddr = getNftAddress(tokenOut);
        INftSale.SaleInfo memory saleInfo = INftSale(nftSale).getNftSaleInfo(nftAddr, nftId);
        require(saleInfo.salePrice > 0, "order error");

        _swapTokenForNFTBefore(tokenIn, amountInMax, saleInfo.salePrice, path);

        _tokenApprove(tokenOut, nftSale);
        INftSale(nftSale).buy(nftAddr, nftId);
        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = nftId;
        _swapTokenForNFTAfter(tokenIn, tokenOut, nftAddr, msg.sender, nftIds);
    }

    /**
     * @notice Swap token
     * @param tokenIn Input token
     * @param amountInMax Max input amount
     * @param amountOut Output amount
     * @param path token swap router
     */
    function _swapTokenForNFTBefore(address tokenIn, uint256 amountInMax, uint256 amountOut, bytes memory path) private {
        uint256 amountIn = getAmountIn(amountOut, path);
        require(amountIn <= amountInMax, "exceed amount in max");
        if(tokenIn == WETH && msg.value > 0) {
            IWETH9(tokenIn).deposit{value: amountIn}();
        } else {
            IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        _tokenApprove(tokenIn, uniswapRouter);

        IV3SwapRouter.ExactOutputParams memory params = IV3SwapRouter.ExactOutputParams({
            path: path,
            recipient: address(this),
            amountOut: amountOut,
            amountInMaximum: amountIn
        });
        IV3SwapRouter(uniswapRouter).exactOutput(params);
    }

    /**
     * @notice Send Nft
     * @param tokenIn Input token
     * @param tokenOut Output token
     * @param nftAddr nft contract address
     * @param to The recipient of the output token
     * @param nftIds nft id list
     */
    function _swapTokenForNFTAfter(address tokenIn, address tokenOut, address nftAddr, address to, uint256[] memory nftIds) private {
        for(uint i = 0; i < nftIds.length; i++) {
            TransferHelper.transferOutNonFungibleToken(transferManager, nftAddr, address(this), to, nftIds[i]);
        }
        _sweepToken(tokenIn, to);
        _sweepToken(tokenOut, to);
    }


    /**
     * @notice NFT listing order
     * @param order Order info
     * @param amountInMax Max input amount
     * @param path token swap router
     */
    function swapTokensForNFTOrder(IApproveTrade.Order memory order, uint256 amountInMax, bytes memory path) external payable onlyEOA {
        uint256 amountIn = getAmountIn(order.price, path);
        require(amountIn <= amountInMax, "exceed amount in max");

        (address tokenOut, address tokenIn) = getFirstAndLastToken(path);
        if (tokenIn == WETH && msg.value >= amountIn) {
            IWETH9(tokenIn).deposit{value: amountIn}();
        } else {
            IERC20Upgradeable(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
        }

        _tokenApprove(tokenIn, uniswapRouter);

        IV3SwapRouter.ExactOutputParams memory params = IV3SwapRouter.ExactOutputParams({
            path: path,
            recipient: address(this),
            amountOut: order.price,
            amountInMaximum: amountIn
        });
        IV3SwapRouter(uniswapRouter).exactOutput(params);

        uint256 msgValue;
        if (tokenOut == WETH) {
            msgValue = order.price;
            IWETH9(tokenOut).withdraw(msgValue);
        } else {
            _tokenApprove(tokenOut, approveTrade);
        }

        IApproveTrade.Order memory buy = IApproveTrade.Order({
            maker: address(this),
            taker: address(0),
            collection: order.collection,
            assetClass: order.assetClass,
            currency: order.currency,
            price: order.price,
            tokenId: order.tokenId,
            amount: order.amount,
            deadline: block.timestamp,
            sig: new bytes(0)
        });
        IApproveTrade(approveTrade).matchAskWithTakerBid{value: msgValue}(buy, order);
        _transferNonFungibleToken(order.collection, order.assetClass, address(this), msg.sender, order.tokenId, order.amount);
        _sweepToken(tokenIn, msg.sender);
        _sweepToken(tokenOut, msg.sender);
    }

    /**
     * @notice Send NFT
     * @param token token address
     * @param assetClass tokentype
     * @param from Sender
     * @param to The recipient of NFT
     * @param tokenId token id
     * @param amount token amount
     */
    function _transferNonFungibleToken(address token, address assetClass, address from, address to, uint256 tokenId, uint256 amount) internal {
        if (assetClass == ERC721) {
            TransferHelper.transferOutNonFungibleToken(transferManager, token, from, to, tokenId);
        } else {
            IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, amount, "0x");
        }
    }

    /**
     * @notice Retrieving the addresses of the first and last tokens in the transaction path
     * @param path transaction path
     * @return firstToken address of the first token
     * @return lastToken address of the last token
     */
    function getFirstAndLastToken(bytes memory path) public pure returns (address firstToken, address lastToken) {
        while (true) {
            (address tokenA, address tokenB, ) = path.decodeFirstPool();
            if (firstToken == address(0)) {
                firstToken = tokenA;
            }
            // decide whether to continue or terminate
            if (path.hasMultiplePools()) {
                path = path.skipToken();
            } else {
                lastToken = tokenB;
                break;
            }
        }
    }

    /**
     * @notice Get the NFT address based on the ptoken address
     * @param ptoken ptoken contract address
     * @return nftAddr nft contract address
     */
    function getNftAddress(address ptoken) public view returns (address nftAddr) {
        nftAddr = IPTokenFactory(pieceFactory).getNftAddress(ptoken);
        require(nftAddr != address(0), "nft address is zero");
    }

    /**
     * @notice Calculate the number of ptoken required to swap NFTs in different ways
     * @param ptoken ptoken contract address
     * @param number nft amount
     * @return randAmount The number of ptoken required to swap random NFT
     * @return specifiedAmount The number of ptoken required to swap specific NFT
     */
    function calculatePtokenAmount(address ptoken, uint256 number) public view returns (uint256 randAmount, uint256 specifiedAmount) {
        address nftAddr = getNftAddress(ptoken);
        uint256 pieceCount = IPToken(ptoken).pieceCount();

        (uint256 randFee, uint256 specifiedFee) = INftController(nftController).getFeeInfo(nftAddr);
        randAmount = (pieceCount + randFee) * number;
        specifiedAmount = (pieceCount + specifiedFee) * number;
    }

    /**
     * @notice Determining the output amount of the last token in the path array based on the given input amount
     * @param amountIn Input amount
     * @param path token swap router
     * @return amountOut the output amount of the last token in the path array
     */
    function getAmountOut(uint amountIn, bytes memory path) public returns (uint amountOut) {
        amountOut = IQuoter(quoter).quoteExactInput(path, amountIn);
    }

    /**
     * @notice Determining the input amount of the first token in the path array based on the given output amount
     * @param amountOut given output amount
     * @param path token swap router
     * @return amountIn input amount
     */
    function getAmountIn(uint amountOut, bytes memory path) public returns (uint256 amountIn) {
        amountIn = IQuoter(quoter).quoteExactOutput(path, amountOut);
    }

    /**
     * @notice token approval
     * @param token token address
     * @param spender Approved address
     * @return balance token balance
     */
    function _tokenApprove(address token, address spender) private returns (uint256 balance) {
        balance = IERC20Upgradeable(token).balanceOf(address(this));
        if (IERC20Upgradeable(token).allowance(address(this), spender) < balance) {
            IERC20Upgradeable(token).safeApprove(spender, 0);
            IERC20Upgradeable(token).safeApprove(spender, type(uint256).max);
        }
    }

    /**
     * @notice Return extra token
     * @param token token address
     * @param recipient The recipient of the token
     */
    function _sweepToken(address token, address recipient) private {
        uint256 remainingBalance = IERC20Upgradeable(token).balanceOf(address(this));
        if (token == WETH) {
            IWETH9(WETH).withdraw(remainingBalance);
            payable(recipient).transfer(address(this).balance);
        } else {
            if (remainingBalance > 0) {
                IERC20Upgradeable(token).safeTransfer(recipient, remainingBalance);
            }
        }
    }

    receive() external payable {}


    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA");
        _;
    }

}