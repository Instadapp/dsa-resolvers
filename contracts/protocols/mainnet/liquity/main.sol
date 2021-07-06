// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function fetchETHPrice() public returns (uint256) {
        return priceFeedOracle.fetchPrice();
    }

    function getTrove(address owner) public returns (Trove memory) {
        uint256 oracleEthPrice = fetchETHPrice();
        (uint256 debt, uint256 collateral, , ) = troveManager.getEntireDebtAndColl(owner);
        uint256 icr = troveManager.getCurrentICR(owner, oracleEthPrice);
        return Trove(collateral, debt, icr);
    }

    function getStabilityDeposit(address owner) public view returns (StabilityDeposit memory) {
        uint256 deposit = stabilityPool.getCompoundedLUSDDeposit(owner);
        uint256 ethGain = stabilityPool.getDepositorETHGain(owner);
        uint256 lqtyGain = stabilityPool.getDepositorLQTYGain(owner);
        return StabilityDeposit(deposit, ethGain, lqtyGain);
    }

    function getStake(address owner) public view returns (Stake memory) {
        uint256 amount = staking.stakes(owner);
        uint256 ethGain = staking.getPendingETHGain(owner);
        uint256 lusdGain = staking.getPendingLUSDGain(owner);
        return Stake(amount, ethGain, lusdGain);
    }

    function getPosition(address owner) external returns (Position memory) {
        Trove memory trove = getTrove(owner);
        StabilityDeposit memory stability = getStabilityDeposit(owner);
        Stake memory stake = getStake(owner);
        return Position(trove, stability, stake);
    }

    function getSystemState() external returns (System memory) {
        uint256 oracleEthPrice = fetchETHPrice();
        uint256 borrowFee = troveManager.getBorrowingRateWithDecay();
        uint256 ethTvl = add(activePool.getETH(), defaultPool.getETH());
        uint256 tcr = troveManager.getTCR(oracleEthPrice);
        bool isInRecoveryMode = troveManager.checkRecoveryMode(oracleEthPrice);
        return System(borrowFee, ethTvl, tcr, isInRecoveryMode);
    }

    function getTrovePositionHints(
        uint256 collateral,
        uint256 debt,
        uint256 searchIterations,
        uint256 randomSeed
    ) external view returns (address upperHint, address lowerHint) {
        // See: https://github.com/liquity/dev#supplying-hints-to-trove-operations
        uint256 nominalCr = hintHelpers.computeNominalCR(collateral, debt);
        searchIterations = searchIterations == 0 ? mul(10, sqrt(sortedTroves.getSize())) : searchIterations;
        randomSeed = randomSeed == 0 ? block.number : randomSeed;
        (address hintAddress, , ) = hintHelpers.getApproxHint(nominalCr, searchIterations, randomSeed);
        return sortedTroves.findInsertPosition(nominalCr, hintAddress, hintAddress);
    }

    function getRedemptionPositionHints(
        uint256 amount,
        uint256 searchIterations,
        uint256 randomSeed
    )
        external
        returns (
            uint256 partialHintNicr,
            address firstHint,
            address upperHint,
            address lowerHint
        )
    {
        uint256 oracleEthPrice = fetchETHPrice();
        // See: https://github.com/liquity/dev#hints-for-redeemcollateral
        (firstHint, partialHintNicr, ) = hintHelpers.getRedemptionHints(amount, oracleEthPrice, 0);
        searchIterations = searchIterations == 0 ? mul(10, sqrt(sortedTroves.getSize())) : searchIterations;
        randomSeed = randomSeed == 0 ? block.number : randomSeed;
        (address hintAddress, , ) = hintHelpers.getApproxHint(partialHintNicr, searchIterations, randomSeed);
        (upperHint, lowerHint) = sortedTroves.findInsertPosition(partialHintNicr, hintAddress, hintAddress);
    }
}

contract InstaLiquityResolver is Resolver {
    string public constant name = "Liquity-Resolver-v1";
}
