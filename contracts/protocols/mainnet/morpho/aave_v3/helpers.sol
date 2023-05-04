// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../../utils/dsmath.sol";
import { Types } from "@morpho-aave-v3/libraries/Types.sol";
import { DataTypes } from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";

contract MorphoHelpers is DSMath {
    IMorpho internal morpho = IMorpho(0x33333aea097c193e66081E930c33020272b33333);
    AaveAddressProvider addrProvider = AaveAddressProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IAave internal protocolData = IAave(0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3);
    IAave internal incentiveData = IAave(0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb);

    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
        uint256 p2pSupplyAmount;
        uint256 p2pBorrowAmount;
        uint256 poolSupplyAmount;
        uint256 poolBorrowAmount;
        uint256 totalSupplyAmount;
        uint256 totalBorrowAmount;
    }

    struct TokenConfig {
        address underlyingToken;
        address aTokenAddress;
        address sDebtTokenAddress;
        address vDebtTokenAddress;
        uint256 decimals;
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
    }

    struct AaveMarketDetail {
        uint256 aEmissionPerSecond;
        uint256 sEmissionPerSecond;
        uint256 vEmissionPerSecond;
        uint256 availableLiquidity;
        uint256 liquidityRate;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 totalSupplies;
        uint256 totalStableBorrows;
        uint256 totalVariableBorrows;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRatePerYear; //in wad
        uint256 avgBorrowRatePerYear; //in wad
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 totalP2PSupply;
        uint256 totalPoolSupply;
        uint256 totalP2PBorrows;
        uint256 totalPoolBorrows;
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 poolSupplyIndex;
        uint256 poolBorrowIndex;
        uint256 lastUpdateTimestamp;
        uint256 p2pSupplyDelta; //The total amount of underlying ERC20 tokens supplied through Morpho,
        //stored as matched peer-to-peer but supplied on the underlying pool
        uint256 p2pBorrowDelta; //The total amount of underlying ERC20 tokens borrow through Morpho,
        //stored as matched peer-to-peer but borrowed from the underlying pool
        uint256 reserveFactor;
        uint256 p2pIndexCursor; //p2p rate position b/w supply and borrow rate, in bps,
        // 0% = supply rate, 100% = borrow rate
        AaveMarketDetail aaveData;
        Flags flags;
    }

    struct Flags {
        bool isCreated;
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
        bool isUnderlyingBorrowEnabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRatePerYear;
        uint256 supplyRatePerYear;
        uint256 totalSupplies;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
        uint256 maxWithdrawable;
        uint256 maxBorrowable;
    }

    struct UserData {
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets
        uint256 debtValue; //calculated by updating interest accrue indices for all markets
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets
        bool isLiquidatable;
        uint256 liquidationThreshold;
        UserMarketData[] marketData;
        uint256 ethPriceInUsd;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    /// @notice Morpho pool data
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer
    /// subtracting the supply delta and the idle supply on Morpho's contract (in base currency).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool
    /// adding the supply delta (in base currency).
    /// @return idleSupplyAmount The total idle supply amount on the Morpho's contract (in base currency).
    /// @return totalSupplyAmount The total amount supplied through Morpho (in base currency).
    function totalSupplyMorpho()
        public
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 idleSupplyAmount,
            uint256 totalSupplyAmount
        )
    {
        address[] memory marketAddresses = morpho.marketsCreated();

        uint256 underlyingPrice;
        uint256 nbMarkets = marketAddresses.length;

        for (uint256 i; i < nbMarkets; ++i) {
            address underlying = marketAddresses[i];

            DataTypes.ReserveConfigurationMap memory reserve = pool.getConfiguration(underlying);
            underlyingPrice = assetPrice(underlying, reserve.getEModeCategory());
            uint256 assetUnit = 10**reserve.getDecimals();

            (
                uint256 marketP2PSupplyAmount,
                uint256 marketPoolSupplyAmount,
                uint256 marketIdleSupplyAmount
            ) = marketSupply(underlying);

            p2pSupplyAmount += (marketP2PSupplyAmount * underlyingPrice) / assetUnit;
            poolSupplyAmount += (marketPoolSupplyAmount * underlyingPrice) / assetUnit;
            idleSupplyAmount += (marketIdleSupplyAmount * underlyingPrice) / assetUnit;
        }

        totalSupplyAmount = p2pSupplyAmount + poolSupplyAmount + idleSupplyAmount;
    }

    /// @notice Returns the supply rate per year a given user is currently experiencing on a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to compute the supply rate per year for.
    /// @return supplyRatePerYear The supply rate per year the user is currently experiencing (in ray).
    function supplyAPR(address underlying, address user) public view returns (uint256 supplyRatePerYear) {
        (uint256 balanceInP2P, uint256 balanceOnPool, ) = supplyBalance(underlying, user);
        (uint256 poolSupplyRate, uint256 poolBorrowRate) = poolAPR(underlying);

        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 p2pSupplyRate = Utils.p2pSupplyAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRate,
                poolBorrowRatePerYear: poolBorrowRate,
                poolIndex: indexes.supply.poolIndex,
                p2pIndex: indexes.supply.p2pIndex,
                proportionIdle: market.proportionIdle(),
                p2pDelta: market.deltas.supply.scaledDelta,
                p2pTotal: market.deltas.supply.scaledP2PTotal,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        supplyRatePerYear = Utils.weightedRate(p2pSupplyRate, poolSupplyRate, balanceInP2P, balanceOnPool);
    }

    /// @notice Computes and returns the total distribution of supply for a given market
    /// using virtually updated indexes.
    /// @notice It takes into account the amount of token deposit in supply and in collateral in Morpho.
    /// @param underlying The address of the underlying asset to check.
    /// @return p2pSupply The total supplied amount (in underlying) matched peer-to-peer
    /// subtracting the supply delta and the idle supply.
    /// @return poolSupply The total supplied amount (in underlying) on the underlying pool, adding the supply delta.
    /// @return idleSupply The total idle amount (in underlying) on the Morpho contract.
    function marketSupply(address underlying)
        public
        view
        returns (
            uint256 p2pSupply,
            uint256 poolSupply,
            uint256 idleSupply
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        p2pSupply = market.trueP2PSupply(indexes);
        poolSupply = ERC20(market.aToken).balanceOf(address(morpho));
        idleSupply = market.idleSupply;
    }

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function supplyBalance(address underlying, address user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        balanceInP2P = morpho.scaledP2PSupplyBalance(underlying, user).rayMulDown(indexes.supply.p2pIndex);
        balanceOnPool = morpho.scaledPoolSupplyBalance(underlying, user).rayMulDown(indexes.supply.poolIndex);
        totalBalance = balanceInP2P + balanceOnPool;
    }

    /// @notice Returns the total collateral balance in underlying of a given user.
    /// @param user The user to determine balances of.
    /// @return collateralBalance The total collateral balance of the user (in underlying).
    function totalCollateralBalance(address user) public view returns (uint256 collateralBalance) {
        address[] memory userCollaterals = morpho.userCollaterals(user);

        uint256 length = userCollaterals.length;

        for (uint256 i = 0; i < length; i++) {
            collateralBalance += morpho.collateralBalance(userCollaterals[i], user);
        }
    }

    /// @notice Computes and returns the current supply rate per year experienced on average on a given market.
    /// @param underlying The address of the underlying asset.
    /// @return avgSupplyRatePerYear The market's average supply rate per year (in ray).
    /// @return p2pSupplyRatePerYear The market's p2p supply rate per year (in ray).
    ///@return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    function avgSupplyAPR(address underlying)
        public
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 p2pSupplyRatePerYear,
            uint256 poolSupplyRatePerYear
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 poolBorrowRatePerYear;
        (poolSupplyRatePerYear, poolBorrowRatePerYear) = poolAPR(underlying);

        p2pSupplyRatePerYear = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRatePerYear,
                poolBorrowRatePerYear: poolBorrowRatePerYear,
                poolIndex: indexes.supply.poolIndex,
                p2pIndex: indexes.supply.p2pIndex,
                proportionIdle: 0,
                p2pDelta: 0, // Simpler to account for the delta in the weighted avg.
                p2pTotal: 0,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        avgSupplyRatePerYear = Utils.weightedRate(
            p2pSupplyRatePerYear,
            poolSupplyRatePerYear,
            market.trueP2PSupply(indexes),
            ERC20(market.aToken).balanceOf(address(morpho))
        );
    }

    /// @dev Computes and returns the underlying pool rates for a specific market.
    /// @param underlying The underlying pool market address.
    /// @return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    /// @return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function poolAPR(address underlying)
        public
        view
        returns (uint256 poolSupplyRatePerYear, uint256 poolBorrowRatePerYear)
    {
        DataTypes.ReserveData memory reserve = pool.getReserveData(underlying);
        poolSupplyRatePerYear = reserve.currentLiquidityRate;
        poolBorrowRatePerYear = reserve.currentVariableBorrowRate;
    }

    /// @notice Returns the price of a given asset.
    /// @param asset The address of the asset to get the price of.
    /// @param reserveEModeCategoryId Aave's associated reserve e-mode category.
    /// @return price The current price of the asset.
    function assetPrice(address asset, uint256 reserveEModeCategoryId) public view returns (uint256 price) {
        address priceSource;
        if (eModeCategoryId != 0 && reserveEModeCategoryId == eModeCategoryId) {
            priceSource = pool.getEModeCategoryData(eModeCategoryId).priceSource;
        }

        IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());

        if (priceSource != address(0)) {
            price = oracle.getAssetPrice(priceSource);
        }

        if (priceSource == address(0) || price == 0) {
            price = oracle.getAssetPrice(asset);
        }
    }

    /// @notice Computes and returns the total distribution of borrows through Morpho
    /// using virtually updated indexes.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer
    /// subtracting the borrow delta (in base currency).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool
    /// adding the borrow delta (in base currency).
    /// @return totalBorrowAmount The total amount borrowed through Morpho (in base currency).
    function totalBorrow()
        public
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        )
    {
        address[] memory marketAddresses = morpho.marketsCreated();

        uint256 underlyingPrice;
        uint256 nbMarkets = marketAddresses.length;

        for (uint256 i; i < nbMarkets; ++i) {
            address underlying = marketAddresses[i];

            DataTypes.ReserveConfigurationMap memory reserve = pool.getConfiguration(underlying);
            underlyingPrice = assetPrice(underlying, reserve.getEModeCategory());
            uint256 assetUnit = 10**reserve.getDecimals();

            (uint256 marketP2PBorrowAmount, uint256 marketPoolBorrowAmount) = marketBorrow(underlying);

            p2pBorrowAmount += (marketP2PBorrowAmount * underlyingPrice) / assetUnit;
            poolBorrowAmount += (marketPoolBorrowAmount * underlyingPrice) / assetUnit;
        }

        totalBorrowAmount = p2pBorrowAmount + poolBorrowAmount;
    }

    /// @notice Returns the borrow rate per year a given user is currently experiencing on a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to compute the borrow rate per year for.
    /// @return borrowRatePerYear The borrow rate per year the user is currently experiencing (in ray).
    function borrowAPR(address underlying, address user) public view returns (uint256 borrowRatePerYear) {
        (uint256 balanceInP2P, uint256 balanceOnPool, ) = borrowBalance(underlying, user);
        (uint256 poolSupplyRate, uint256 poolBorrowRate) = poolAPR(underlying);

        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 p2pBorrowRate = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRate,
                poolBorrowRatePerYear: poolBorrowRate,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: market.deltas.borrow.scaledDelta,
                p2pTotal: market.deltas.borrow.scaledP2PTotal,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        borrowRatePerYear = Utils.weightedRate(p2pBorrowRate, poolBorrowRate, balanceInP2P, balanceOnPool);
    }

    /// @notice Computes and returns the current borrow rate per year experienced on average on a given market.
    /// @param underlying The address of the underlying asset.
    /// @return avgBorrowRatePerYear The market's average borrow rate per year (in ray).
    /// @return p2pBorrowRatePerYear The market's p2p borrow rate per year (in ray).
    ///@return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function avgBorrowAPR(address underlying)
        public
        view
        returns (
            uint256 avgBorrowRatePerYear,
            uint256 p2pBorrowRatePerYear,
            uint256 poolBorrowRatePerYear
        )
    {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        uint256 poolSupplyRatePerYear;
        (poolSupplyRatePerYear, poolBorrowRatePerYear) = poolAPR(underlying);

        p2pBorrowRatePerYear = Utils.p2pBorrowAPR(
            Utils.P2PRateComputeParams({
                poolSupplyRatePerYear: poolSupplyRatePerYear,
                poolBorrowRatePerYear: poolBorrowRatePerYear,
                poolIndex: indexes.borrow.poolIndex,
                p2pIndex: indexes.borrow.p2pIndex,
                proportionIdle: 0,
                p2pDelta: 0, // Simpler to account for the delta in the weighted avg.
                p2pTotal: 0,
                p2pIndexCursor: market.p2pIndexCursor,
                reserveFactor: market.reserveFactor
            })
        );

        avgBorrowRatePerYear = Utils.weightedRate(
            p2pBorrowRatePerYear,
            poolBorrowRatePerYear,
            market.trueP2PBorrow(indexes),
            ERC20(market.variableDebtToken).balanceOf(address(morpho))
        );
    }

    /// @notice Computes and returns the total distribution of borrows for a given market
    /// using virtually updated indexes.
    /// @param underlying The address of the underlying asset to check.
    /// @return p2pBorrow The total borrowed amount (in underlying) matched peer-to-peer, subtracting the borrow delta.
    /// @return poolBorrow The total borrowed amount (in underlying) on the underlying pool, adding the borrow delta.
    function marketBorrow(address underlying) public view returns (uint256 p2pBorrow, uint256 poolBorrow) {
        Types.Market memory market = morpho.market(underlying);
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        p2pBorrow = market.trueP2PBorrow(indexes);
        poolBorrow = ERC20(market.variableDebtToken).balanceOf(address(morpho));
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param underlying The address of the underlying asset.
    /// @param user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function borrowBalance(address underlying, address user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.Indexes256 memory indexes = morpho.updatedIndexes(underlying);

        balanceInP2P = morpho.scaledP2PBorrowBalance(underlying, user).rayMulUp(indexes.borrow.p2pIndex);
        balanceOnPool = morpho.scaledPoolBorrowBalance(underlying, user).rayMulUp(indexes.borrow.poolIndex);
        totalBalance = balanceInP2P + balanceOnPool;
    }

    /// @dev Computes and returns the underlying pool rates for a specific market.
    /// @param underlying The underlying pool market address.
    /// @return poolSupplyRatePerYear The market's pool supply rate per year (in ray).
    /// @return poolBorrowRatePerYear The market's pool borrow rate per year (in ray).
    function poolAPR(address underlying)
        public
        view
        returns (uint256 poolSupplyRatePerYear, uint256 poolBorrowRatePerYear)
    {
        DataTypes.ReserveData memory reserve = pool.getReserveData(underlying);
        poolSupplyRatePerYear = reserve.currentLiquidityRate;
        poolBorrowRatePerYear = reserve.currentVariableBorrowRate;
    }

    /// @notice Returns the price of a given asset.
    /// @param asset The address of the asset to get the price of.
    /// @param reserveEModeCategoryId Aave's associated reserve e-mode category.
    /// @return price The current price of the asset.
    function assetPrice(address asset, uint256 reserveEModeCategoryId) public view returns (uint256 price) {
        address priceSource;
        if (eModeCategoryId != 0 && reserveEModeCategoryId == eModeCategoryId) {
            priceSource = pool.getEModeCategoryData(eModeCategoryId).priceSource;
        }

        IAaveOracle oracle = IAaveOracle(addressesProvider.getPriceOracle());

        if (priceSource != address(0)) {
            price = oracle.getAssetPrice(priceSource);
        }

        if (priceSource == address(0) || price == 0) {
            price = oracle.getAssetPrice(asset);
        }
    }

    /// @notice Returns the health factor of a given user.
    /// @param user The user of whom to get the health factor.
    /// @return The health factor of the given user (in wad).
    function healthFactor(address user) public view returns (uint256) {
        Types.LiquidityData memory liquidityData = morpho.liquidityData(user);

        return liquidityData.debt > 0 ? liquidityData.maxDebt.wadDiv(liquidityData.debt) : type(uint256).max;
    }

    function getUserData(address user, address[] memory tokens_) internal view returns (UserData memory userData_) {
        uint256 length_ = tokens_.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(
                user,
                underlyingToken[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }

        userData_.marketData = marketData_;

        userData_.healthFactor = healthFactor(user);

        // TODO: Factor in supply and collateral values everywhere
        userData_.collateralValue = totalCollateralBalance(user);

        Types.LiquidityData memory liquidityData = morpho.liquidityData(user);

        // The maximum debt value allowed to borrow (in base currency).
        userData_.maxBorrowable = liquidityData.borrowable;
        // The maximum debt value allowed before being liquidatable (in base currency).
        userData_.maxDebtValue = liquidityData.maxDebt;
        // The debt value (in base currency).
        userData_.debtValue = liquidityData.debt;
    }

    function getUserMarketData(
        address user,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (UserMarketData memory userMarketData_) {
        userMarketData_.marketData = getMarketData(poolTokenAddress, priceInEth, priceInUsd);

        (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = borrowBalance(
            underlying,
            user
        );

        (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = supplyBalance(
            underlying,
            user
        );

        // With combined P2P and pool balance
        userMarketData_.borrowRatePerYear = borrowAPR(underlying, user);
        userMarketData_.supplyRatePerYear = supplyAPR(underlying, user);
    }

    function getMarketData(
        address poolTokenAddress,
        address underlying,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getAaveMarketData(marketData_, poolTokenAddress, priceInEth, priceInUsd);

        (marketData_.totalP2PBorrows, marketData_.totalPoolBorrows) = marketBorrow(underlying);

        (marketData_.avgBorrowRatePerYear, marketData_.p2pBorrowRate, marketData_.poolBorrowRate) = avgBorrowAPR(
            underlying
        );

        (marketData_.totalP2PSupply, marketData_.totalPoolSupply, marketData_.totalIdleSupply) = marketSupply(
            underlying
        );

        (marketData_.avgSupplyRatePerYear, marketData_.p2pSupplyRate, marketData_.poolSupplyRate) = avgSupplyAPR(
            underlying
        );
    }

    function getAaveMarketData(
        // TODO: update
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory) {
        marketData_.config.poolTokenAddress = poolTokenAddress_;
        marketData_.config.tokenPriceInEth = priceInEth; // TODO: Update prices
        marketData_.config.tokenPriceInUsd = priceInUsd;
        (
            marketData_.config.underlyingToken,
            marketData_.flags.isCreated,
            marketData_.flags.isP2PDisabled,
            marketData_.flags.isPaused,
            marketData_.flags.isPartiallyPaused,
            ,
            ,
            ,
            ,
            ,
            marketData_.config.decimals
        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        marketData_ = getLiquidatyData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);
        marketData_ = getAaveHelperData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);

        return marketData_;
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory tokens_ = morpho.marketsCreated();

        MarketDetail[] memory aaveMarket_ = new MarketDetail[](tokens_.length);
        uint256 length_ = tokens_.length;

        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(aaveMarkets_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = morpho.isClaimRewardsPaused();

        (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = morpho
            .totalBorrow();
    }
}
