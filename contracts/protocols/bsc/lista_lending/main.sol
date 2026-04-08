// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./helpers.sol";

contract ListaLendingResolver is ListaLendingHelpers {
    function getUserPosition(
        Id[] memory marketIds_,
        address user_
    ) public view returns (UserData[] memory positions, MarketData[] memory marketData) {
        uint256 length = marketIds_.length;
        positions = new UserData[](length);
        marketData = new MarketData[](length);

        for (uint256 i = 0; i < length; i++) {
            Market memory m = MOOLAH.market(marketIds_[i]);
            MarketParams memory mp = MOOLAH.idToMarketParams(marketIds_[i]);

            positions[i] = getUserConfig(marketIds_[i], mp, user_);
            marketData[i] = MarketData(
                marketIds_[i],
                mp.loanToken,
                mp.collateralToken,
                mp.oracle,
                mp.irm,
                mp.lltv,
                m.totalSupplyAssets,
                m.totalSupplyShares,
                m.totalBorrowAssets,
                m.totalBorrowShares,
                m.lastUpdate,
                m.fee
            );
        }
    }

    function getMarketParamsFromId(
        Id id_
    ) public view returns (address loanToken_, address collateralToken_, address oracle_, address irm_, uint256 lltv_) {
        MarketParams memory mp = MOOLAH.idToMarketParams(id_);
        (loanToken_, collateralToken_, oracle_, irm_, lltv_) = (
            mp.loanToken,
            mp.collateralToken,
            mp.oracle,
            mp.irm,
            mp.lltv
        );
    }

    function getMarketState(
        Id id_
    )
        public
        view
        returns (
            uint256 totalSupplyAssets_,
            uint256 totalSupplyShares_,
            uint256 totalBorrowAssets_,
            uint256 totalBorrowShares_,
            uint256 lastUpdate_,
            uint256 fee_
        )
    {
        Market memory m = MOOLAH.market(id_);
        (totalSupplyAssets_, totalSupplyShares_, totalBorrowAssets_, totalBorrowShares_, lastUpdate_, fee_) = (
            m.totalSupplyAssets,
            m.totalSupplyShares,
            m.totalBorrowAssets,
            m.totalBorrowShares,
            m.lastUpdate,
            m.fee
        );
    }
}

contract InstaListaLendingResolverBSC is ListaLendingResolver {
    string public constant name = "ListaLending-Resolver-BSC-v1.0";
}
