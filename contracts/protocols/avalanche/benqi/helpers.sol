// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { ComptrollerLensInterface, TokenInterface } from "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     * @dev get Benqi Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4);
    }

    /**
     * @dev get Benqi Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

    /**
     * @dev get QiAVAX Address
     */
    function getQiAVAXAddress() public pure returns (address) {
        return 0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    }

    /**
     * @dev get Qi Token Address
     */
    function getQiToken() public pure returns (TokenInterface) {
        return TokenInterface(0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5);
    }

    struct BenqiData {
        uint256 tokenPriceInAvax;
        uint256 tokenPriceInUsd;
        uint256 exchangeRateStored;
        uint256 balanceOfUser;
        uint256 borrowBalanceStoredUser;
        uint256 totalBorrows;
        uint256 totalSupplied;
        uint256 borrowCap;
        uint256 supplyRatePerBlock;
        uint256 borrowRatePerBlock;
        uint256 collateralFactor;
        uint256 rewardSpeed;
        bool isQied;
        bool isBorrowPaused;
    }
}
