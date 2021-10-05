// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getTokenFaucetData(address owner, address tokenFaucetAddress) public returns (TokenFaucetData memory) {
        TokenFaucetInterface tokenFaucet = TokenFaucetInterface(tokenFaucetAddress);

        (uint128 lastExchangeRateMantissa, uint128 balance) = tokenFaucet.userStates(owner);

        TokenFaucetData memory tokenFaucetData = TokenFaucetData(
            tokenFaucet.asset(),
            tokenFaucet.dripRatePerSecond(),
            tokenFaucet.exchangeRateMantissa(),
            tokenFaucet.totalUnclaimed(),
            tokenFaucet.lastDripTimestamp(),
            lastExchangeRateMantissa,
            balance,
            tokenFaucet.claim(owner)
        );

        return tokenFaucetData;
    }

    function getPrizeStrategyData(address prizeStrategyAddress) public view returns (PrizeStrategyData memory) {
        PrizeStrategyInterface prizeStrategy = PrizeStrategyInterface(prizeStrategyAddress);

        PrizeStrategyData memory prizeStrategyData = PrizeStrategyData(
            address(prizeStrategy),
            prizeStrategy.prizePeriodRemainingSeconds(),
            prizeStrategy.isPrizePeriodOver(),
            prizeStrategy.prizePeriodEndAt(),
            prizeStrategy.getExternalErc20Awards(),
            prizeStrategy.getExternalErc721Awards(),
            prizeStrategy.tokenListener()
        );

        return prizeStrategyData;
    }

    function getPosition(address owner, address[] memory prizePoolAddress) public returns (PrizePoolData[] memory) {
        PrizePoolData[] memory prizePoolsData = new PrizePoolData[](prizePoolAddress.length);
        for (uint256 i = 0; i < prizePoolAddress.length; i++) {
            PrizePoolInterface prizePool = PrizePoolInterface(prizePoolAddress[i]);
            TokenInterface[] memory controlledTokens = prizePool.tokens();
            ControlledTokenData[] memory controlledTokenData = new ControlledTokenData[](controlledTokens.length);

            for (uint256 j = 0; j < controlledTokens.length; j++) {
                (uint128 creditLimitMantissa, uint128 creditRateMantissa) = prizePool.creditPlanOf(
                    address(controlledTokens[j])
                );
                controlledTokenData[j] = ControlledTokenData(
                    address(controlledTokens[j]),
                    controlledTokens[j].balanceOf(owner),
                    controlledTokens[j].name(),
                    controlledTokens[j].symbol(),
                    controlledTokens[j].decimals(),
                    creditLimitMantissa,
                    creditRateMantissa
                );
            }
            PrizeStrategyData memory prizeStrategyData = getPrizeStrategyData(prizePool.prizeStrategy());
            prizePoolsData[i] = PrizePoolData(
                prizePool.token(),
                controlledTokens,
                prizePool.balance(),
                prizePool.accountedBalance(),
                controlledTokenData,
                prizePool.captureAwardBalance(),
                prizePool.maxExitFeeMantissa(),
                prizePool.reserveTotalSupply(),
                prizePool.liquidityCap(),
                prizeStrategyData
            );
        }
        return prizePoolsData;
    }
}

contract InstaPoolTogetherResolver is Resolver {
    string public constant name = "PoolTogether-Resolver-v1";
}
