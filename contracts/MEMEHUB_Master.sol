//Powered by https://memehub.ai
//Website:https://memehub.ai
//Telegram:https://t.me/memehubai
//X(Twitter):https://x.com/memehubai

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.25;

import { SafeTransferLib } from "./utils/SafeTransferLib.sol";
import { IUniswapV2Router02 } from "./interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";
import { MEMEHUB_Token } from "./MEMEHUB_Token.sol";

import "hardhat/console.sol";

/**
 * @title MEMEHUB_Master
 * @notice This contract may be replaced by other strategies in the future.A MemeHub protocol graduation strategy for bootstrapping liquidity on uni-v2 AMMs.
 */
contract MEMEHUB_Master {
    error MEMEHUB_Forbidden();
    error MEMEHUB_InvalidAmountToken();
    error MEMEHUB_InvalidAmountEth();

    address public immutable bond;
    IUniswapV2Router02 public immutable uniswapV2Router02;

    address public constant liquidityOwner = address(0xf651F9ba692ada64e6f2EC9Ba416f2D611d4d4EA); //test

    MEMEHUB_Token[] public addedLiquidityToken;

    constructor(address _bond, IUniswapV2Router02 _uniswapV2Router02) {
        bond = _bond;
        uniswapV2Router02 = IUniswapV2Router02(payable(_uniswapV2Router02));
    }

    modifier onlybond() {
        if (msg.sender != bond) revert MEMEHUB_Forbidden();
        _;
    }

    event MemeHubAddLiquidity(
        MEMEHUB_Token indexed token,
        address indexed pair,
        uint256 amountETH,
        uint256 amountToken
    );

    /**
     * @dev Add liquidity.
     * @param token The token to add liquidity.
     * @param amountToken The amountToken to add liquidity.
     * @param amountEth The amountEth to add liquidity.
     * @return _amountToken Add liquidity to the number of tokens.
     * @return _amountETH Add liquidity to the number of eth.
     */
    function execute(
        MEMEHUB_Token token,
        uint256 amountToken,
        uint256 amountEth
    ) external payable onlybond returns (uint256 _amountToken, uint256 _amountETH) {
        if (amountToken == 0) revert MEMEHUB_InvalidAmountToken();
        if (amountEth == 0 || msg.value != amountEth) revert MEMEHUB_InvalidAmountEth();

        SafeTransferLib.safeTransferFrom(token, msg.sender, address(this), amountToken);
        SafeTransferLib.safeApprove(token, address(uniswapV2Router02), amountToken);

        address pair = IUniswapV2Factory(uniswapV2Router02.factory()).createPair(
            address(token),
            uniswapV2Router02.WETH()
        );
        (_amountToken, _amountETH, ) = uniswapV2Router02.addLiquidityETH{ value: amountEth }(
            address(token),
            amountToken,
            0,
            0,
            liquidityOwner,
            block.timestamp
        );

        addedLiquidityToken.push(token);

        emit MemeHubAddLiquidity(token, pair, _amountETH, _amountToken);
    }

    function getToken() external view returns (MEMEHUB_Token[] memory) {
        return addedLiquidityToken;
    }
}
