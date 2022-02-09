// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces.sol";



contract Resolver {

_1inchOracleInterface AvalancheContract = _1inchOracleInterface(0xBd0c7AaF0bF082712EbE919a9dD94b2d978f79A9);
IERC20 dsttoken= IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);

function getRateInUsdc(IERC20[] memory srctokens,bool useWrapper) public view returns(uint256[] memory){

    uint256[] memory prices = new uint256[](srctokens.length);

   for(uint i=0;i<srctokens.length;i++){
        prices[i]=(AvalancheContract.getRate(srctokens[i],dsttoken,useWrapper));
    }
    return prices;

}

}
