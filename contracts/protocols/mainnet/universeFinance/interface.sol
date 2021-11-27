pragma solidity ^0.7.6;
pragma abicoder v2;

interface IUniverseAdapter {

    function depositProxy(
        address universeVault,
        uint256 amount0,
        uint256 amount1
    ) external returns(uint256, uint256);

}

interface IUniverseResolver {

    function getAllVaultAddress() external view returns(address[] memory vaults);

    function checkUniverseVault(address universeVault) external view returns(bool status);

}

interface IVaultV3 {

    function getShares(
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 share0, uint256 share1);

    function getBals(
        uint256 share0,
        uint256 share1
    ) external view returns (uint256 amount0, uint256 amount1);

    function getUserShares(address user) external view returns (uint256 share0, uint256 share1);

    function token0() external view returns (address);

    function token1() external view returns (address);

    struct MaxShares {
        uint256 maxToken0Amt;
        uint256 maxToken1Amt;
        uint256 maxSingeDepositAmt0;
        uint256 maxSingeDepositAmt1;
    }

    function maxShares() external view returns (MaxShares memory);

    function getTotalAmounts() external view returns (
        uint256 total0,
        uint256 total1,
        uint256 free0,
        uint256 free1,
        uint256 utilizationRate0,
        uint256 utilizationRate1
    );

    function getPNL() external view returns (uint256 rate, uint256 param);
}
