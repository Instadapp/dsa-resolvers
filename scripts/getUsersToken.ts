import { ethers, network } from "hardhat";
import { abi as StakerABI } from "../artifacts/contracts/protocols/mainnet/uniswapStaking/interfaces.sol/IUniswapV3Staker.json";
const stakerAddress = "0x1f98407aaB862CdDeF78Ed252D6f557aA5b0f00d";

export default async (user: any) => {
  const stakerContract = await ethers.getContractAt(StakerABI, stakerAddress);
  let filterToMe = stakerContract.filters.DepositTransferred(null, null, user);
  const queryFilterTo = await stakerContract.queryFilter(filterToMe, 0, "latest");

  let filterFromMe = stakerContract.filters.DepositTransferred(null, user);
  const queryFilterFrom = await stakerContract.queryFilter(filterFromMe, 0, "latest");

  let tokens: any = {};
  let tokenIds: any = [];
  for (let i = 0; i < queryFilterTo.length; i++) {
    const tokenId = queryFilterTo[i]?.args?.tokenId;
    if (tokens.hasOwnProperty(tokenId)) {
      tokens[tokenId] += 1;
    } else {
      tokens[tokenId] = 1;
    }
  }

  for (let i = 0; i < queryFilterFrom.length; i++) {
    const tokenId = queryFilterFrom[i]?.args?.tokenId;
    if (tokens.hasOwnProperty(tokenId)) {
      tokens[tokenId] -= 1;
    } else {
      tokens[tokenId] = 0;
    }
  }

  let keys = Object.keys(tokens);
  for (let i = 0; i < keys.length; i++) {
    if (tokens[keys[i]] > 0) {
      tokenIds.push(keys[i]);
    }
  }
  return tokenIds;
};
