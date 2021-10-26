pragma solidity ^0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import { IPangolinRouter, IPangolinFactory, TokenInterface } from "./interfaces.sol";
import "./library.sol";

contract Helpers is DSMath {
    /**
     * @dev get Avalanche address
     */
    function getAVAXAddr() public pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }
}

contract PangolinHelpers is Helpers {
    using SafeMath for uint256;

    /**
     * @dev Return WAVAX address
     */
    function getAddressWAVAX() internal pure returns (address) {
        return 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7; // mainnet
        // return 0xd00ae08403B9bbb9124bB305C09058E32C39A48c; // fuji
    }

    /**
     * @dev Return Pangolin router Address
     */
    function getPangolinAddr() internal pure returns (address) {
        return 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106;
    }

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    function changeAVAXAddress(address buy, address sell)
        internal
        pure
        returns (TokenInterface _buy, TokenInterface _sell)
    {
        _buy = buy == getAVAXAddr() ? TokenInterface(getAddressWAVAX()) : TokenInterface(buy);
        _sell = sell == getAVAXAddr() ? TokenInterface(getAddressWAVAX()) : TokenInterface(sell);
    }

    function getExpectedBuyAmt(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt
    ) internal view returns (uint256 buyAmt) {
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
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
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
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
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
        address exchangeAddr = IPangolinFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
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
}
