// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces.sol";



contract Resolver {

_1inchOracleInterface ArbitrumContract = _1inchOracleInterface(0x735247fb0a604c0adC6cab38ACE16D0DbA31295F);
IERC20 dsttoken= IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);

function getRateInUsdc(IERC20[] memory srctokens,bool useWrapper) public view returns(uint256[] memory){

    uint256[] memory prices = new uint256[](srctokens.length);

   for(uint i=0;i<srctokens.length;i++){
        prices[i]=(ArbitrumContract.getRate(srctokens[i],dsttoken,useWrapper));
    }
    return prices;

}

}
