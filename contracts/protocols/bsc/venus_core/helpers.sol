// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract VenusCoreHelper is DSMath {
    /**
     *@dev Returns BNB sentinel address
     */
    function getBnbAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     *@dev Returns Venus Core Pool Comptroller (Diamond) on BSC
     */
    function getComptrollerAddr() internal pure returns (address) {
        return 0xfD36E2c2a6789Db23113685031d7F16329158384;
    }

    struct VenusUserData {
        uint256 totalCollateralUSD; // from getAccountLiquidity context
        uint256 totalBorrowsUSD;
        uint256 liquidity; // excess liquidity (based on liquidation threshold)
        uint256 shortfall; // shortfall (based on liquidation threshold)
        uint256 borrowingLiquidity; // excess liquidity (based on collateral factor)
        uint256 borrowingShortfall; // shortfall (based on collateral factor)
        uint256 xvsAccrued; // pending XVS rewards
    }

    struct VenusUserMarketData {
        uint256 vTokenBalance; // user's vToken balance
        uint256 supplyBalanceUnderlying; // supply balance in underlying
        uint256 borrowBalance; // borrow balance in underlying
        bool isCollateral; // whether user has entered this market
        uint256 underlyingPrice; // price from oracle
        uint256 walletBalance; // user's underlying token balance in wallet
        uint256 walletAllowance; // user's allowance to vToken
    }

    struct VenusMarketData {
        address vTokenAddr;
        address underlyingAddr;
        string symbol;
        string underlyingSymbol;
        uint8 vTokenDecimals;
        uint8 underlyingDecimals;
        uint256 collateralFactorMantissa;
        uint256 liquidationThresholdMantissa;
        uint256 liquidationIncentiveMantissa;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 totalSupply; // total vTokens
        uint256 totalBorrows; // total borrows in underlying
        uint256 totalReserves; // total reserves in underlying
        uint256 availableCash; // available underlying
        uint256 exchangeRateStored;
        uint256 reserveFactorMantissa;
        uint256 xvsSupplySpeed; // XVS per block for suppliers
        uint256 xvsBorrowSpeed; // XVS per block for borrowers
        bool isListed;
        bool isBorrowAllowed;
        uint96 poolId;
    }

    IComptroller internal comptroller = IComptroller(getComptrollerAddr());
    IPriceOracle internal oracle = IPriceOracle(comptroller.oracle());

    function isVBnb(address vToken) internal view returns (bool) {
        return keccak256(bytes(IVToken(vToken).symbol())) == keccak256(bytes("vBNB"));
    }

    function getUnderlyingAddr(address vToken) internal view returns (address) {
        if (isVBnb(vToken)) {
            return getBnbAddr();
        }
        return IVToken(vToken).underlying();
    }

    function getUnderlyingDecimals(address vToken) internal view returns (uint8) {
        if (isVBnb(vToken)) {
            return 18;
        }
        return IERC20(IVToken(vToken).underlying()).decimals();
    }

    function getUnderlyingSymbol(address vToken) internal view returns (string memory) {
        if (isVBnb(vToken)) {
            return "BNB";
        }
        return IERC20(IVToken(vToken).underlying()).symbol();
    }

    function getUserData(address user) internal view returns (VenusUserData memory userData) {
        (, userData.liquidity, userData.shortfall) = comptroller.getAccountLiquidity(user);
        (, userData.borrowingLiquidity, userData.borrowingShortfall) = comptroller.getBorrowingPower(user);
        userData.xvsAccrued = comptroller.venusAccrued(user);
    }

    function getUserMarketData(
        address user,
        address vToken
    ) internal view returns (VenusUserMarketData memory tokenData) {
        IVToken vTokenContract = IVToken(vToken);

        tokenData.vTokenBalance = vTokenContract.balanceOf(user);
        tokenData.borrowBalance = vTokenContract.borrowBalanceStored(user);
        tokenData.isCollateral = comptroller.checkMembership(user, vToken);
        tokenData.underlyingPrice = oracle.getUnderlyingPrice(vToken);

        // supply balance in underlying = vTokenBalance * exchangeRate / 1e18
        uint256 exchangeRate = vTokenContract.exchangeRateStored();
        tokenData.supplyBalanceUnderlying = wmul(tokenData.vTokenBalance, exchangeRate);

        // wallet balance & allowance
        if (isVBnb(vToken)) {
            tokenData.walletBalance = user.balance;
            tokenData.walletAllowance = user.balance; // no approval needed for BNB
        } else {
            address underlying = vTokenContract.underlying();
            tokenData.walletBalance = IERC20(underlying).balanceOf(user);
            tokenData.walletAllowance = IERC20(underlying).allowance(user, vToken);
        }
    }

    function getMarketData(address vToken) internal view returns (VenusMarketData memory marketData) {
        IVToken vTokenContract = IVToken(vToken);

        marketData.vTokenAddr = vToken;
        marketData.underlyingAddr = getUnderlyingAddr(vToken);
        marketData.symbol = vTokenContract.symbol();
        marketData.underlyingSymbol = getUnderlyingSymbol(vToken);
        marketData.vTokenDecimals = vTokenContract.decimals();
        marketData.underlyingDecimals = getUnderlyingDecimals(vToken);

        (
            marketData.isListed,
            marketData.collateralFactorMantissa,
            , // isVenus
            marketData.liquidationThresholdMantissa,
            marketData.liquidationIncentiveMantissa,
            marketData.poolId,
            marketData.isBorrowAllowed
        ) = comptroller.markets(vToken);

        marketData.totalSupply = vTokenContract.totalSupply();
        marketData.totalBorrows = vTokenContract.totalBorrows();
        marketData.totalReserves = vTokenContract.totalReserves();
        marketData.availableCash = vTokenContract.getCash();
        marketData.exchangeRateStored = vTokenContract.exchangeRateStored();
        marketData.reserveFactorMantissa = vTokenContract.reserveFactorMantissa();

        marketData.xvsSupplySpeed = comptroller.venusSupplySpeeds(vToken);
        marketData.xvsBorrowSpeed = comptroller.venusBorrowSpeeds(vToken);
    }
}
