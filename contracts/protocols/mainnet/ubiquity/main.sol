// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getUbiquityAddresses() public view returns (UbiquityAddresses memory addresses) {
        addresses.ubiquityManagerAddress = address(ubiquityManager);
        addresses.masterChefAddress = address(getMasterChef());
        addresses.twapOracleAddress = address(getTWAPOracle());
        addresses.uadAddress = address(getUAD());
        addresses.uarAddress = address(getUAR());
        addresses.udebtAddress = address(getUDEBT());
        addresses.ubqAddress = address(getUBQ());
        addresses.cr3Address = address(getCRV3());
        addresses.uadcrv3Address = address(getUADCRV3());
        addresses.bondingShareAddress = address(getBondingShare());
        addresses.dsaResolverAddress = address(this);
        addresses.dsaConnectorAddress = address(dsaConnectorAddress);
    }

    function getUbiquityDatas() public view returns (UbiquityDatas memory datas) {
        datas.twapPrice = getTWAPOracle().consult(getTWAPOracle().token0());
        datas.uadTotalSupply = getUAD().totalSupply();
        datas.uarTotalSupply = getUAR().totalSupply();
        datas.ubqTotalSupply = getUBQ().totalSupply();
        datas.uadcrv3TotalSupply = getUADCRV3().totalSupply();
        datas.bondingSharesTotalSupply = getBondingShare().totalSupply();
        datas.lpTotalSupply = getBondingShare().totalLP();
    }

    function getUbiquityInventory(address user) public view returns (UbiquityInventory memory inventory) {
        inventory.uadBalance = getUAD().balanceOf(user);
        inventory.uarBalance = getUAR().balanceOf(user);
        inventory.ubqBalance = getUBQ().balanceOf(user);
        inventory.crv3Balance = getCRV3().balanceOf(user);
        inventory.uad3crvBalance = getUADCRV3().balanceOf(user);
        inventory.bondingSharesBalance = getBondingShareBalanceOf(user);
        inventory.lpBalance = getBondingShareBalanceOf(user);
        inventory.bondBalance = getBondingShareIds(user).length;
        inventory.ubqPendingBalance = getPendingUBQ(user);
    }
}

contract InstaUbiquityResolver is Resolver {
    string public constant name = "Ubiquity-Resolver-v0.1";
}
