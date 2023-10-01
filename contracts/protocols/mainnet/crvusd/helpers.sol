// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract CRVHelpers is DSMath {
    address internal constant CRV_USD = 0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E;
    /**
     * @dev ControllerFactory Interface
     */
    IControllerFactory internal constant CONTROLLER_FACTORY =
        IControllerFactory(0xC9332fdCB1C491Dcc683bAe86Fe3cb70360738BC);

    /**
     * @dev Get controller address by given collateral asset
     */
    function getController(address collateral, uint256 i) internal view returns (IController controller) {
        controller = IController(CONTROLLER_FACTORY.get_controller(collateral, i));
    }

    function getMarketConfig(address market, uint256 index) internal view returns (MarketConfig memory config) {
        IController controller = getController(market, index);
        address AMM = controller.amm();
        address monetary = controller.monetary_policy();
        config.controller = address(controller);
        config.AMM = AMM;
        config.monetary = monetary;
        config.oraclePrice = controller.amm_price();
        config.loanLen = controller.n_loans();
        config.totalDebt = controller.total_debt();

        address coin0 = I_LLAMMA(AMM).coins(0);
        address coin1 = I_LLAMMA(AMM).coins(1);
        uint8 decimals0 = IERC20(coin0).decimals();
        uint8 decimals1 = IERC20(coin1).decimals();
        uint256 amount0 = IERC20(coin0).balanceOf(AMM);
        uint256 amount1 = IERC20(coin1).balanceOf(AMM);

        Coins memory c = Coins(coin0, coin1, decimals0, decimals1, amount0, amount1);

        config.coins = c;
        config.borrowable = IERC20(CRV_USD).balanceOf(address(controller));
        config.basePrice = I_LLAMMA(AMM).get_base_price();
        config.A = I_LLAMMA(AMM).A();
        config.minBand = I_LLAMMA(AMM).min_band();
        config.maxBand = I_LLAMMA(AMM).max_band();

        try IMonetary(monetary).rate(address(controller)) returns (uint256 rate) {
            config.fractionPerSecond = rate;
        } catch {
            config.fractionPerSecond = IMonetary(monetary).rate();
        }
        config.sigma = IMonetary(monetary).sigma();
        config.targetDebtFraction = IMonetary(monetary).target_debt_fraction();
    }
}
