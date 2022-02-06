// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";


contract Helper {


function getMainnetoracle() public pure returns(Ofchain) {
        return Ofchain(0x07D91f5fb9Bf7798734C3f606dB065549F6893bb);
    }

function getMainnetMultiwrapper() public pure returns(Multiwrapper){
    return Multiwrapper(0x931e32B6D112F7BE74B16f7FBc77D491B30fe18c);
}

function getUsdcToken() public pure returns(IERC20){
    return IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}

}