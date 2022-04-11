pragma solidity ^0.7.6;
// SPDX-License-Identifier: MIT
pragma abicoder v2;

import { Helpers } from "./helpers.sol";

/**
 * @title LimitOrderResolver.
 * @dev Resolver for Limit Order Swap on Uni V3.
 */
contract LimitOrderResolver is Helpers {
    /**
     * @dev Returns all the NFTs
     * @notice Get all the NFTs using nftManager
     * @param contr_ All the tokenIds in the contract
     */
    function getNFTs(address contr_) public view returns (uint256[] memory tokenIDs_) {
        uint256 count_ = nftManager.balanceOf(contr_);

        tokenIDs_ = new uint256[](count_);

        for (uint256 i = 0; i < count_; i++) {
            tokenIDs_[i] = nftManager.tokenOfOwnerByIndex(contr_, i);
        }
    }

    /**
     * @dev Get NFTs to close.
     * @notice If bool = true, close the tokenId
     * @param tokenIds_ All the tokenIds in the contract
     */
    function nftsToClose(uint256[] memory tokenIds_) public view returns (bool[] memory result_) {
        uint256 arrLen_ = tokenIds_.length;
        result_ = new bool[](arrLen_);

        for (uint128 i = 0; i < arrLen_; i++) {
            (address token0_, address token1_, uint24 fee_, int24 tickLower_, int24 tickUpper_) = getPositionInfo(
                tokenIds_[i]
            );

            int24 currentTick_ = getCurrentTick(token0_, token1_, fee_);

            if (limitCon_.nftToOwner(tokenIds_[i]) != address(0)) {
                if (limitCon_.token0To1(tokenIds_[i]) && currentTick_ > tickUpper_) {
                    result_[i] = true; //Close NFT
                } else if ((!limitCon_.token0To1(tokenIds_[i])) && currentTick_ < tickLower_) {
                    result_[i] = true; //Close NFT
                } else {
                    result_[i] = false;
                }
            } else {
                result_[i] = false;
            }
        }
    }

    /**
     * @dev Get open and closed NFTs.
     * @notice Returns "True" if ID is open, "false" if ID is closed
     * @param user_ The address of the user
     */
    function nftsUser(address user_) public view returns (uint256[] memory tokenIDs_, bool[] memory idsBool_) {
        tokenIDs_ = limitCon_.returnArray(user_);
        uint256 arrLen_ = tokenIDs_.length;
        idsBool_ = new bool[](arrLen_);

        for (uint128 i = 0; i < arrLen_; i++) {
            if (limitCon_.nftToOwner(tokenIDs_[i]) != address(0)) {
                idsBool_[i] = true; //user ID open
            } else {
                idsBool_[i] = false; //user ID closed
            }
        }
    }
}
