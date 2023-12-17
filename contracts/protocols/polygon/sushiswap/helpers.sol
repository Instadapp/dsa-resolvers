pragma solidity ^0.8.12;

import { DSMath } from "../../../utils/dsmath.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { ISushiSwapRouter, ISushiSwapFactory, ISushiSwapPair, TokenInterface } from "./interfaces.sol";

library Babylonian {
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

abstract contract Helpers is DSMath {
    using SafeMath for uint256;
    /**
     * @dev ISushiSwapRouter
     */
    ISushiSwapRouter internal constant router = ISushiSwapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;

    function getExpectedBuyAmt(address[] memory paths, uint256 sellAmt) internal view returns (uint256 buyAmt) {
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function changeEthAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == ethAddr ? TokenInterface(wethAddr) : TokenInterface(buy);
        _sell = sell == ethAddr ? TokenInterface(wethAddr) : TokenInterface(sell);
    }

    function convertEthToWeth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) token.deposit{ value: amount }();
    }

    function convertWethToEth(
        bool isEth,
        TokenInterface token,
        uint256 amount
    ) internal {
        if (isEth) {
            approve(token, address(token), amount);
            token.withdraw(amount);
        }
    }

    function approve(
        TokenInterface token,
        address spender,
        uint256 amount
    ) internal {
        try token.approve(spender, amount) {} catch {
            token.approve(spender, 0);
            token.approve(spender, amount);
        }
    }

    function getTokenBal(TokenInterface token) internal view returns (uint256 _amt) {
        _amt = address(token) == ethAddr ? address(this).balance : token.balanceOf(address(this));
    }

    function getExpectedSellAmt(address[] memory paths, uint256 buyAmt) internal view returns (uint256 sellAmt) {
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function checkPair(address[] memory paths) internal view {
        address pair = ISushiSwapFactory(router.factory()).getPair(paths[0], paths[1]);
        require(pair != address(0), "No-exchange-address");
    }

    function getPaths(address buyAddr, address sellAddr) internal pure returns (address[] memory paths) {
        paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
    }

    function getMinAmount(
        TokenInterface token,
        uint256 amt,
        uint256 slippage
    ) internal view returns (uint256 minAmt) {
        uint256 _amt18 = convertTo18(token.decimals(), amt);
        minAmt = wmul(_amt18, sub(WAD, slippage));
        minAmt = convert18ToDec(token.decimals(), minAmt);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmt,
        uint256 slippage
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _liquidity
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeEthAddress(tokenA, tokenB);

        _amtA = _amt == type(uint256).max ? getTokenBal(TokenInterface(tokenA)) : _amt;
        _amtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmt, convertTo18(_tokenA.decimals(), _amtA)));

        bool isEth = address(_tokenA) == wethAddr;
        convertEthToWeth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertEthToWeth(isEth, _tokenB, _amtB);

        approve(_tokenA, address(router), _amtA);
        approve(_tokenB, address(router), _amtB);

        uint256 minAmtA = getMinAmount(_tokenA, _amtA, slippage);
        uint256 minAmtB = getMinAmount(_tokenB, _amtB, slippage);
        (_amtA, _amtB, _liquidity) = router.addLiquidity(
            address(_tokenA),
            address(_tokenB),
            _amtA,
            _amtB,
            minAmtA,
            minAmtB,
            address(this),
            block.timestamp + 1
        );
    }

    function _removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 _amt,
        uint256 unitAmtA,
        uint256 unitAmtB
    )
        internal
        returns (
            uint256 _amtA,
            uint256 _amtB,
            uint256 _uniAmt
        )
    {
        TokenInterface _tokenA;
        TokenInterface _tokenB;
        (_tokenA, _tokenB, _uniAmt) = _getRemoveLiquidityData(tokenA, tokenB, _amt);
        {
            uint256 minAmtA = convert18ToDec(_tokenA.decimals(), wmul(unitAmtA, _uniAmt));
            uint256 minAmtB = convert18ToDec(_tokenB.decimals(), wmul(unitAmtB, _uniAmt));
            (_amtA, _amtB) = router.removeLiquidity(
                address(_tokenA),
                address(_tokenB),
                _uniAmt,
                minAmtA,
                minAmtB,
                address(this),
                block.timestamp + 1
            );
        }

        bool isEth = address(_tokenA) == wethAddr;
        convertWethToEth(isEth, _tokenA, _amtA);

        isEth = address(_tokenB) == wethAddr;
        convertWethToEth(isEth, _tokenB, _amtB);
    }

    function _getRemoveLiquidityData(
        address tokenA,
        address tokenB,
        uint256 _amt
    )
        internal
        returns (
            TokenInterface _tokenA,
            TokenInterface _tokenB,
            uint256 _uniAmt
        )
    {
        (_tokenA, _tokenB) = changeEthAddress(tokenA, tokenB);
        address exchangeAddr = ISushiSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");

        TokenInterface uniToken = TokenInterface(exchangeAddr);
        _uniAmt = _amt == type(uint256).max ? uniToken.balanceOf(address(this)) : _amt;
        approve(uniToken, address(router), _uniAmt);
    }

    /** resolver part */
    /**
     * @dev get Ethereum address
     */
    function getEthAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     * @dev Return WETH address
     */
    function getAddressWETH() internal pure returns (address) {
        return 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270; // mainnet
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // kovan
    }

    /**
     * @dev Return sushiswap router Address
     */
    function getSushiSwapAddr() internal pure returns (address) {
        return 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    }

    // function convert18ToDec(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    //     amt = (_amt / 10 ** (18 - _dec));
    // }

    // function convertTo18(uint _dec, uint256 _amt) internal pure returns (uint256 amt) {
    //     amt = mul(_amt, 10 ** (18 - _dec));
    // }

    // function changeEthAddress(address buy, address sell) internal pure returns(TokenInterface _buy, TokenInterface _sell){
    //     _buy = buy == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(buy);
    //     _sell = sell == getEthAddr() ? TokenInterface(getAddressWETH()) : TokenInterface(sell);
    // }

    struct PoolData {
        address tokenA;
        address tokenB;
        address lpAddress;
        uint256 reserveA;
        uint256 reserveB;
        uint256 tokenAShareAmt;
        uint256 tokenBShareAmt;
        uint256 tokenABalance;
        uint256 tokenBBalance;
        uint256 lpAmount;
        uint256 totalSupply;
    }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt
    ) internal view returns (uint256 buyAmt) {
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint256[] memory amts = router.getAmountsOut(sellAmt, paths);
        buyAmt = amts[1];
    }

    function getExpectedSellAmt(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt
    ) internal view returns (uint256 sellAmt) {
        address[] memory paths = new address[](2);
        paths[0] = address(sellAddr);
        paths[1] = address(buyAddr);
        uint256[] memory amts = router.getAmountsIn(buyAmt, paths);
        sellAmt = amts[0];
    }

    function getBuyUnitAmt(
        TokenInterface buyAddr,
        uint256 expectedAmt,
        TokenInterface sellAddr,
        uint256 sellAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmt) {
        uint256 _sellAmt = convertTo18((sellAddr).decimals(), sellAmt);
        uint256 _buyAmt = convertTo18(buyAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_buyAmt, _sellAmt);
        unitAmt = wmul(unitAmt, sub(WAD, slippage));
    }

    function getSellUnitAmt(
        TokenInterface sellAddr,
        uint256 expectedAmt,
        TokenInterface buyAddr,
        uint256 buyAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmt) {
        uint256 _buyAmt = convertTo18(buyAddr.decimals(), buyAmt);
        uint256 _sellAmt = convertTo18(sellAddr.decimals(), expectedAmt);
        unitAmt = wdiv(_sellAmt, _buyAmt);
        unitAmt = wmul(unitAmt, add(WAD, slippage));
    }

    function _getWithdrawUnitAmts(
        TokenInterface tokenA,
        TokenInterface tokenB,
        uint256 amtA,
        uint256 amtB,
        uint256 uniAmt,
        uint256 slippage
    ) internal view returns (uint256 unitAmtA, uint256 unitAmtB) {
        uint256 _amtA = convertTo18(tokenA.decimals(), amtA);
        uint256 _amtB = convertTo18(tokenB.decimals(), amtB);
        unitAmtA = wdiv(_amtA, uniAmt);
        unitAmtA = wmul(unitAmtA, sub(WAD, slippage));
        unitAmtB = wdiv(_amtB, uniAmt);
        unitAmtB = wmul(unitAmtB, sub(WAD, slippage));
    }

    function _getWithdrawAmts(
        TokenInterface _tokenA,
        TokenInterface _tokenB,
        uint256 uniAmt
    ) internal view returns (uint256 amtA, uint256 amtB) {
        address exchangeAddr = ISushiSwapFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr != address(0), "pair-not-found.");
        TokenInterface uniToken = TokenInterface(exchangeAddr);
        uint256 share = wdiv(uniAmt, uniToken.totalSupply());
        amtA = wmul(_tokenA.balanceOf(exchangeAddr), share);
        amtB = wmul(_tokenB.balanceOf(exchangeAddr), share);
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn) internal pure returns (uint256) {
        return
            Babylonian.sqrt(reserveIn.mul(userIn.mul(3988000).add(reserveIn.mul(3988009)))).sub(reserveIn.mul(1997)) /
            1994;
    }

    function _getTokenBalance(address token, address owner) internal view returns (uint256) {
        uint256 balance = token == wethAddr ? owner.balance : TokenInterface(token).balanceOf(owner);
        return balance;
    }

    function _getPoolData(address lpTokenAddr, address owner) internal view returns (PoolData memory pool) {
        ISushiSwapPair lpToken = ISushiSwapPair(lpTokenAddr);
        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (address tokenA, address tokenB) = (lpToken.token0(), lpToken.token1());
        uint256 lpAmount = lpToken.balanceOf(owner);
        uint256 totalSupply = lpToken.totalSupply();
        uint256 share = wdiv(lpAmount, totalSupply);
        uint256 amtA = wmul(reserveA, share);
        uint256 amtB = wmul(reserveB, share);
        pool = PoolData(
            tokenA == getAddressWETH() ? getEthAddr() : tokenA,
            tokenB == getAddressWETH() ? getEthAddr() : tokenB,
            address(lpToken),
            reserveA,
            reserveB,
            amtA,
            amtB,
            _getTokenBalance(tokenA, owner),
            _getTokenBalance(tokenB, owner),
            lpAmount,
            totalSupply
        );
    }
}
