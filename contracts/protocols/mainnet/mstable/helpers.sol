// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    //
    struct VaultData {
        uint256 credits;
        uint256 balance;
        uint256 exchangeRage;
        uint256 rewardsEarned;
        uint256 rewardsUnclaimed;
        uint256 rewardsLocked;
    }

    address internal constant mUsdToken = 0xe2f2a5C287993345a840Db3B0845fbC70f5935a5;
    address internal constant imUsdToken = 0x30647a72Dc82d7Fbb1123EA74716aB8A317Eac19;
    address internal constant imUsdVault = 0x78BefCa7de27d07DC6e71da295Cc2946681A6c7B;
}
