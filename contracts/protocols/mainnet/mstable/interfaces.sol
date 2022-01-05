// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct UserData {
    uint128 rewardPerTokenPaid;
    uint128 rewards;
    uint64 lastAction;
    uint64 rewardCount;
}

struct Reward {
    uint64 start;
    uint64 finish;
    uint128 rate;
}

interface IMasset {
    function getMintOutput(address _input, uint256 _inputQuantity) external view returns (uint256 mintOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view returns (uint256 swapOutput);

    function getRedeemOutput(address _output, uint256 _mAssetQuantity) external view returns (uint256 bAssetOutput);

    function bAssetIndexes(address) external view returns (uint8);
}

interface ISavingsContractV2 {
    function exchangeRate() external view returns (uint256); // V1 & V2

    function balanceOfUnderlying(address _user) external view returns (uint256 balance); // V2

    function underlyingToCredits(uint256 _credits) external view returns (uint256 underlying); // V2

    function creditsToUnderlying(uint256 _underlying) external view returns (uint256 credits); // V2
}

interface IBoostedSavingsVault {
    /**
     * @dev Returned the units of IMMEDIATELY claimable rewards a user has to receive. Note - this
     * does NOT include the majority of rewards which will be locked up.
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(address _account) external view returns (uint256);

    /**
     * @dev Calculates all unclaimed reward data, finding both immediately unlocked rewards
     * and those that have passed their time lock.
     * @param _account User address
     * @return amount Total units of unclaimed rewards
     * @return first Index of the first userReward that has unlocked
     * @return last Index of the last userReward that has unlocked
     */
    function unclaimedRewards(address _account)
        external
        view
        returns (
            uint256 amount,
            uint256 first,
            uint256 last
        );

    function userData(address _account) external view returns (UserData memory);

    function userRewards(address _account, uint256 _i) external view returns (Reward memory);

    function rawBalanceOf(address _account) external view returns (uint256);

    function LOCKUP() external view returns (uint256);

    function UNLOCK() external view returns (uint64);

    function userClaim(address _account) external view returns (uint64);

    function periodFinish() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

interface IFeederPool {
    function getMintOutput(address _input, uint256 _inputQuantity) external view returns (uint256 mintOutput);

    function getMintMultiOutput(address[] calldata _inputs, uint256[] calldata _inputQuantities)
        external
        view
        returns (uint256 mintOutput);

    // Swaps
    function swap(
        address _input,
        address _output,
        uint256 _inputQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 swapOutput);

    function getSwapOutput(
        address _input,
        address _output,
        uint256 _inputQuantity
    ) external view returns (uint256 swapOutput);

    // Redemption
    function redeem(
        address _output,
        uint256 _fpTokenQuantity,
        uint256 _minOutputQuantity,
        address _recipient
    ) external returns (uint256 outputQuantity);

    function redeemProportionately(
        uint256 _fpTokenQuantity,
        uint256[] calldata _minOutputQuantities,
        address _recipient
    ) external returns (uint256[] memory outputQuantities);

    function redeemExactBassets(
        address[] calldata _outputs,
        uint256[] calldata _outputQuantities,
        uint256 _maxMassetQuantity,
        address _recipient
    ) external returns (uint256 mAssetRedeemed);

    function getRedeemOutput(address _output, uint256 _fpTokenQuantity) external view returns (uint256 bAssetOutput);

    function getRedeemExactBassetsOutput(address[] calldata _outputs, uint256[] calldata _outputQuantities)
        external
        view
        returns (uint256 mAssetAmount);

    // Views
    function mAsset() external view returns (address);

    function getPrice() external view returns (uint256 price, uint256 k);
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
