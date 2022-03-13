pragma solidity >=0.8.0;
// SPDX-License-Identifier: MIT
pragma abicoder v2;

import { Helpers } from "./helpers.sol";

/**
 * @title LimitOrderResolver.
 * @dev Resolver for Limit Order Swap on Uni V3.
 */
contract LimitOrderResolver is Helpers {
    function fetchNFTsOfContract(address contr_, uint256 count_) public view returns (uint256[] memory tokenIDs_) {
        for (uint256 i = 0; i < count_; i++) {
            tokenIDs_[i] = nftManager.tokenOfOwnerByIndex(contr_, i);
        }
    }

    function nftsToClose(uint256[] memory tokenIds_) public view returns (bool[] memory result_) {
        for (uint256 i = 0; i < tokenIds_.length; i++) {
            if (limitCon_.nftToOwner(tokenIds_[i]) != address(0)) {
                (address token0_, address token1_, uint24 fee_, int24 tickLower_, int24 tickUpper_) = getPositionInfo(
                    tokenIds_[i]
                );

                int24 currentTick_ = getCurrentTick(token0_, token1_, fee_);

                if (limitCon_.token0to1(tokenIds_[i]) && currentTick_ > tickUpper_) {
                    result_[i] = true;
                }
                if ((!limitCon_.token0to1(tokenIds_[i])) && currentTick_ < tickLower_) {
                    result_[i] = true;
                }
            }
        }
    }
}
