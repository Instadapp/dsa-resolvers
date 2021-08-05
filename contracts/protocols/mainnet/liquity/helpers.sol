// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { DSMath } from "../../../utils/dsmath.sol";
import "./interfaces.sol";

contract Helpers is DSMath {
    TroveManagerLike internal constant troveManager = TroveManagerLike(0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2);

    StabilityPoolLike internal constant stabilityPool = StabilityPoolLike(0x66017D22b0f8556afDd19FC67041899Eb65a21bb);

    StakingLike internal constant staking = StakingLike(0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d);

    PoolLike internal constant activePool = PoolLike(0xDf9Eb223bAFBE5c5271415C75aeCD68C21fE3D7F);

    PoolLike internal constant defaultPool = PoolLike(0x896a3F03176f05CFbb4f006BfCd8723F2B0D741C);

    HintHelpersLike internal constant hintHelpers = HintHelpersLike(0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0);

    SortedTrovesLike internal constant sortedTroves = SortedTrovesLike(0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6);

    PriceFeedOracle internal constant priceFeedOracle = PriceFeedOracle(0x4c517D4e2C851CA76d7eC94B805269Df0f2201De);

    struct Trove {
        uint256 collateral;
        uint256 debt;
        uint256 icr;
    }

    struct StabilityDeposit {
        uint256 deposit;
        uint256 ethGain;
        uint256 lqtyGain;
    }

    struct Stake {
        uint256 amount;
        uint256 ethGain;
        uint256 lusdGain;
    }

    struct Position {
        Trove trove;
        StabilityDeposit stability;
        Stake stake;
    }

    struct System {
        uint256 borrowFee;
        uint256 ethTvl;
        uint256 tcr;
        bool isInRecoveryMode;
    }
}
