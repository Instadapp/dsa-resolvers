// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./interface.sol";

contract EulerHelper {
    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

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
        uint256 totalCollateral;
        uint256 totalBorrowed;
    }

    struct MarketsInfoSubacc {
        // Universal
        address underlying;
        string name;
        string symbol;
        uint8 decimals;
        address eTokenAddr;
        address dTokenAddr;
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
        uint256 riskAdjustedColValue;
        uint256 riskAdjustedBorValue;
        uint256 riskAdjustedCol;
        uint256 riskAdjustedLiability;
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
                } else {
                    continue;
                }
            }
        }
    }

    /**
     * @dev Get active sub-accounts.
     * @notice Get active sub-accounts.
     * @param response Response of a sub-account. ResponseMarket include enteredMarkets followed by queried token response.
     * @param tokens Array of the tokens(Use WETH address for ETH token)
     */
    function getSubAccountInfo(Response memory response, address[] memory tokens)
        public
        pure
        returns (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accountStatus)
    {
        uint256 totalLendUSD;
        uint256 totalBorrowUSD;
        uint256 k;

        marketsInfo = new MarketsInfoSubacc[](tokens.length);

        for (uint256 i = response.enteredMarkets.length; i < response.markets.length; i++) {
            (uint256 eTokenPriceUSD, uint256 dTokenPriceUSD) = getUSDBalance(
                response.markets[i].eTokenBalanceUnderlying,
                response.markets[i].dTokenBalance,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            totalLendUSD = totalLendUSD + eTokenPriceUSD;
            totalBorrowUSD = totalBorrowUSD + dTokenPriceUSD;

            (uint256 riskAdjusColUSD, uint256 riskAdjusDebtUSD) = getUSDRiskAdjustedValues(
                response.markets[i].liquidityStatus.collateralValue,
                response.markets[i].liquidityStatus.liabilityValue,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            marketsInfo[k] = MarketsInfoSubacc({
                underlying: response.markets[i].underlying,
                name: response.markets[i].name,
                symbol: response.markets[i].symbol,
                decimals: response.markets[i].decimals,
                eTokenAddr: response.markets[i].eTokenAddr,
                dTokenAddr: response.markets[i].dTokenAddr,
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
                eTokenPriceUSD: eTokenPriceUSD,
                dTokenPriceUSD: dTokenPriceUSD,
                riskAdjustedColValue: riskAdjusColUSD,
                riskAdjustedBorValue: riskAdjusDebtUSD,
                riskAdjustedCol: response.markets[i].liquidityStatus.collateralValue,
                riskAdjustedLiability: response.markets[i].liquidityStatus.liabilityValue,
                numBorrows: response.markets[i].liquidityStatus.numBorrows
            });
            k++;
        }

        accountStatus = AccountStatus({ totalCollateral: totalLendUSD, totalBorrowed: totalBorrowUSD });
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
