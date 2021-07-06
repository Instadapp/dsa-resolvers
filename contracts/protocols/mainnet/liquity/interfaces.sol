// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface PriceFeedOracle {
    function fetchPrice() external returns (uint256);
}

interface TroveManagerLike {
    function getBorrowingRateWithDecay() external view returns (uint256);

    function getTCR(uint256 _price) external view returns (uint256);

    function getCurrentICR(address _borrower, uint256 _price) external view returns (uint256);

    function checkRecoveryMode(uint256 _price) external view returns (bool);

    function getEntireDebtAndColl(address _borrower)
        external
        view
        returns (
            uint256 debt,
            uint256 coll,
            uint256 pendingLUSDDebtReward,
            uint256 pendingETHReward
        );
}

interface StabilityPoolLike {
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint256);

    function getDepositorETHGain(address _depositor) external view returns (uint256);

    function getDepositorLQTYGain(address _depositor) external view returns (uint256);
}

interface StakingLike {
    function stakes(address owner) external view returns (uint256);

    function getPendingETHGain(address _user) external view returns (uint256);

    function getPendingLUSDGain(address _user) external view returns (uint256);
}

interface PoolLike {
    function getETH() external view returns (uint256);
}

interface HintHelpersLike {
    function computeNominalCR(uint256 _coll, uint256 _debt) external pure returns (uint256);

    function computeCR(
        uint256 _coll,
        uint256 _debt,
        uint256 _price
    ) external pure returns (uint256);

    function getApproxHint(
        uint256 _CR,
        uint256 _numTrials,
        uint256 _inputRandomSeed
    )
        external
        view
        returns (
            address hintAddress,
            uint256 diff,
            uint256 latestRandomSeed
        );

    function getRedemptionHints(
        uint256 _LUSDamount,
        uint256 _price,
        uint256 _maxIterations
    )
        external
        view
        returns (
            address firstHint,
            uint256 partialRedemptionHintNICR,
            uint256 truncatedLUSDamount
        );
}

interface SortedTrovesLike {
    function getSize() external view returns (uint256);

    function findInsertPosition(
        uint256 _ICR,
        address _prevId,
        address _nextId
    ) external view returns (address, address);
}
