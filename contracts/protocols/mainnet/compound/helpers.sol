// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { ComptrollerLensInterface, TokenInterface, IChainlinkOracle } from "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     * @dev Chainlink ETH/USD Price Oracle Interface
     */
    IChainlinkOracle internal constant ETH_PRICE_ORACLE = 
        IChainlinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    
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
        uint256 compSupplySpeed;
        uint256 compBorrowSpeed;
        bool isComped;
        bool isBorrowPaused;
    }
}
