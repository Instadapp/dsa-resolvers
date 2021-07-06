// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { ComptrollerLensInterface, TokenInterface, BCompoundRegistry, BAvatar } from "./interfaces.sol";
import { DSMath } from "./../../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     * @dev get Compound Comptroller
     */
    function getComptroller() public pure returns (ComptrollerLensInterface) {
        return ComptrollerLensInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    }

    /**
     * @dev get Compound Open Feed Oracle Address
     */
    function getOracleAddress() public view returns (address) {
        return getComptroller().oracle();
    }

    /**
     * @dev get Comp Read Address
     */
    function getCompReadAddress() public pure returns (address) {
        return 0xd513d22422a3062Bd342Ae374b4b9c20E0a9a074;
    }

    /**
     * @dev get ETH Address
     */
    function getCETHAddress() public pure returns (address) {
        return 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    }

    /**
     * @dev get Comp Token Address
     */
    function getCompToken() public pure returns (TokenInterface) {
        return TokenInterface(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    }

    /**
     * @dev get B.Registery Address
     */
    function getBRegistery() public pure returns (BCompoundRegistry) {
        return BCompoundRegistry(0xbF698dF5591CaF546a7E087f5806E216aFED666A);
    }

    /**
     * @dev get owner avatar
     */
    function getOwnerBAvatar(address owner) public view returns (address) {
        return getBRegistery().avatarOf(owner);
    }

    /**
     * @dev get owner cushion debt
     */
    function getOwnerAddtionalDebt(address avatar, address ctoken) public view returns (uint) {
        if(avatar == address(0)) return 0;

        if(BAvatar(avatar).toppedUpCToken() == ctoken) return BAvatar(avatar).toppedUpAmount();
        else return 0;
    }    

    struct CompData {
        uint256 tokenPriceInEth;
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
        uint256 compSpeed;
        bool isComped;
        bool isBorrowPaused;
    }
}
