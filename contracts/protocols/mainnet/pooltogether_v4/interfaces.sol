// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./helpers.sol";

interface PrizePoolInterface {
    function balance() external returns (uint256);

    function getLiquidityCap() external view returns (uint256);

    function getTicket() external view returns (TicketInterface);

    function getToken() external view returns (address);

    function prizeStrategy() external view returns (address);

    function awardBalance() external view returns (uint256);

    function getAccountedBalance() external view returns (uint256);
}

interface TokenInterface {
    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);
}

interface TicketInterface {
    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function delegateOf(address user) external view returns (address);

    function getBalanceAt(address user, uint64 timestamp) external view returns (uint256);

    function getBalancesAt(address user, uint64[] calldata timestamps) external view returns (uint256[] memory);

    function getAverageBalanceBetween(
        address user,
        uint64 startTime,
        uint64 endTime
    ) external view returns (uint256);

    function getTotalSupplyAt(uint64 timestamp) external view returns (uint256);

    function getAverageTotalSuppliesBetween(uint64[] calldata startTimes, uint64[] calldata endTimes)
        external
        view
        returns (uint256[] memory);
}

interface PrizeStrategyInterface {
    function prizePeriodRemainingSeconds() external view returns (uint256);

    function isPrizePeriodOver() external view returns (bool);

    function prizePeriodEndAt() external view returns (uint256);

    function calculateNextPrizePeriodStartTime(uint256 currentTime) external view returns (uint256);

    function getExternalErc20Awards() external view returns (address[] memory);

    function getExternalErc721Awards() external view returns (address[] memory);

    function tokenListener() external view returns (address);
}

interface DrawBeaconInterface {
    function isRngCompleted() external view returns (bool);

    function isRngRequested() external view returns (bool);

    function isRngTimedOut() external view returns (bool);

    function canStartDraw() external view returns (bool);

    function canCompleteDraw() external view returns (bool);

    function calculateNextBeaconPeriodStartTimeFromCurrentTime() external view returns (uint64);

    function beaconPeriodRemainingSeconds() external view returns (uint64);

    function beaconPeriodEndAt() external view returns (uint64);

    function getBeaconPeriodSeconds() external view returns (uint32);

    function getBeaconPeriodStartedAt() external view returns (uint64);

    function getDrawBuffer() external view returns (DrawBufferInterface);

    function getNextDrawId() external view returns (uint32);

    function getLastRngLockBlock() external view returns (uint32);

    function getRngTimeout() external view returns (uint32);

    function isBeaconPeriodOver() external view returns (bool);
}

interface DrawBufferInterface {
    function getDraw(uint32 drawId) external view returns (Helpers.Draw memory);

    function getDraws(uint32[] calldata _drawIds) external view returns (Helpers.Draw[] memory);

    function getDrawCount() external view returns (uint32);
}

interface PrizeDistributorInterface {
    function getDrawCalculator() external view returns (DrawCalculatorInterface);

    function getDrawPayoutBalanceOf(address _user, uint32 _drawId) external view returns (uint256);
}

interface PrizeDistributionBufferInterface {
    function getPrizeDistribution(uint32 _drawId) external view returns (Helpers.PrizeDistribution memory);

    function getPrizeDistributions(uint32[] calldata _drawIds)
        external
        view
        returns (Helpers.PrizeDistribution[] memory);

    function getPrizeDistributionCount() external view returns (uint32);
}

interface DrawCalculatorInterface {
    function getDrawBuffer() external view returns (DrawBufferInterface);

    function getPrizeDistributionBuffer() external view returns (PrizeDistributionBufferInterface);

    function getNormalizedBalancesForDrawIds(address user, uint32[] calldata drawIds)
        external
        view
        returns (uint256[] memory);

    function calculate(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _pickIndicesForDraws
    ) external view returns (uint256[] memory, bytes memory);

    function ticket() external view returns (TicketInterface);
}

interface DrawCalculatorTimelockInterface {
    function getDrawCalculator() external view returns (DrawCalculatorInterface);

    function hasElapsed() external view returns (bool);

    function getTimelock() external view returns (Helpers.Timelock memory);
}
