// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    struct Info {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    function getDepositedToken(address user) external view returns (uint256[] memory) {
        uint256[] memory depositedTokens = userNfts(address(staker));
        uint256[] memory tokenIds = new uint256[](depositedTokens.length);
        uint256 counter = 0;
        for (uint256 i = 0; i < depositedTokens.length; i++) {
            (address owner, , , ) = staker.deposits(depositedTokens[i]);
            if (owner == user) {
                tokenIds[counter] = depositedTokens[i];
                counter++;
            }
        }

        return tokenIds;
    }

    function getStakedPoolInfo(address user) external view returns (address[] memory) {
        uint256[] memory depositedTokens = userNfts(address(staker));
        address[] memory pools = new address[](depositedTokens.length);
        uint256 j = 0;
        for (uint256 i = 0; i < depositedTokens.length; i++) {
            (address owner, , , ) = staker.deposits(depositedTokens[i]);
            if (owner == user) {
                pools[j] = getPoolAddress(depositedTokens[i]);
                j++;
            }
        }
        return pools;
    }

    function getUnclaimedRewards(
        IUniswapV3Staker.IncentiveKey memory key,
        uint256 tokenId,
        address user,
        address rewardToken
    ) public view returns (uint256 reward, uint256 rewardToCollect) {
        (uint256 liquidity, ) = staker.stakes(tokenId, getIncentiveId(key));
        if (liquidity > 0) (reward, ) = staker.getRewardInfo(key, tokenId);
        rewardToCollect = staker.rewards(IERC20Minimal(rewardToken), user);
    }

    struct Deposit {
        address owner;
        uint48 numberOfStakes;
        int24 tickLower;
        int24 tickUpper;
    }

    struct Incentive {
        uint256 totalRewardUnclaimed;
        uint160 totalSecondsClaimedX128;
        uint96 numberOfStakes;
    }

    struct RewardDetailsMinAndMax {
        uint256 rate;
        uint128 liquidity;
        address token0;
        address token1;
        uint256 minAmount0;
        uint256 minAmount1;
        uint256 maxAmount0;
        uint256 maxAmount1;
        int24 tick;
    }

    struct RewardDetails {
        uint256 rate;
        uint128 liquidity;
        uint256 amount0;
        uint256 amount1;
        int24 tick;
    }

    function getPositionRewardsDetails(
        IUniswapV3Staker.IncentiveKey memory key,
        uint128 positionLiquidity,
        int24 upperTick,
        int24 lowerTick
    ) public view returns (RewardDetails memory rewardDetails) {
        IUniswapV3Pool pool = IUniswapV3Pool(key.pool);
        uint160 sqrtRatioX96;
        (sqrtRatioX96, rewardDetails.tick, , , , , ) = pool.slot0();
        rewardDetails.liquidity = pool.liquidity();
        (rewardDetails.amount0, rewardDetails.amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick((int24(lowerTick))),
            TickMath.getSqrtRatioAtTick((int24(upperTick))),
            uint128(positionLiquidity)
        );

        if (key.startTime < block.timestamp) {
            bytes32 incentiveId = keccak256(abi.encode(key));

            Incentive memory incentive;
            (incentive.totalRewardUnclaimed, incentive.totalSecondsClaimedX128, incentive.numberOfStakes) = staker
                .incentives(incentiveId);

            uint256 totalSecondsUnclaimedX128 = ((Math.max(key.endTime, block.timestamp) - key.startTime) << 128) -
                incentive.totalSecondsClaimedX128;
            rewardDetails.rate = uint256(
                (incentive.totalRewardUnclaimed * 0x100000000000000000000000000000000) /
                    uint256(totalSecondsUnclaimedX128)
            );
        }
    }

    struct TickInfo {
        IUniswapV3Staker.IncentiveKey key;
        int24 minUpperTick;
        int24 minLowerTick;
        int24 maxUpperTick;
        int24 maxLowerTick;
    }

    function getRewardsDetailsMinAndMax(TickInfo[] memory tickInfo)
        public
        view
        returns (RewardDetailsMinAndMax[] memory rewardDetails)
    {
        rewardDetails = new RewardDetailsMinAndMax[](tickInfo.length);
        for (uint256 i = 0; i < tickInfo.length; i++) {
            IUniswapV3Pool pool = IUniswapV3Pool(tickInfo[i].key.pool);
            rewardDetails[i].token0 = pool.token0();
            rewardDetails[i].token1 = pool.token1();

            uint160 sqrtRatioX96;
            (sqrtRatioX96, rewardDetails[i].tick, , , , , ) = pool.slot0();
            rewardDetails[i].liquidity = pool.liquidity();
            (rewardDetails[i].minAmount0, rewardDetails[i].minAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick((int24(tickInfo[i].minLowerTick))),
                TickMath.getSqrtRatioAtTick((int24(tickInfo[i].minUpperTick))),
                uint128(rewardDetails[i].liquidity)
            );

            (rewardDetails[i].maxAmount0, rewardDetails[i].maxAmount1) = LiquidityAmounts.getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick((int24(tickInfo[i].maxLowerTick))),
                TickMath.getSqrtRatioAtTick((int24(tickInfo[i].maxUpperTick))),
                uint128(rewardDetails[i].liquidity)
            );

            if (tickInfo[i].key.startTime < block.timestamp) {
                bytes32 incentiveId = keccak256(abi.encode(tickInfo[i].key));

                Incentive memory incentive;
                (incentive.totalRewardUnclaimed, incentive.totalSecondsClaimedX128, incentive.numberOfStakes) = staker
                    .incentives(incentiveId);

                uint256 totalSecondsUnclaimedX128 = ((Math.max(tickInfo[i].key.endTime, block.timestamp) -
                    tickInfo[i].key.startTime) << 128) - incentive.totalSecondsClaimedX128;
                rewardDetails[i].rate = uint256(
                    (incentive.totalRewardUnclaimed * 0x100000000000000000000000000000000) /
                        uint256(totalSecondsUnclaimedX128)
                );
            }
        }
    }

    struct PoolInfo {
        int24 tick;
        int24 tickspacing;
        address token0;
        address token1;
        uint128 liquidity;
        uint128 maxLiquidityPerTick;
        uint24 fee;
    }

    function getPoolInfo(address[] memory pools) public view returns (PoolInfo[] memory poolInfo) {
        poolInfo = new PoolInfo[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            IUniswapV3Pool pool = IUniswapV3Pool(pools[i]);

            (, poolInfo[i].tick, , , , , ) = pool.slot0();
            poolInfo[i].tickspacing = pool.tickSpacing();

            poolInfo[i].token0 = pool.token0();
            poolInfo[i].token1 = pool.token1();

            poolInfo[i].liquidity = pool.liquidity();
            poolInfo[i].maxLiquidityPerTick = pool.maxLiquidityPerTick();

            poolInfo[i].fee = pool.fee();
        }
    }

    function getRewardsRate(IUniswapV3Staker.IncentiveKey memory key) public view returns (uint256 rate) {
        if (key.startTime >= block.timestamp) return 0;
        bytes32 incentiveId = keccak256(abi.encode(key));

        Incentive memory incentive;
        (incentive.totalRewardUnclaimed, incentive.totalSecondsClaimedX128, incentive.numberOfStakes) = staker
            .incentives(incentiveId);

        uint256 totalSecondsUnclaimedX128 = ((Math.max(key.endTime, block.timestamp) - key.startTime) << 128) -
            incentive.totalSecondsClaimedX128;
        rate = uint256(
            (incentive.totalRewardUnclaimed * 0x100000000000000000000000000000000) / uint256(totalSecondsUnclaimedX128)
        );
    }

    function getUserLiquidity(uint256 tokenId)
        public
        view
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        PositionInfo memory pInfo = positions(tokenId);
        liquidity = pInfo.liquidity;
        IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(tokenId));
        (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(pInfo.tickLower),
            TickMath.getSqrtRatioAtTick(pInfo.tickUpper),
            uint128(liquidity)
        );
    }

    function getPoolsLiquidity(uint256 tokenId) public view returns (uint128 liquidity) {
        address poolAddr = getPoolAddress(tokenId);
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        liquidity = pool.liquidity();
    }

    function getPositionLiquidity(
        address poolAddr,
        int24 lowerTick,
        int24 upperTick
    ) public view returns (uint128 liquidity) {
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        (liquidity, , , , ) = pool.positions(keccak256(abi.encodePacked(address(nftManager), lowerTick, upperTick)));
    }

    struct PositionParams {
        uint256 tokenId;
        IUniswapV3Staker.IncentiveKey incentiveKey;
    }

    struct PositionInformation {
        uint256 reward;
        uint256 rewardToCollect;
        int24 lowerTick;
        int24 upperTick;
        uint256 userLiquidity;
        uint256 totalLiquidity;
        RewardDetails rewardDetails;
    }

    function getPositions(address user, PositionParams[] memory paramArray)
        external
        view
        returns (PositionInformation[] memory)
    {
        PositionInformation[] memory positionInfo = new PositionInformation[](paramArray.length);
        for (uint256 i = 0; i < paramArray.length; i++) {
            (positionInfo[i].reward, positionInfo[i].rewardToCollect) = getUnclaimedRewards(
                paramArray[i].incentiveKey,
                paramArray[i].tokenId,
                user,
                address(paramArray[i].incentiveKey.rewardToken)
            );
            PositionInfo memory pInfo = positions(paramArray[i].tokenId);
            positionInfo[i].userLiquidity = pInfo.liquidity;
            positionInfo[i].lowerTick = pInfo.tickLower;
            positionInfo[i].upperTick = pInfo.tickUpper;
            positionInfo[i].rewardDetails = getPositionRewardsDetails(
                paramArray[i].incentiveKey,
                uint128(positionInfo[i].userLiquidity),
                positionInfo[i].lowerTick,
                positionInfo[i].upperTick
            );

            IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(paramArray[i].tokenId));
            positionInfo[i].totalLiquidity = pool.liquidity();
        }

        return positionInfo;
    }

    function isPoolExist(address[] memory pools) public view returns (bool[] memory isValidPools) {
        isValidPools = new bool[](pools.length);
        for (uint256 i = 0; i < pools.length; i++) {
            isValidPools[i] = isContract(pools[i]);
        }
    }
}

contract InstaUniswapStakerResolver is Resolver {
    string public constant name = "UniswapV3-Staker-Resolver-v1";
}
