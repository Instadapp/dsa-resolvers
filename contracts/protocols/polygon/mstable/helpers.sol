// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    //
    struct VaultData {
        uint256 credits;
        uint256 balance;
        uint256 exchangeRate;
        uint256 rewardsEarned;
        uint256 platformRewards;
    }

    address internal constant mUsdToken = 0xE840B73E5287865EEc17d250bFb1536704B43B21;
    address internal constant imUsdToken = 0x5290Ad3d83476CA6A2b178Cd9727eE1EF72432af;
    address internal constant imUsdVault = 0x32aBa856Dc5fFd5A56Bcd182b13380e5C855aa29;
}
