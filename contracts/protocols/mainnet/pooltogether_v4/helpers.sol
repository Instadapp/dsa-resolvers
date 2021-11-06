// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { TokenInterface, DrawBufferInterface } from "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    /**
     * @dev get Pool Together Token Address
     */
    function getPoolToken() public pure returns (TokenInterface) {
        return TokenInterface(address(0x0cEC1A9154Ff802e7934Fc916Ed7Ca50bDE6844e));
    }

    struct PrizePoolData {
        address token; // Address of the underlying ERC20 asset
        TicketData ticketData; // An array of the Tokens controlled by the Prize Pool (ie. Tickets, Sponsorship)
        uint256 balance; // The total underlying balance of all assets. This includes both principal and interest.
        uint256 accountedBalance; // The total of all controlled tokens
        uint256 awardBalance;
        uint256 liquidityCap; // The total amount of funds that the prize pool can hold.
        DrawBeaconData drawBeaconData;
        DrawData drawsData;
        Timelock timelock;
        bool hasElapsed;
    }

    struct TokenData {
        uint256 balance;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct TicketData {
        address addr;
        uint256 balanceOf; // User Balance
        uint256 balanceAt;
        string name;
        string symbol;
        uint256 decimals;
        address delegateOf;
    }

    struct DrawBeaconData {
        bool isRngCompleted;
        bool isRngRequested;
        bool isRngTimedOut;
        bool canStartDraw;
        bool canCompleteDraw;
        uint64 nextBeaconPeriodStartTimeFromCurrentTime;
        uint64 beaconPeriodRemainingSeconds;
        uint64 beaconPeriodEndAt;
        uint32 beaconPeriodSeconds;
        uint64 beaconPeriodStartedAt;
        DrawBufferInterface drawBuffer;
        uint32 nextDrawId;
        uint32 lastRngLockBlock;
        uint32 rngTimeout;
        bool isBeaconPeriodOver;
    }

    struct DrawData {
        Draw[] draws;
        PrizeDistribution[] prizeDistributions;
        uint256[] normalizedBalancesForDrawIds;
        UserDrawData[] userDrawData;
    }

    struct UserDrawData {
        uint64 drawPicks;
        uint256 balanceAt;
        uint256 payoutBalance; // > 0 if user has claimed prize
    }

    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint104 numberOfPicks;
        uint32[16] tiers;
        uint256 prize;
    }

    struct Timelock {
        uint64 timestamp;
        uint32 drawId;
    }
}
