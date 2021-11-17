// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getDrawBeaconData(address drawBeaconAddress) public view returns (DrawBeaconData memory) {
        DrawBeaconInterface drawBeacon = DrawBeaconInterface(drawBeaconAddress);

        DrawBeaconData memory drawBeaconData = DrawBeaconData(
            drawBeacon.isRngCompleted(),
            drawBeacon.isRngRequested(),
            drawBeacon.isRngTimedOut(),
            drawBeacon.canStartDraw(),
            drawBeacon.canCompleteDraw(),
            drawBeacon.calculateNextBeaconPeriodStartTimeFromCurrentTime(),
            drawBeacon.beaconPeriodRemainingSeconds(),
            drawBeacon.beaconPeriodEndAt(),
            drawBeacon.getBeaconPeriodSeconds(),
            drawBeacon.getBeaconPeriodStartedAt(),
            drawBeacon.getDrawBuffer(),
            drawBeacon.getNextDrawId(),
            drawBeacon.getLastRngLockBlock(),
            drawBeacon.getRngTimeout(),
            drawBeacon.isBeaconPeriodOver()
        );

        return drawBeaconData;
    }

    function getUserPicks(uint104 numberOfPicks, uint256 normalizedBalance) public pure returns (uint64) {
        return uint64((normalizedBalance * numberOfPicks) / 1 ether);
    }

    function getUserDrawData(
        address owner,
        Draw[] memory draws,
        PrizeDistributorInterface prizeDistributor,
        PrizeDistribution[] memory prizeDistributions,
        address drawCalculatorTimeLockAddress,
        uint32[] memory drawIds
    ) public view returns (UserDrawData[] memory) {
        // Get Contracts
        DrawCalculatorTimelockInterface drawCalculatorTimelock = DrawCalculatorTimelockInterface(
            drawCalculatorTimeLockAddress
        );
        DrawCalculatorInterface drawCalculator = drawCalculatorTimelock.getDrawCalculator();
        TicketInterface ticket = TicketInterface(drawCalculator.ticket());

        uint256[] memory normalizedBalancesForDrawIds = drawCalculator.getNormalizedBalancesForDrawIds(owner, drawIds);

        UserDrawData[] memory userDrawData = new UserDrawData[](draws.length);

        for (uint32 i = 0; i < draws.length; i++) {
            userDrawData[i].drawPicks = getUserPicks(
                prizeDistributions[i].numberOfPicks,
                normalizedBalancesForDrawIds[i]
            );
            userDrawData[i].balanceAt = ticket.getBalanceAt(
                owner,
                draws[i].timestamp - prizeDistributions[i].endTimestampOffset
            );
            userDrawData[i].payoutBalance = prizeDistributor.getDrawPayoutBalanceOf(owner, draws[i].drawId);
        }

        return userDrawData;
    }

    function getAverageTotalSuppliesForDraws(
        Draw[] memory draws,
        PrizeDistribution[] memory prizeDistributions,
        TicketInterface ticket
    ) public view returns (uint256[] memory) {
        uint256[] memory drawTotalSupply = new uint256[](draws.length);

        uint256 drawsLength = draws.length;
        uint64[] memory timestampsWithStartCutoffTimes = new uint64[](drawsLength);
        uint64[] memory timestampsWithEndCutoffTimes = new uint64[](drawsLength);

        for (uint32 i = 0; i < drawsLength; i++) {
            unchecked {
                timestampsWithStartCutoffTimes[i] = draws[i].timestamp - prizeDistributions[i].startTimestampOffset;
                timestampsWithEndCutoffTimes[i] = draws[i].timestamp - prizeDistributions[i].endTimestampOffset;
            }
        }

        return ticket.getAverageTotalSuppliesBetween(timestampsWithStartCutoffTimes, timestampsWithEndCutoffTimes);
    }

    function getDrawsData(
        address owner,
        DrawBeaconData memory drawBeaconData,
        address prizeDistributorAddress,
        address drawCalculatorTimeLockAddress
    ) public view returns (DrawData memory) {
        // Get Contracts
        PrizeDistributorInterface prizeDistributor = PrizeDistributorInterface(prizeDistributorAddress);
        DrawCalculatorTimelockInterface drawCalculatorTimelock = DrawCalculatorTimelockInterface(
            drawCalculatorTimeLockAddress
        );
        PrizeDistributionBufferInterface prizeDistribution = drawCalculatorTimelock
            .getDrawCalculator()
            .getPrizeDistributionBuffer();

        // Get drawIds
        DrawBufferInterface drawBuffer = drawBeaconData.drawBuffer;

        // Get one less than draw counts because prizeDistribution might not be available yet
        uint32[] memory drawIds = new uint32[](drawBuffer.getDrawCount() - 1);
        for (uint32 j = 1; j < drawBuffer.getDrawCount(); j++) {
            drawIds[j - 1] = j;
        }

        // Get Prize Distribution for each draw id
        Draw[] memory draws = drawBuffer.getDraws(drawIds);

        uint256[] memory normalizedBalancesForDrawIds = drawCalculatorTimelock
            .getDrawCalculator()
            .getNormalizedBalancesForDrawIds(owner, drawIds);

        return
            DrawData(
                draws,
                prizeDistribution.getPrizeDistributions(drawIds),
                normalizedBalancesForDrawIds,
                getAverageTotalSuppliesForDraws(
                    draws,
                    prizeDistribution.getPrizeDistributions(drawIds),
                    drawCalculatorTimelock.getDrawCalculator().ticket()
                ),
                getUserDrawData(
                    owner,
                    draws,
                    prizeDistributor,
                    prizeDistribution.getPrizeDistributions(drawIds),
                    drawCalculatorTimeLockAddress,
                    drawIds
                )
            );
    }

    function getPosition(
        address owner,
        address[] memory prizePoolAddress,
        address drawBeaconAddress,
        address prizeDistributorAddress,
        address drawCalculatorTimeLockAddress
    ) public returns (PrizePoolData[] memory) {
        PrizePoolData[] memory prizePoolsData = new PrizePoolData[](prizePoolAddress.length);
        for (uint256 i = 0; i < prizePoolAddress.length; i++) {
            PrizePoolInterface prizePool = PrizePoolInterface(prizePoolAddress[i]);
            // Ticket Data
            TicketInterface ticket = prizePool.getTicket();
            TicketData memory ticketData = TicketData(
                address(ticket),
                ticket.balanceOf(owner),
                ticket.getBalanceAt(owner, uint64(block.timestamp)),
                ticket.getTotalSupplyAt(uint64(block.timestamp)),
                ticket.name(),
                ticket.symbol(),
                ticket.decimals(),
                ticket.delegateOf(owner)
            );

            // Current Draw Beacon Data
            DrawBeaconData memory drawBeaconData = getDrawBeaconData(drawBeaconAddress);

            DrawData memory drawsData = getDrawsData(
                owner,
                drawBeaconData,
                prizeDistributorAddress,
                drawCalculatorTimeLockAddress
            );

            DrawCalculatorTimelockInterface drawCalculatorTimelock = DrawCalculatorTimelockInterface(
                drawCalculatorTimeLockAddress
            );

            prizePoolsData[i] = PrizePoolData(
                prizePool.getToken(),
                ticketData,
                prizePool.balance(),
                prizePool.getAccountedBalance(),
                prizePool.awardBalance(),
                prizePool.getLiquidityCap(),
                drawBeaconData,
                drawsData,
                drawCalculatorTimelock.getTimelock(),
                drawCalculatorTimelock.hasElapsed()
            );
        }
        return prizePoolsData;
    }
}

contract InstaPoolTogetherV4Resolver is Resolver {
    string public constant name = "PoolTogetherV4-Resolver-v1";
}
