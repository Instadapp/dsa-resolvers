// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface TokenInterface {
    function decimals() external view returns (uint256 _decimals);
}

interface LimitOrderInterface {
    function minAmount() external view returns (uint256 _minAmount);

    function priceSlippage() external view returns (uint256 _priceSlippage);

    function route(uint256 _route) external view returns (bool _isOk);

    function routeTokensArray(uint256 _route) external view returns (address[] memory _tokens);

    function getRouteTokensArrayLength(uint256 _route) external view returns (uint256 _length);

    function tokenToCtoken(address _token) external view returns (CTokenInterface);

    function encodeTokenKey(address _tokenFrom, address _tokenTo) external pure returns (bytes32 _key);

    function encodeDsaKey(address _dsa, uint32 _route) external pure returns (bytes8 _key);

    function checkPrice(uint128) external view returns (bool _isOk);

    function findCreatePos(bytes32 _key, uint128 _price) external view returns (bytes8 _key2);

    function checkUserPosition(address _dsa, uint256 _route) external view returns (bool _isOk, uint256 _netPos);

    function ordersLinks(bytes32 _key) external view returns (OrderLink memory);

    function ordersLists(bytes32 _key, bytes8 _key2) external view returns (OrderList memory);

    struct OrderLink {
        bytes8 first;
        bytes8 last;
        uint64 count;
    }

    struct OrderList {
        bytes8 prev;
        bytes8 next;
        uint128 price; // price in 18 decimals
        uint32 route; // which route to take Eg:- payback & borrow from Aave.
        address tokenFrom;
        address tokenTo;
        address dsa;
    }
}

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint256);

    function balanceOfUnderlying(address) external returns (uint256);

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function getCash() external view returns (uint256);
}

interface AaveProtocolDataProvider {
    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}
