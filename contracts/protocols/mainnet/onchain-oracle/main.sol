// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./interfaces.sol";
import "./helper.sol";


contract Resolver is Helper {
uint256 ans;
IERC20[] list;


function getRateInUsdc(IERC20[] memory srctokens) public view returns(uint256[] memory){
    uint256[] memory prices = new uint256[](srctokens.length);
    Ofchain token  = getMainnetoracle();
    IERC20 dsttoken = getUsdcToken();
    for(uint i=0;i<srctokens.length;i++){
        prices[i]=(token.getRate(srctokens[i],dsttoken,false));
    }
    return prices;

}

function getConnectors(Ofchain token) public view returns(IERC20[] memory) {

    return token.connectors();

}



function getWrappedTokens(IERC20 wtoken,bool useWrapper) public view returns(IERC20[] memory){

    Multiwrapper token = getMainnetMultiwrapper();

    (IERC20[] memory wrappedTokens , uint256[] memory rates) =  token.getWrappedTokens(wtoken);

    return wrappedTokens;
}


function oracles() public view returns(IOracle[] memory allOracles) {

    Ofchain token  = getMainnetoracle();

    (allOracles,)=token.oracles();

    return (allOracles);

}}
