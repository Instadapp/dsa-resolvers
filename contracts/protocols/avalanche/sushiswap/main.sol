pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

/**
 * @title SushiSwap.
 * @dev Decentralized Exchange.
 */

import { Helpers, ISushiSwapRouter, ISushiSwapFactory, ISushiSwapPair, TokenInterface } from "./helpers.sol";

abstract contract SushipswapResolver is Helpers {
    function getBuyAmount(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 slippage
    ) public view returns (uint256 buyAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeAvaxAddress(buyAddr, sellAddr);
        buyAmt = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 slippage
    ) public view returns (uint256 sellAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeAvaxAddress(buyAddr, sellAddr);
        sellAmt = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippageA,
        uint256 slippageB
    )
        public
        view
        returns (
            uint256 amountB,
            uint256 uniAmount,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAvaxAddress(tokenA, tokenB);
        ISushiSwapRouter router = ISushiSwapRouter(getSushiSwapAddr());
        ISushiSwapFactory factory = ISushiSwapFactory(router.factory());
        ISushiSwapPair lpToken = ISushiSwapPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        amountB = router.quote(amountA, reserveA, reserveB);

        uniAmount = mul(amountA, lpToken.totalSupply());
        uniAmount = uniAmount / reserveA;

        amountAMin = wmul(sub(WAD, slippageA), amountA);
        amountBMin = wmul(sub(WAD, slippageB), amountB);
    }

    function getSingleDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 uniAmt,
            uint256 minUniAmt
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAvaxAddress(tokenA, tokenB);
        ISushiSwapRouter router = ISushiSwapRouter(getSushiSwapAddr());
        ISushiSwapFactory factory = ISushiSwapFactory(router.factory());
        ISushiSwapPair lpToken = ISushiSwapPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 swapAmtA = calculateSwapInAmount(reserveA, amountA);

        amtB = getExpectedBuyAmt(address(_tokenB), address(_tokenA), swapAmtA);
        amtA = sub(amountA, swapAmtA);

        uniAmt = mul(amtA, lpToken.totalSupply());
        uniAmt = uniAmt / add(reserveA, swapAmtA);

        minUniAmt = wmul(sub(WAD, slippage), uniAmt);
    }

    function getDepositAmountNewPool(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 amtB
    ) public view returns (uint256 unitAmt) {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAvaxAddress(tokenA, tokenB);
        ISushiSwapRouter router = ISushiSwapRouter(getSushiSwapAddr());
        address exchangeAddr = ISushiSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr == address(0), "pair-found.");
        uint256 _amtA18 = convertTo18(_tokenA.decimals(), amtA);
        uint256 _amtB18 = convertTo18(_tokenB.decimals(), amtB);
        unitAmt = wdiv(_amtB18, _amtA18);
    }

    function getWithdrawAmounts(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 unitAmtA,
            uint256 unitAmtB
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAvaxAddress(tokenA, tokenB);
        (amtA, amtB) = _getWithdrawAmts(_tokenA, _tokenB, uniAmt);
        (unitAmtA, unitAmtB) = _getWithdrawUnitAmts(_tokenA, _tokenB, amtA, amtB, uniAmt, slippage);
    }

    struct TokenPair {
        address tokenA;
        address tokenB;
    }

    function getPositionByPair(address owner, TokenPair[] memory tokenPairs) public view returns (PoolData[] memory) {
        ISushiSwapRouter router = ISushiSwapRouter(getSushiSwapAddr());
        uint256 _len = tokenPairs.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            (TokenInterface tokenA, TokenInterface tokenB) = changeAvaxAddress(
                tokenPairs[i].tokenA,
                tokenPairs[i].tokenB
            );
            address exchangeAddr = ISushiSwapFactory(router.factory()).getPair(address(tokenA), address(tokenB));
            if (exchangeAddr != address(0)) {
                ISushiSwapPair lpToken = ISushiSwapPair(exchangeAddr);
                (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
                (reserveA, reserveB) = lpToken.token0() == address(tokenA)
                    ? (reserveA, reserveB)
                    : (reserveB, reserveA);

                uint256 lpAmount = lpToken.balanceOf(owner);
                uint256 totalSupply = lpToken.totalSupply();
                uint256 share = wdiv(lpAmount, totalSupply);
                uint256 amtA = wmul(reserveA, share);
                uint256 amtB = wmul(reserveB, share);
                poolData[i] = PoolData(
                    address(0),
                    address(0),
                    address(lpToken),
                    reserveA,
                    reserveB,
                    amtA,
                    amtB,
                    0,
                    0,
                    lpAmount,
                    totalSupply
                );
            }
            poolData[i].tokenA = tokenPairs[i].tokenA;
            poolData[i].tokenB = tokenPairs[i].tokenB;
            poolData[i].tokenABalance = tokenPairs[i].tokenA == getAvaxAddr() ? owner.balance : tokenA.balanceOf(owner);
            poolData[i].tokenBBalance = tokenPairs[i].tokenB == getAvaxAddr() ? owner.balance : tokenB.balanceOf(owner);
        }
        return poolData;
    }

    function getPosition(address owner, address[] memory lpTokens) public view returns (PoolData[] memory) {
        uint256 _len = lpTokens.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            address lpTokenAddr = lpTokens[i];
            poolData[i] = _getPoolData(lpTokenAddr, owner);
        }
        return poolData;
    }
}

contract InstaSushiSwapResolverAvalanche is SushipswapResolver {
    string public constant name = "Sushiswap-Resolver-v1.1";
}
