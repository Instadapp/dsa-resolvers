// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface PrizePoolInterface {
    function balance() external returns (uint256);

    function maxExitFeeMantissa() external view returns (uint256);

    function reserveTotalSupply() external view returns (uint256);

    function liquidityCap() external view returns (uint256);

    function balanceOfCredit(address user, address controlledToken) external returns (uint256);

    function token() external view returns (address);

    function prizeStrategy() external view returns (address);

    function tokens() external view returns (TokenInterface[] memory);

    function accountedBalance() external view returns (uint256);

    function calculateEarlyExitFee(
        address from,
        address controlledToken,
        uint256 amount
    ) external returns (uint256 exitFee, uint256 burnedCredit);

    function creditPlanOf(address controlledToken)
        external
        view
        returns (uint128 creditLimitMantissa, uint128 creditRateMantissa);

    function captureAwardBalance() external returns (uint256);
}

interface TokenFaucetInterface {
    function asset() external view returns (address);

    function dripRatePerSecond() external view returns (uint256);

    function exchangeRateMantissa() external view returns (uint112);

    function totalUnclaimed() external view returns (uint112);

    function lastDripTimestamp() external view returns (uint32);

    function userStates(address addr) external view returns (uint128, uint128);

    function claim(address user) external returns (uint256);
}

interface TokenFaucetProxyFactoryInterface {
    function claimAll(address user, TokenFaucetInterface[] calldata tokenFaucets) external;
}

interface PodInterface {
    function prizePool() external view returns (address);

    function getPricePerShare() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function getEarlyExitFee(uint256 amount) external returns (uint256);

    function balanceOfUnderlying(address user) external view returns (uint256 amount);

    function balance() external view returns (uint256);

    function faucet() external view returns (address);

    function tokenDrop() external view returns (address);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function token() external view returns (address);

    function ticket() external view returns (address);
}

interface TokenInterface {
    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface MultiTokenListenerInterface {
    function getAddresses() external view returns (address[] memory);
}

interface PrizeStrategyInterface {
    function prizePeriodRemainingSeconds() external view returns (uint256);

    function isPrizePeriodOver() external view returns (bool);

    function prizePeriodEndAt() external view returns (uint256);

    function calculateNextPrizePeriodStartTime(uint256 currentTime) external view returns (uint256);

    function getExternalErc20Awards() external view returns (address[] memory);

    function getExternalErc721Awards() external view returns (address[] memory);

    function tokenListener() external view returns (address);
}
