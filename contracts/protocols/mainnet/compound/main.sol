// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    function getPriceInEth(CTokenInterface cToken) public view returns (uint priceInETH, uint priceInUSD) {
        uint decimals = getCETHAddress() == address(cToken) ? 18 : TokenInterface(cToken.underlying()).decimals();
        uint ethPrice = OrcaleComp(getOracleAddress()).price("ETH") * 1e12;
        uint price = address(cToken) == getCETHAddress() ? ethPrice : OrcaleComp(getOracleAddress()).getUnderlyingPrice(address(cToken));
        priceInUSD = price / 10 ** (18 - decimals);
        priceInETH = wdiv(priceInUSD, ethPrice);
    }

    function getCompoundData(address owner, address[] memory cAddress) public view returns (CompData[] memory) {
        CompData[] memory tokensData = new CompData[](cAddress.length);
        ComptrollerLensInterface troller = getComptroller();
        for (uint256 i = 0; i < cAddress.length; i++) {
            CTokenInterface cToken = CTokenInterface(cAddress[i]);
            (uint256 priceInETH, uint256 priceInUSD) = getPriceInEth(cToken);
            (, uint256 collateralFactor, bool isComped) = troller.markets(address(cToken));
            uint256 _totalBorrowed = cToken.totalBorrows();
            tokensData[i] = CompData(
                priceInETH,
                priceInUSD,
                cToken.exchangeRateStored(),
                cToken.balanceOf(owner),
                cToken.borrowBalanceStored(owner),
                _totalBorrowed,
                add(_totalBorrowed, cToken.getCash()),
                troller.borrowCaps(cAddress[i]),
                cToken.supplyRatePerBlock(),
                cToken.borrowRatePerBlock(),
                collateralFactor,
                troller.compSpeeds(cAddress[i]),
                troller.compSupplySpeeds(cAddress[i]),
                troller.compBorrowSpeeds(cAddress[i]),
                isComped,
                troller.borrowGuardianPaused(cAddress[i])
            );
        }

        return tokensData;
    }

    function getPosition(address owner, address[] memory cAddress)
        public
        returns (CompData[] memory, CompReadInterface.CompBalanceMetadataExt memory)
    {
        return (
            getCompoundData(owner, cAddress),
            CompReadInterface(getCompReadAddress()).getCompBalanceMetadataExt(getCompToken(), getComptroller(), owner)
        );
    }
}

contract InstaCompoundResolver is Resolver {
    string public constant name = "Compound-Resolver-v1.6";
}
