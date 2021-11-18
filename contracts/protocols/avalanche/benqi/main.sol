// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is Helpers {
    // reward token type to show BENQI or AVAX
    uint8 public constant rewardQi = 0;
    uint8 public constant rewardAvax = 1;

    function getPriceInAvax(QiTokenInterface qiToken) public view returns (uint256 priceInAVAX, uint256 priceInUSD) {
        uint256 decimals = getQiAVAXAddress() == address(qiToken)
            ? 18
            : TokenInterface(qiToken.underlying()).decimals();
        uint256 price = OrcaleQi(getOracleAddress()).getUnderlyingPrice(address(qiToken));
        uint256 avaxPrice = OrcaleQi(getOracleAddress()).getUnderlyingPrice(getQiAVAXAddress());
        priceInUSD = price / 10**(18 - decimals);
        priceInAVAX = wdiv(priceInUSD, avaxPrice);
    }

    function getBenqiData(address owner, address[] memory qiAddress) public view returns (BenqiData[] memory) {
        BenqiData[] memory tokensData = new BenqiData[](qiAddress.length);
        ComptrollerLensInterface troller = getComptroller();
        for (uint256 i = 0; i < qiAddress.length; i++) {
            QiTokenInterface qiToken = QiTokenInterface(qiAddress[i]);
            (uint256 priceInAVAX, uint256 priceInUSD) = getPriceInAvax(qiToken);
            (, uint256 collateralFactor, bool isQied) = troller.markets(address(qiToken));
            uint256 _totalBorrowed = qiToken.totalBorrows();
            tokensData[i] = BenqiData(
                priceInAVAX,
                priceInUSD,
                qiToken.exchangeRateStored(),
                qiToken.balanceOf(owner),
                qiToken.borrowBalanceStored(owner),
                _totalBorrowed,
                sub(add(_totalBorrowed, qiToken.getCash()), qiToken.totalReserves()),
                troller.borrowCaps(qiAddress[i]),
                qiToken.supplyRatePerTimestamp(),
                qiToken.borrowRatePerTimestamp(),
                collateralFactor,
                troller.rewardSpeeds(rewardQi, qiAddress[i]),
                troller.rewardSpeeds(rewardAvax, qiAddress[i]),
                isQied,
                troller.borrowGuardianPaused(qiAddress[i])
            );
        }

        return tokensData;
    }

    function getRewardsData(
        address owner,
        ComptrollerLensInterface comptroller,
        TokenInterface qiToken
    ) public view returns (MetadataExt memory) {
        return
            MetadataExt(
                comptroller.rewardAccrued(rewardQi, owner),
                comptroller.rewardAccrued(rewardAvax, owner),
                qiToken.delegates(owner),
                qiToken.getCurrentVotes(owner)
            );
    }

    function getPosition(address owner, address[] memory qiAddress)
        public
        view
        returns (BenqiData[] memory, MetadataExt memory)
    {
        return (getBenqiData(owner, qiAddress), getRewardsData(owner, getComptroller(), getQiToken()));
    }
}

contract InstaBenqiResolver is Resolver {
    string public constant name = "Benqi-Resolver-v1";
}
