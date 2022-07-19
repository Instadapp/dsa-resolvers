// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interface.sol";

contract EulerHelper is DSMath {
    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    IEulerSimpleView internal constant simpleView = IEulerSimpleView(0xc2d41d42939109CDCfa26C6965269D9C0220b38E);

    struct SubAccount {
        uint256 id;
        address subAccountAddress;
    }

    struct Position {
        SubAccount subAccountInfo;
        AccountStatus accountStatus;
        MarketsInfoSubacc[] marketsInfoSubAcc;
    }

    struct AccountStatus {
        uint256 totalCollateralUSD;
        uint256 totalBorrowedUSD;
        uint256 totalCollateral;
        uint256 totalBorrowed;
        uint256 riskAdjustedTotalCollateral;
        uint256 riskAdjustedTotalBorrow;
        uint256 healthScore;
    }

    struct AccountStatusHelper {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 healthScore;
    }

    struct InternalHelper {
        uint256 eTokenPriceUSD;
        uint256 dTokenPriceUSD;
        uint256 riskAdjustedColUSD;
        uint256 riskAdjustedDebtUSD;
    }

    struct MarketsInfoSubacc {
        // Universal
        address underlying;
        string name;
        string symbol;
        uint8 decimals;
        address eTokenAddr;
        address dTokenAddr;
        uint256 totalBorrows;
        uint32 collateralFactor;
        uint32 borrowFactor;
        uint24 twapWindow;
        uint256 borrowAPY;
        uint256 supplyAPY;
        // Pricing
        uint256 twap;
        uint256 currPrice;
        // Account specific
        uint256 underlyingBalance;
        uint256 eulerAllowance;
        uint256 eTokenBalance;
        uint256 eTokenBalanceUnderlying;
        uint256 dTokenBalance;
        uint256 eTokenPriceUSD;
        uint256 dTokenPriceUSD;
        uint256 riskAdjustedColUSD;
        uint256 riskAdjustedBorrowUSD;
        uint256 riskAdjustedCol;
        uint256 riskAdjustedBorrow;
        uint256 numBorrows;
    }

    /**
     * @dev Return ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; // ETH Address
    }

    /**
     * @dev Return Weth address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // Mainnet WETH Address
        // return 0xd0A1E359811322d97991E03f863a0C30C2cF029C; // Kovan WETH Address
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param user Address of user
     */
    function getAllSubAccounts(address user) public pure returns (SubAccount[] memory subAccounts) {
        uint256 length = 256;
        subAccounts = new SubAccount[](length);

        for (uint256 i = 0; i < length; i++) {
            address subAccount = getSubAccountAddress(user, i);
            subAccounts[i] = SubAccount({ id: i, subAccountAddress: subAccount });
        }
    }

    /**
     * @dev Get all sub-accounts of a user.
     * @notice Get all sub-accounts of a user.
     * @param primary Address of user
     * @param subAccountId sub-account Id(0 for primary and 1 - 255 for sub-account)
     */
    function getSubAccountAddress(address primary, uint256 subAccountId) public pure returns (address) {
        require(subAccountId < 256, "sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

    /**
     * @dev Get active sub-accounts.
     * @notice Get active sub-accounts.
     * @param subAccounts Array of SubAccount struct(id and address)
     * @param tokens Array of the tokens
     */
    function getActiveSubAccounts(SubAccount[] memory subAccounts, address[] memory tokens)
        public
        view
        returns (bool[] memory activeSubAcc, uint256 count)
    {
        uint256 accLength = subAccounts.length;
        uint256 tokenLength = tokens.length;
        activeSubAcc = new bool[](accLength);

        for (uint256 i = 0; i < accLength; i++) {
            for (uint256 j = 0; j < tokenLength; j++) {
                address eToken = markets.underlyingToEToken(tokens[j]);

                if ((IEToken(eToken).balanceOfUnderlying(subAccounts[i].subAccountAddress)) > 0) {
                    activeSubAcc[i] = true;
                    count++;
                    break;
                }
            }
        }
    }

    /**
     * @dev Get detailed sub-account info.
     * @notice Get detailed sub-account info.
     * @param response Response of a sub-account. 
        (ResponseMarket include enteredMarkets followed by queried token response).
     * @param tokens Array of the tokens(Use WETH address for ETH token)
     */
    function getSubAccountInfo(
        address subAccount,
        Response memory response,
        address[] memory tokens
    ) public view returns (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accountStatus) {
        uint256 totalLendUSD;
        uint256 totalBorrowUSD;
        uint256 totalLend;
        uint256 totalBorrow;
        uint256 k;

        marketsInfo = new MarketsInfoSubacc[](tokens.length);

        for (uint256 i = response.enteredMarkets.length; i < response.markets.length; i++) {
            InternalHelper memory helper;

            (helper.eTokenPriceUSD, helper.dTokenPriceUSD) = getUSDBalance(
                response.markets[i].eTokenBalanceUnderlying,
                response.markets[i].dTokenBalance,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            totalLendUSD += helper.eTokenPriceUSD;
            totalBorrowUSD += helper.dTokenPriceUSD;

            (helper.riskAdjustedColUSD, helper.riskAdjustedDebtUSD) = getUSDRiskAdjustedValues(
                response.markets[i].liquidityStatus.collateralValue,
                response.markets[i].liquidityStatus.liabilityValue,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            totalLend += convertTo18(response.markets[i].decimals, response.markets[i].eTokenBalanceUnderlying);
            totalBorrow += convertTo18(response.markets[i].decimals, response.markets[i].dTokenBalance);

            marketsInfo[k] = MarketsInfoSubacc({
                underlying: response.markets[i].underlying,
                name: response.markets[i].name,
                symbol: response.markets[i].symbol,
                decimals: response.markets[i].decimals,
                eTokenAddr: response.markets[i].eTokenAddr,
                dTokenAddr: response.markets[i].dTokenAddr,
                totalBorrows: response.markets[i].totalBorrows,
                collateralFactor: response.markets[i].config.collateralFactor,
                borrowFactor: response.markets[i].config.borrowFactor,
                twapWindow: response.markets[i].config.twapWindow,
                borrowAPY: response.markets[i].borrowAPY,
                supplyAPY: response.markets[i].supplyAPY,
                twap: response.markets[i].twap,
                currPrice: response.markets[i].currPrice,
                underlyingBalance: response.markets[i].underlyingBalance,
                eulerAllowance: response.markets[i].eulerAllowance,
                eTokenBalance: response.markets[i].eTokenBalance,
                eTokenBalanceUnderlying: response.markets[i].eTokenBalanceUnderlying,
                dTokenBalance: response.markets[i].dTokenBalance,
                eTokenPriceUSD: helper.eTokenPriceUSD,
                dTokenPriceUSD: helper.dTokenPriceUSD,
                riskAdjustedColUSD: helper.riskAdjustedColUSD,
                riskAdjustedBorrowUSD: helper.riskAdjustedDebtUSD,
                riskAdjustedCol: response.markets[i].liquidityStatus.collateralValue,
                riskAdjustedBorrow: response.markets[i].liquidityStatus.liabilityValue,
                numBorrows: response.markets[i].liquidityStatus.numBorrows
            });

            k++;
        }

        AccountStatusHelper memory accHelper;

        (accHelper.collateralValue, accHelper.liabilityValue, accHelper.healthScore) = simpleView.getAccountStatus(
            subAccount
        );

        accountStatus = AccountStatus({
            totalCollateralUSD: totalLendUSD,
            totalBorrowedUSD: totalBorrowUSD,
            totalCollateral: totalLend,
            totalBorrowed: totalBorrow,
            riskAdjustedTotalCollateral: accHelper.collateralValue,
            riskAdjustedTotalBorrow: accHelper.liabilityValue,
            healthScore: accHelper.healthScore
        });
    }

    /**
     * @dev Get lent and borrowed token amount in USD.
     * @notice Get lent and borrowed token amount in USD.
     * @param eTokenBalanceUnderlying Lent amount.
     * @param dTokenBalance Borrowed amount.
     * @param twap Uniswap twap price of token.
     * @param decimals Token decimals.
     */
    function getUSDBalance(
        uint256 eTokenBalanceUnderlying,
        uint256 dTokenBalance,
        uint256 twap,
        uint256 decimals
    ) internal pure returns (uint256 eTokenPriceUSD, uint256 dTokenPriceUSD) {
        eTokenPriceUSD = (eTokenBalanceUnderlying * twap) / (10 ^ decimals);
        dTokenPriceUSD = (dTokenBalance * twap) / (10 ^ decimals);
    }

    /**
     * @dev Get risk-adjusted lent and borrowed token amount in USD.
     * @notice Get risk-adjusted lent and borrowed token amount in USD.
     * @param colValue risk-adjusted collateral value.
     * @param debtValue risk-adjusted borrowed value.
     * @param twap Uniswap twap price of token.
     * @param decimals Token decimals.
     */
    function getUSDRiskAdjustedValues(
        uint256 colValue,
        uint256 debtValue,
        uint256 twap,
        uint256 decimals
    ) internal pure returns (uint256 riskAdjusCol, uint256 riskAdjusDebt) {
        riskAdjusCol = (colValue * twap) / (10 ^ decimals);
        riskAdjusDebt = (debtValue * twap) / (10 ^ decimals);
    }
}
