// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

import "hardhat/console.sol";

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
    function getUnclaimedRewards(address token, address user) external view returns (uint256 amount) {
        amount = staker.rewards(IERC20Minimal(token), user);
    }

    /**
     * @dev get rewards rate of incentive
     * @param key incentive key
     */
    function getRewardsRate(IUniswapV3Staker.IncentiveKey memory key) external view returns (uint256 rate) {
        bytes32 incentiveId = getIncentiveId(key);
        (uint256 totalRewards, , ) = staker.incentives(incentiveId);
        uint256 totalSeconds = key.endTime - key.startTime;
        rate = uint256(uint256(totalRewards) / uint256(totalSeconds));
    }

    /**
     * @dev get users deposited liquidity
     * @param tokenId deposited token id
     */
    function getUsersLiquidity(uint256 tokenId) external view returns (uint128 liquidity) {
        PositionInfo memory pInfo = positions(tokenId);
        liquidity = pInfo.liquidity;
    }

    /**
     * @dev get pool liquidity
     * @param tokenId deposited token id
     */
    function getPoolsLiquidity(uint256 tokenId) external view returns (uint128 liquidity) {
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
}

contract InstaUniswapStakerResolver is Resolver {
    string public constant name = "UniswapV3-Resolver-v1";
}
