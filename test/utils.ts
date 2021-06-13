import { expect, use } from "chai";
import { solidity } from "ethereum-waffle";
import chaiPromised from "chai-as-promised";

export const useChai = (): typeof expect => {
  use(solidity);
  use(chaiPromised);
  return expect;
};
