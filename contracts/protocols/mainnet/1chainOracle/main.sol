// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces.sol";



contract Resolver {

_1inchOracleInterface MainnetContract = _1inchOracleInterface(0x07D91f5fb9Bf7798734C3f606dB065549F6893bb);
IERC20 dsttoken= IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

function getRateInUsdc(IERC20[] memory srctokens,bool useWrapper) public view returns(uint256[] memory){
    
    uint256[] memory prices = new uint256[](srctokens.length);
   
   for(uint i=0;i<srctokens.length;i++){
        prices[i]=(MainnetContract.getRate(srctokens[i],dsttoken,useWrapper));
    }
    return prices;

} 

}