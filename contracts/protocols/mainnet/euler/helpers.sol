// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "./interface.sol";
pragma abicoder v2;

contract EulerHelper {
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address internal constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    address internal constant EULER_MAINNET = 0x27182842E098f60e3D576794A5bFFb0777E025d3;

    IEulerMarkets internal constant markets = IEulerMarkets(0x3520d5a913427E6F0D6A83E07ccD4A4da316e4d3);

    IEulerExecution internal constant eulerExec = IEulerExecution(0x14cBaC4eC5673DEFD3968693ebA994F07F8436D2);

    IEulerGeneralView internal constant eulerView = IEulerGeneralView(0xACC25c4d40651676FEEd43a3467F3169e3E68e42);

    struct AccountStatus {
        uint256 collateralValue;
        uint256 liabilityValue;
        uint256 healthScore;
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

    function getAccountStatus(address account) public view returns (AccountStatus memory accStatus) {
        LiquidityStatus memory status = eulerExec.liquidity(account);

        accStatus.collateralValue = status.collateralValue;
        accStatus.liabilityValue = status.liabilityValue;

        if (accStatus.liabilityValue == 0) {
            accStatus.healthScore = type(uint256).max;
        }

        accStatus.healthScore = (accStatus.collateralValue * 1e18) / accStatus.liabilityValue;
    }
}
