// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { TokenInterface } from "./interfaces.sol";
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
        TokenInterface[] tokens; // An array of the Tokens controlled by the Prize Pool (ie. Tickets, Sponsorship)
        uint256 balance; // The total underlying balance of all assets. This includes both principal and interest.
        uint256 accountedBalance; // The total of all controlled tokens
        ControlledTokenData[] tokenData;
        uint256 awardBalance; // The balance that is available to award.
        uint256 maxExitFeeMantissa; // The maximum possible exit fee fraction as a fixed point 18 number.
        uint256 reserveTotalSupply; // The total funds that have been allocated to the reserve
        uint256 liquidityCap; // The total amount of funds that the prize pool can hold.
        PrizeStrategyData prizeStategyData;
    }

    struct PrizeStrategyData {
        address addr;
        uint256 prizePeriodRemainingSeconds;
        bool isPrizePeriodOver;
        uint256 prizePeriodEndAt;
        address[] getExternalErc20Awards;
        address[] getExternalErc721Awards;
        address tokenListener;
    }

    struct TokenData {
        uint256 balance;
        string name;
        string symbol;
        uint256 decimals;
    }

    struct ControlledTokenData {
        address addr;
        uint256 balanceOf; // User Balance
        string name;
        string symbol;
        uint256 decimals;
        uint128 creditLimitMantissa; // Credit limit fraction used to calculate both the credit limit and early exit fee
        uint128 creditRateMantissa; // The credit rate. This is the amount of tokens that accrue per second.
    }

    struct TokenFaucetData {
        address asset; // The token that is being disbursed
        uint256 dripRatePerSecond; // The total number of tokens that are disbursed each second
        uint112 exchangeRateMantissa; // The cumulative exchange rate of measure token supply : dripped tokens
        uint112 totalUnclaimed; // The total amount of tokens that have been dripped but not claimed
        uint32 lastDripTimestamp; // The timestamp at which the tokens were last dripped
        uint128 lastExchangeRateMantissa;
        uint128 balance;
        uint256 ownerBalance;
    }

    struct PodData {
        string name;
        string symbol;
        uint8 decimals;
        address prizePool; // The Pod PrizePool reference
        uint256 pricePerShare; // Calculate the cost of the Pod's token price per share. Until a Pod has won it's 1.
        uint256 balance; // Measure's the Pod's total balance by adding the vaultTokenBalance and _podTicketBalance
        uint256 balanceOf; // User balance
        uint256 balanceOfUnderlying; // Calculate the underlying assets relative to users balance.
        uint256 totalSupply;
        address tokenDrop;
        address faucet;
    }

    struct TokenDrop {
        address asset; // The token that is being disbursed
        address measure; // The token that is used to measure a user's portion of disbursed tokens
        uint112 exchangeRateMantissa; // The cumulative exchange rate of measure token supply : dripped tokens
        uint112 totalUnclaimed; // The total amount of tokens that have been dripped but not claimed
        uint32 lastDripTimestamp; // The timestamp at which the tokens were last dripped
        uint128 lastExchangeRateMantissa;
        uint128 balance;
    }
}
