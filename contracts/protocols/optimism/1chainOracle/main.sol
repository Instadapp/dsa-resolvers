// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces.sol";



contract Resolver {

_1inchOracleInterface OptimismContract = _1inchOracleInterface(0x11DEE30E710B8d4a8630392781Cc3c0046365d4c);
IERC20 dsttoken= IERC20(0x7F5c764cBc14f9669B88837ca1490cCa17c31607);

function getRateInUsdc(IERC20[] memory srctokens,bool useWrapper) public view returns(uint256[] memory){

    uint256[] memory prices = new uint256[](srctokens.length);

   for(uint i=0;i<srctokens.length;i++){
        prices[i]=(Optimism.getRate(srctokens[i],dsttoken,useWrapper));
    }
    return prices;

}
 
}
