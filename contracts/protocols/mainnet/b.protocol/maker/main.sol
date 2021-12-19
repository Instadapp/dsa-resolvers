// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract VaultResolver is Helpers {
    function getVaults(address owner) external view returns (VaultData[] memory) {
        address manager = address(getManager());
        address cdpManger = InstaMcdAddress(getMcdAddresses()).getCdps();

        (uint256[] memory ids, address[] memory urns, bytes32[] memory ilks) =
            CdpsLike(cdpManger).getCdpsAsc(manager, owner);
        VaultData[] memory vaults = new VaultData[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            (uint256 ink, uint256 art) = VatLike(ManagerLike(manager).vat()).urns(ilks[i], urns[i]);
            art = add(art, getAddtionalDebt(ids[i]));
            (, uint256 rate, uint256 priceMargin, , ) = VatLike(ManagerLike(manager).vat()).ilks(ilks[i]);
            uint256 mat = getColRatio(ilks[i]);

            vaults[i] = VaultData(
                ids[i],
                owner,
                bytes32ToString(ilks[i]),
                ink,
                art,
                rmul(art, rate),
                VatLike(ManagerLike(manager).vat()).gem(ilks[i], urns[i]),
                getFee(ilks[i]),
                rmul(priceMargin, mat),
                mat,
                urns[i]
            );
        }
        return vaults;
    }

    function getVaultById(uint256 id) external view returns (VaultData memory) {
        address manager = address(getManager());
        address urn = ManagerLike(manager).urns(id);
        bytes32 ilk = ManagerLike(manager).ilks(id);

        (uint256 ink, uint256 art) = VatLike(ManagerLike(manager).vat()).urns(ilk, urn);
        art = add(art, getAddtionalDebt(id));
        (, uint256 rate, uint256 priceMargin, , ) = VatLike(ManagerLike(manager).vat()).ilks(ilk);

        uint256 mat = getColRatio(ilk);

        uint256 feeRate = getFee(ilk);
        VaultData memory vault =
            VaultData(
                id,
                ManagerLike(manager).owns(id),
                bytes32ToString(ilk),
                ink,
                art,
                rmul(art, rate),
                VatLike(ManagerLike(manager).vat()).gem(ilk, urn),
                feeRate,
                rmul(priceMargin, mat),
                mat,
                urn
            );
        return vault;
    }

    function getColInfo(string[] memory name) public view returns (ColInfo[] memory) {
        ColInfo[] memory colInfo = new ColInfo[](name.length);

        for (uint256 i = 0; i < name.length; i++) {
            bytes32 ilk = stringToBytes32(name[i]);
            (
                uint256 vaultDebtCelling,
                uint256 vaultDebtFloor,
                uint256 vaultTotalDebt,
                uint256 totalDebtCelling,
                uint256 totalDebt
            ) = getDebtFloorAndCeiling(ilk);

            colInfo[i] = ColInfo(
                getFee(ilk),
                getColPrice(ilk),
                getColRatio(ilk),
                vaultDebtCelling,
                vaultTotalDebt,
                vaultDebtFloor,
                totalDebtCelling,
                totalDebt
            );
        }
        return colInfo;
    }
}

contract DSRResolver is VaultResolver {
    function getDsrRate() public view returns (uint256 dsr) {
        address pot = InstaMcdAddress(getMcdAddresses()).pot();
        dsr = PotLike(pot).dsr();
    }

    function getDaiPosition(address owner) external view returns (uint256 amt, uint256 dsr) {
        address pot = InstaMcdAddress(getMcdAddresses()).pot();
        uint256 chi = PotLike(pot).chi();
        uint256 pie = PotLike(pot).pie(owner);
        amt = rmul(pie, chi);
        dsr = getDsrRate();
    }
}

contract InstaBMakerResolver is DSRResolver {
    string public constant name = "B.Maker-Resolver-v1.0";
}
