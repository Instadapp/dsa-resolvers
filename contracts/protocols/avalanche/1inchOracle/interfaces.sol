// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface _1inchOracleInterface {

   function getRate(IERC20 , IERC20 , bool) external view returns(uint256) ;

}

