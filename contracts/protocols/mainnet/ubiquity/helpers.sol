// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";

contract Helpers {
    address internal constant dsaConnectorAddress = 0x164B772671A7c2b16FC965Ce74583D361075b3B5;

    IUbiquityAlgorithmicDollarManager internal constant ubiquityManager =
        IUbiquityAlgorithmicDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);

    struct UbiquityAddresses {
        address ubiquityManagerAddress;
        address masterChefAddress;
        address twapOracleAddress;
        address uadAddress;
        address uarAddress;
        address udebtAddress;
        address ubqAddress;
        address cr3Address;
        address uadcrv3Address;
        address bondingShareAddress;
        address dsaResolverAddress;
        address dsaConnectorAddress;
    }

    struct UbiquityDatas {
        uint256 twapPrice;
        uint256 uadTotalSupply;
        uint256 uarTotalSupply;
        uint256 udebtTotalSupply;
        uint256 ubqTotalSupply;
        uint256 uadcrv3TotalSupply;
        uint256 bondingSharesTotalSupply;
        uint256 lpTotalSupply;
    }

    struct UbiquityInventory {
        uint256 uadBalance;
        uint256 uarBalance;
        uint256 udebtBalance;
        uint256 ubqBalance;
        uint256 crv3Balance;
        uint256 uad3crvBalance;
        uint256 ubqRewards;
        uint256 bondingSharesBalance;
        uint256 lpBalance;
        uint256 bondBalance;
        uint256 ubqPendingBalance;
    }

    function getMasterChef() internal view returns (IMasterChefV2) {
        return IMasterChefV2(ubiquityManager.masterChefAddress());
    }

    function getTWAPOracle() internal view returns (ITWAPOracle) {
        return ITWAPOracle(ubiquityManager.twapOracleAddress());
    }

    function getUAD() internal view returns (IERC20) {
        return IERC20(ubiquityManager.dollarTokenAddress());
    }

    function getUAR() internal view returns (IERC20) {
        return IERC20(ubiquityManager.autoRedeemTokenAddress());
    }

    function getUBQ() internal view returns (IERC20) {
        return IERC20(ubiquityManager.governanceTokenAddress());
    }

    function getCRV3() internal view returns (IERC20) {
        return IERC20(ubiquityManager.curve3PoolTokenAddress());
    }

    function getUADCRV3() internal view returns (IERC20) {
        return IERC20(ubiquityManager.stableSwapMetaPoolAddress());
    }

    function getUDEBT() internal view returns (IERC1155) {
        return IERC1155(ubiquityManager.debtCouponAddress());
    }

    function getBondingShare() internal view returns (IBondingShareV2) {
        return IBondingShareV2(ubiquityManager.bondingShareAddress());
    }

    function getBondingShareIds(address user) internal view returns (uint256[] memory bondIds) {
        return getBondingShare().holderTokens(user);
    }

    function getBondingShareBalanceOf(address user) internal view returns (uint256 balance) {
        uint256[] memory bondIds = getBondingShareIds(user);
        for (uint256 i = 0; i < bondIds.length; i += 1) {
            balance += getBondingShare().getBond(bondIds[i]).lpAmount;
        }
    }

    function getPendingUBQ(address user) internal view returns (uint256 amount) {
        uint256[] memory bondIds = getBondingShareIds(user);
        for (uint256 i = 0; i < bondIds.length; i += 1) {
            amount += getMasterChef().pendingUGOV(bondIds[i]);
        }
    }
}
