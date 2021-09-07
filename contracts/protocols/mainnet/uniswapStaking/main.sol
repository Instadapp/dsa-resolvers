// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    /**
     * @dev Get deposited token
     * @param user wallet address
     */
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

    /**
     * @dev Get deposited pool Info
     * @param user wallet address
     */
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

    /**
     * @dev get unclaimed Rewards
     * @param token reward token address
     * @param user wallet address
     */
    function getUnclaimedRewards(address token, address user) public view returns (uint256 amount) {
        amount = staker.rewards(IERC20Minimal(token), user);
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

    /**
     * @dev get rewards rate of incentive
     * @param key incentive key
     */
    function getRewardsRate(IUniswapV3Staker.IncentiveKey memory key) public view returns (uint256 rate) {
        if (key.startTime >= block.timestamp) return 0;

        bytes32 incentiveId = keccak256(abi.encode(key));

        Incentive memory incentive;
        (incentive.totalRewardUnclaimed, incentive.totalSecondsClaimedX128, incentive.numberOfStakes) = staker
        .incentives(incentiveId);

        uint256 totalSecondsUnclaimedX128 = ((Math.max(key.endTime, block.timestamp) - key.startTime) << 128) -
            incentive.totalSecondsClaimedX128;

        rate = uint256(incentive.totalRewardUnclaimed / uint256(totalSecondsUnclaimedX128));
    }

    /**
     * @dev get users deposited liquidity
     * @param tokenId deposited token id
     */
    function getUsersLiquidity(uint256 tokenId) public view returns (uint128 liquidity) {
        PositionInfo memory pInfo = positions(tokenId);
        liquidity = pInfo.liquidity;
    }

    /**
     * @dev get pool liquidity
     * @param tokenId deposited token id
     */
    function getPoolsLiquidity(uint256 tokenId) public view returns (uint128 liquidity) {
        address poolAddr = getPoolAddress(tokenId);
        IUniswapV3Pool pool = IUniswapV3Pool(poolAddr);
        liquidity = pool.liquidity();
    }

    /**
     * @dev get incentive key
     */
    function getIncentiveKey(
        address _rewardToken,
        address _refundee,
        address _poolAddr,
        uint256 _length
    ) external view returns (IUniswapV3Staker.IncentiveKey memory _key) {
        IUniswapV3Pool pool = IUniswapV3Pool(_poolAddr);
        _key = IUniswapV3Staker.IncentiveKey(
            IERC20Minimal(_rewardToken),
            pool,
            block.timestamp + 1,
            block.timestamp + _length,
            _refundee
        );
    }

    struct PositionParams {
        uint256 tokenId;
        IUniswapV3Staker.IncentiveKey incentiveKey;
    }

    struct PositionInformation {
        uint256 unclaimed;
        uint256 rates;
        uint256 userLiquidities;
        uint256 totalLiquidities;
    }

    /**
     * @dev get positions info
     */
    function getPositions(PositionParams[] memory paramArray, address user)
        external
        view
        returns (PositionInformation[] memory)
    {
        PositionInformation[] memory positionInfo = new PositionInformation[](paramArray.length);
        for (uint256 i = 0; i < paramArray.length; i++) {
            positionInfo[i].unclaimed = getUnclaimedRewards(address(paramArray[i].incentiveKey.rewardToken), user);
            positionInfo[i].rates = getRewardsRate(paramArray[i].incentiveKey);
            positionInfo[i].userLiquidities = positions(paramArray[i].tokenId).liquidity;
            IUniswapV3Pool pool = IUniswapV3Pool(getPoolAddress(paramArray[i].tokenId));
            positionInfo[i].totalLiquidities = pool.liquidity();
        }

        return positionInfo;
    }
}

contract InstaUniswapStakerResolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
