pragma solidity 0.7.6;
pragma abicoder v2;

import { DSMath } from "../../../utils/dsmath.sol";
import "./contracts/libraries/TickMath.sol";
import "./contracts/libraries/FullMath.sol";
import "./contracts/libraries/FixedPoint128.sol";
import "./contracts/libraries/LiquidityAmounts.sol";
import "./contracts/libraries/PositionKey.sol";
import "./contracts/libraries/PoolAddress.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "./interfaces.sol";

abstract contract Helpers is DSMath {
    /**
     * @dev Return ethereum address
     */
    address internal constant ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /**
     * @dev Return Wrapped ETH address
     */
    address internal constant wethAddr = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    INonfungiblePositionManager internal nftManager = INonfungiblePositionManager(getUniswapNftManagerAddr());

    IUniswapV3Staker public staker = IUniswapV3Staker(0xe34139463bA50bD61336E0c446Bd8C0867c6fE65);

    /**
     * @dev Return uniswap v3 NFT Manager Address
     */
    function getUniswapNftManagerAddr() internal pure returns (address) {
        return 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    }

    function userNfts(address user) internal view returns (uint256[] memory tokenIds) {
        uint256 len = nftManager.balanceOf(user);
        tokenIds = new uint256[](len);
        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = nftManager.tokenOfOwnerByIndex(user, i);
            tokenIds[i] = tokenId;
        }
    }

    struct PositionInfo {
        address token0;
        address token1;
        address pool;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24 currentTick;
        uint128 liquidity;
        uint128 tokenOwed0;
        uint128 tokenOwed1;
        uint256 amount0;
        uint256 amount1;
        uint256 collectAmount0;
        uint256 collectAmount1;
    }

    function getIncentiveId(IUniswapV3Staker.IncentiveKey memory key) internal pure returns (bytes32 incentiveId) {
        return keccak256(abi.encode(key));
    }

    function positions(uint256 tokenId) internal view returns (PositionInfo memory pInfo) {
        (
            ,
            ,
            pInfo.token0,
            pInfo.token1,
            pInfo.fee,
            pInfo.tickLower,
            pInfo.tickUpper,
            pInfo.liquidity,
            ,
            ,
            ,

        ) = nftManager.positions(tokenId);
    }

    function getPoolAddress(uint256 _tokenId) public view returns (address pool) {
        (bool success, bytes memory data) = address(nftManager).staticcall(
            abi.encodeWithSelector(nftManager.positions.selector, _tokenId)
        );
        require(success, "fetching positions failed");
        {
            (, , address token0, address token1, uint24 fee, , , ) = abi.decode(
                data,
                (uint96, address, address, address, uint24, int24, int24, uint128)
            );

            pool = PoolAddress.computeAddress(
                nftManager.factory(),
                PoolAddress.PoolKey({ token0: token0, token1: token1, fee: fee })
            );
        }
    }
}
