// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface CTokenInterface {
    function exchangeRateStored() external view returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function borrowBalanceStored(address) external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function underlying() external view returns (address);

    function balanceOf(address) external view returns (uint256);

    function getCash() external view returns (uint256);
}

interface TokenInterface {
    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

interface OrcaleComp {
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

    function claimComp(address) external;

    function compAccrued(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);

    function borrowGuardianPaused(address) external view returns (bool);

    function oracle() external view returns (address);

    function compSpeeds(address) external view returns (uint256);
}

interface CompReadInterface {
    struct CompBalanceMetadataExt {
        uint256 balance;
        uint256 votes;
        address delegate;
        uint256 allocated;
    }

    function getCompBalanceMetadataExt(
        TokenInterface comp,
        ComptrollerLensInterface comptroller,
        address account
    ) external returns (CompBalanceMetadataExt memory);
}

interface BCompoundRegistry {
    function avatarOf(address owner) external view returns (address);
}

interface BAvatar {
    function toppedUpCToken() external view returns (address);
    function toppedUpAmount() external view returns (uint256);
}
