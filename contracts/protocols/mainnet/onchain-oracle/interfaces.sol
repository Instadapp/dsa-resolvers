// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

 enum OracleType { WETH, ETH, WETH_ETH }

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWrapper {
    function wrap(IERC20 token) external view returns (IERC20 wrappedToken, uint256 rate);
}

interface IOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 rate, uint256 weight);
}




interface Ofchain {



    function getRate(IERC20 , IERC20 , bool) external view returns(uint256) ;



     function connectors() external view returns (IERC20[] memory);

    function oracles() external view returns (IOracle[] memory , OracleType[] memory);

}

interface Multiwrapper{

    function wrappers() external view returns (IWrapper[] memory);

    function getWrappedTokens(IERC20) external view returns (IERC20[] memory , uint256[] memory);


}
