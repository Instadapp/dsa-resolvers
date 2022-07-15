// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./interface.sol";

contract EulerHelper {
    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerExecution internal constant eulerExec = IEulerExecution(0x14cBaC4eC5673DEFD3968693ebA994F07F8436D2);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    struct AccountStatus {
        uint256 totalCollateral;
        uint256 totalBorrowed;
    }

    function getEnteredMarkets(address user) internal view returns (address[] memory enteredMarkets) {
        enteredMarkets = markets.getEnteredMarkets(user);
    }

    function getAPY(address underlying) public view returns (uint256 borrowAPY, uint256 supplyAPY) {
        uint256 borrowSPY = uint256(int256(markets.interestRate(underlying)));
        (, uint256 totalBalances, uint256 totalBorrows, ) = eulerView.getTotalSupplyAndDebts(underlying);
        (borrowAPY, supplyAPY) = eulerView.computeAPYs(
            borrowSPY,
            totalBorrows,
            totalBalances,
            markets.reserveFee(underlying)
        );
    }

    function getSubAccount(address primary, uint256 subAccountId) public pure returns (address) {
        require(subAccountId < 256, "sub-account-id-too-big");
        return address(uint160(primary) ^ uint160(subAccountId));
    }

    function getActiveSubaccounts(Response[] memory response) public pure returns (bool[] memory activeSubAcc) {
        uint256 length = response.length;
        activeSubAcc = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            for (uint256 j = 0; j < response[i].markets.length; j++) {
                if (response[i].markets[j].liquidityStatus.collateralValue > 0) {
                    activeSubAcc[i] = true;
                }
            }
        }
    }

    struct MarketsInfoSubacc {
        // Universal
        address underlying;
        string name;
        string symbol;
        uint8 decimals;
        address eTokenAddr;
        address dTokenAddr;
        // AssetConfig config;
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

    function getSubaccInfo(Response memory response)
        public
        pure
        returns (MarketsInfoSubacc[] memory marketsInfo, AccountStatus memory accStatus)
    {
        // uint length = response.markets.length;

        marketsInfo = new MarketsInfoSubacc[](response.markets.length);

        uint256 totalLendToken;
        uint256 totalBorrowToken;
        uint256 totalLendUSD;
        uint256 totalBorrowUSD;

        for (uint256 i = 0; i < response.markets.length; i++) {
            (uint256 eTokenPriceUSD, uint256 dTokenPriceUSD) = getUSDBalance(
                response.markets[i].eTokenBalanceUnderlying,
                response.markets[i].dTokenBalance,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            totalLendToken = totalLendToken + response.markets[i].eTokenBalanceUnderlying;
            totalBorrowToken = totalBorrowToken + response.markets[i].dTokenBalance;

            totalLendUSD = totalLendUSD + eTokenPriceUSD;
            totalBorrowUSD = totalBorrowUSD + dTokenPriceUSD;

            (uint256 riskAdjusColUSD, uint256 riskAdjusDebtUSD) = getUSDRiskAdjustedValues(
                response.markets[i].liquidityStatus.collateralValue,
                response.markets[i].liquidityStatus.liabilityValue,
                response.markets[i].twap,
                response.markets[i].decimals
            );

            marketsInfo[i] = MarketsInfoSubacc({
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
        }

        accStatus = AccountStatus({ totalCollateral: totalLendUSD, totalBorrowed: totalBorrowUSD });
    }

    function getUSDBalance(
        uint256 eTokenBalanceUnderlying,
        uint256 dTokenBalance,
        uint256 twap,
        uint256 decimals
    ) internal pure returns (uint256 eTokenPriceUSD, uint256 dTokenPriceUSD) {
        eTokenPriceUSD = ((eTokenBalanceUnderlying * twap) / 10) ^ decimals;
        dTokenPriceUSD = ((dTokenBalance * twap) / 10) ^ decimals;
    }

    function getUSDRiskAdjustedValues(
        uint256 colValue,
        uint256 debtValue,
        uint256 twap,
        uint256 decimals
    ) internal pure returns (uint256 riskAdjusCol, uint256 riskAdjusDebt) {
        riskAdjusCol = ((colValue * twap) / 10) ^ decimals;
        riskAdjusDebt = ((debtValue * twap) / 10) ^ decimals;
    }
}
