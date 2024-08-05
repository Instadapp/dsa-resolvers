// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import {Id} from "./interfaces/IMorpho.sol";

interface TokenInterface {
    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface VaultInterface {
    function decimals() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function nonces(address) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);

    function maxDeposit(address) external view returns (uint256);

    function maxMint(address) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);
}

interface MorphoBlueInterface {
    function idToMarketParams(Id id)
        external
        view
        returns (address loanToken, address collateralToken, address oracle, address irm, uint256 lltv);
}

interface MetaMorphoInterface {
    function fee() external view returns (uint96);
    function supplyQueue(uint256) external view returns (Id);
    function config(Id) external view returns (uint184 cap, bool enabled, uint64 removableAt);
}

interface IRewardsEmissions {
    function rewardsEmissions(
        address sender, 
        address urd,
        address rewardToken, 
        bytes32 marketId
    )
    external 
    view 
    returns (
        uint256 supplyRewardTokensPerYear, 
        uint256 borrowRewardTokensPerYear, 
        uint256 collateralRewardTokensPerYear
    );
}