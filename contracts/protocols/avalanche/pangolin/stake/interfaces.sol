// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
pragma abicoder v2;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStakingRewards {
    // Storage
    function rewards(address account) external view returns (uint256);

    // View
    function balanceOf(address account) external view returns (uint256);

    function rewardsToken() external view returns (address);

    function totalSupply() external view returns (uint256);
}

interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    // Storage
    function addedTokens(address token) external view returns (bool);

    function lpToken(uint256 _pid) external view returns (IERC20);

    function userInfo(uint256 _pid, address _user) external view returns (UserInfo memory);

    // View
    function pendingReward(uint256 _pid, address _user) external view returns (uint256);

    function poolLength() external view returns (uint256);
}
