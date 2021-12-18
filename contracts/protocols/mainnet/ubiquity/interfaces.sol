// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC1155.sol";

interface ITWAPOracle {
    function update() external;

    function token0() external view returns (address);

    function consult(address token) external view returns (uint256 amountOut);
}

interface IUbiquityAlgorithmicDollarManager {
    function twapOracleAddress() external view returns (address);

    function dollarTokenAddress() external view returns (address);

    function autoRedeemTokenAddress() external view returns (address);

    function governanceTokenAddress() external view returns (address);

    function curve3PoolTokenAddress() external view returns (address);

    function stableSwapMetaPoolAddress() external view returns (address);

    function debtCouponAddress() external view returns (address);

    function bondingShareAddress() external view returns (address);

    function masterChefAddress() external view returns (address);
}

interface IBondingShareV2 {
    struct Bond {
        address minter;
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        uint256 lpRewardDebt;
        uint256 endBlock;
        uint256 lpAmount;
    }

    function holderTokens(address) external view returns (uint256[] memory);

    function totalLP() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getBond(uint256 id) external view returns (Bond memory);
}

interface IMasterChefV2 {
    function lastPrice() external view returns (uint256);

    function pendingUGOV(uint256) external view returns (uint256);

    function minPriceDiffToUpdateMultiplier() external view returns (uint256);

    function pool() external view returns (uint256 lastRewardBlock, uint256 accuGOVPerShare);

    function totalShares() external view returns (uint256);

    function uGOVDivider() external view returns (uint256);

    function uGOVPerBlock() external view returns (uint256);

    function uGOVmultiplier() external view returns (uint256);
}
