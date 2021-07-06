// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "./../../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     * @dev get MakerDAO MCD Address contract
     */
    function getMcdAddresses() public pure returns (address) {
        return 0xF23196DF1C440345DE07feFbe556a5eF0dcD29F0;
    }

    function getManager() public pure returns (BManagerLike) {
        return BManagerLike(0x3f30c2381CD8B917Dd96EB2f1A4F96D91324BBed);
    }

    struct VaultData {
        uint256 id;
        address owner;
        string colType;
        uint256 collateral;
        uint256 art;
        uint256 debt;
        uint256 liquidatedCol;
        uint256 borrowRate;
        uint256 colPrice;
        uint256 liquidationRatio;
        address vaultAddress;
    }

    struct ColInfo {
        uint256 borrowRate;
        uint256 price;
        uint256 liquidationRatio;
        uint256 vaultDebtCelling;
        uint256 vaultDebtFloor;
        uint256 vaultTotalDebt;
        uint256 totalDebtCelling;
        uint256 TotalDebt;
    }

    /**
     * @dev Convert String to bytes32.
     */
    function stringToBytes32(string memory str) internal pure returns (bytes32 result) {
        require(bytes(str).length != 0, "String-Empty");
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            result := mload(add(str, 32))
        }
    }

    /**
     * @dev Convert bytes32 to String.
     */
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes32 _temp;
        uint256 count;
        for (uint256 i; i < 32; i++) {
            _temp = _bytes32[i];
            if (_temp != bytes32(0)) {
                count += 1;
            }
        }
        bytes memory bytesArray = new bytes(count);
        for (uint256 i; i < count; i++) {
            bytesArray[i] = (_bytes32[i]);
        }
        return (string(bytesArray));
    }

    function getFee(bytes32 ilk) internal view returns (uint256 fee) {
        address jug = InstaMcdAddress(getMcdAddresses()).jug();
        (uint256 duty, ) = JugLike(jug).ilks(ilk);
        uint256 base = JugLike(jug).base();
        fee = add(duty, base);
    }

    function getColPrice(bytes32 ilk) internal view returns (uint256 price) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (, uint256 mat) = SpotLike(spot).ilks(ilk);
        (, , uint256 spotPrice, , ) = VatLike(vat).ilks(ilk);
        price = rmul(mat, spotPrice);
    }

    function getColRatio(bytes32 ilk) internal view returns (uint256 ratio) {
        address spot = InstaMcdAddress(getMcdAddresses()).spot();
        (, ratio) = SpotLike(spot).ilks(ilk);
    }

    function getDebtFloorAndCeiling(bytes32 ilk)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        address vat = InstaMcdAddress(getMcdAddresses()).vat();
        (uint256 totalArt, uint256 rate, , uint256 vaultDebtCellingRad, uint256 vaultDebtFloor) =
            VatLike(vat).ilks(ilk);
        uint256 vaultDebtCelling = vaultDebtCellingRad / 10**45;
        uint256 vaultTotalDebt = rmul(totalArt, rate);

        uint256 totalDebtCelling = VatLike(vat).Line();
        uint256 totalDebt = VatLike(vat).debt();
        return (vaultDebtCelling, vaultTotalDebt, vaultDebtFloor, totalDebtCelling, totalDebt);
    }

    function getAddtionalDebt(uint256 id) internal view returns(uint256) {
        return getManager().cushion(id);
    }
}
