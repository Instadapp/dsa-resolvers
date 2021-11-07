// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface QiTokenInterface {
    function exchangeRateStored() external view returns (uint256);

    function borrowRatePerTimestamp() external view returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function getCash() external view returns (uint256);
}

interface TokenInterface {
    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function delegates(address) external view returns (address);

    function getCurrentVotes(address) external view returns (uint96);
}

interface OrcaleQi {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface ComptrollerLensInterface {
    function markets(address)
        external
        view
        returns (
            bool,
            uint256,
            bool
        );

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimReward(uint8, address) external;

    function rewardAccrued(uint8, address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function oracle() external view returns (address);

    function rewardSpeeds(uint8, address) external view returns (uint256);
}
