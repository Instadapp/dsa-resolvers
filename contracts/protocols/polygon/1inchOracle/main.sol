// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces.sol";



contract Resolver {

_1inchOracleInterface PolygonContract = _1inchOracleInterface(0x7F069df72b7A39bCE9806e3AfaF579E54D8CF2b9);
IERC20 dsttoken= IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);

function getRateInUsdc(IERC20[] memory srctokens,bool useWrapper) public view returns(uint256[] memory){

    uint256[] memory prices = new uint256[](srctokens.length);

   for(uint i=0;i<srctokens.length;i++){
        prices[i]=(PolygonContract.getRate(srctokens[i],dsttoken,useWrapper));
    }
    return prices;

}

}
