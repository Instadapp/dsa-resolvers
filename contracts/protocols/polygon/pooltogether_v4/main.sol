// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
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

    function getDrawsData(
        address owner,
        TicketInterface ticket,
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
        DrawBufferInterface drawBuffer = drawCalculatorTimelock.getDrawCalculator().getDrawBuffer();

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

            DrawData memory drawsData = getDrawsData(
                owner,
                ticket,
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
                drawsData,
                drawCalculatorTimelock.getTimelock(),
                drawCalculatorTimelock.hasElapsed()
            );
        }
        return prizePoolsData;
    }
}

contract InstaPoolTogetherV4PolygonResolver is Resolver {
    string public constant name = "PoolTogetherV4-Resolver-v1";
}
