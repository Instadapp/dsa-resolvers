require("@nomiclabs/hardhat-waffle");
const { getContractFactory } = require("@nomiclabs/hardhat-ethers/types");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Limit Resolver contract", function () {
  let user = "0x8fD3F608603E081b3c78a1BAE8197376dcE6dD2b";
  let contr_ = "0x94F401fAD3ebb89fB7380f5fF6E875A88E6Af916";
  let Resolve;
  let tokenIDs_;

  it("should deploy the resolver", async function () {
    const resolverFactory = await hre.ethers.getContractFactory("LimitOrderResolver");
    Resolve = await resolverFactory.deploy();
    await Resolve.deployed();
    console.log("Resolver address: ", Resolve.address);
  });

  it("Should getNFTs", async function () {
    tokenIDs_ = await Resolve.getNFTs(contr_);
    console.log("getNFTs: ", tokenIDs_.toString());
  });

  it("Should get nftsToClose", async function () {
    let result_ = await Resolve.nftsToClose([71244]);
    console.log("nftsToClose: ", result_);
  });

  it("Should return some owner contract", async function () {
    const { tokenIDs_, idsBool_ } = await Resolve.nftsUser(user);
    console.log("tokenIDs_: ", tokenIDs_.toString(), " idsBool_: ", idsBool_);
  });
});
