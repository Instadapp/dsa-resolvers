import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

export interface Signers {
  instaMaster: SignerWithAddress;
  extras: SignerWithAddress[];
}
