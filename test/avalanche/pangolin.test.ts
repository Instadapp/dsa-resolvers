import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers, network, config } from "hardhat";
import { expect } from "chai";
import { InstaPangolinResolver, InstaPangolinResolver__factory } from "../../typechain";
import { BigNumber } from "ethers";
describe("Pangolin", async () => {
    let signer: SignerWithAddress;

    before(async () => {
        [signer] = await ethers.getSigners();
    });

    describe("Pangolin Resolver", async () => {
        let pangolin: InstaPangolinResolver;
        before(async () => {
            const pangolinresolver = <InstaPangolinResolver__factory>await ethers.getContractFactory("InstaPangolinResolver");
            pangolin = await pangolinresolver.deploy();
            await pangolin.deployed();
        });

        it("deploys the resolver", () => {
            expect(pangolin.address).to.exist;
            if(!!pangolin.address){
                console.log("Resolver address: "+pangolin.address)
            }
        });

        it("Returns buy amount", async () => {
            const [
                buyAmt,
                unitAmt,
            ] = await pangolin.getBuyAmount(
                "0x60781C2586D68229fde47564546784ab3fACA982", 
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                ethers.utils.parseEther("10"),
                BigNumber.from("3"),
            )
            console.log("--- Returns buy amount ---")
            console.log("buyAmt: "+ buyAmt.toString())
            console.log("unitAmt: "+ unitAmt.toString())
        });

        it("Returns sell amount", async () => {
            const [
                sellAmt,
                unitAmt,
            ] = await pangolin.getSellAmount(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                "0x60781C2586D68229fde47564546784ab3fACA982", 
                ethers.utils.parseEther("10"),
                BigNumber.from("3"),
            )
            console.log("--- Returns sell amount ---")
            console.log("sellAmt: "+ sellAmt.toString())
            console.log("unitAmt: "+ unitAmt.toString())
        });

        it("Returns deposit amount", async () => {
            const [
                amountB,
                uniAmount,
                amountAMin,
                amountBMin
            ] = await pangolin.getDepositAmount(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                "0x60781C2586D68229fde47564546784ab3fACA982", 
                ethers.utils.parseEther("10"),
                BigNumber.from("3"),
                BigNumber.from("3"),
            )
            console.log("--- Returns deposit amount ---")
            console.log("amountB: "+ amountB.toString())
            console.log("uniAmount: "+ uniAmount.toString())
            console.log("amountAMin: "+ amountAMin.toString())
            console.log("amountBMin: "+ amountBMin.toString())
        });

        it("Returns single deposit amount", async () => {
            const [
                amtA,
                amtB,
                uniAmt,
                minUniAmt
            ] = await pangolin.getSingleDepositAmount(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                "0x60781C2586D68229fde47564546784ab3fACA982", 
                ethers.utils.parseEther("10"),
                BigNumber.from("3"),
            )
            console.log("--- Returns single deposit amount ---")
            console.log("amtA: "+ amtA.toString())
            console.log("amtB: "+ amtB.toString())
            console.log("uniAmt: "+ uniAmt.toString())
            console.log("minUniAmt: "+ minUniAmt.toString())
        });

        it("Returns deposit amount in new pool", async () => {
            const unitAmt = await pangolin.getDepositAmountNewPool(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                "0x97b99B4009041e948337ebCA7e6ae52f9f6e633c", 
                ethers.utils.parseEther("10"),
                ethers.utils.parseEther("10"),
            )
            console.log("--- Returns deposit amount in new pool ---")
            console.log("unitAmt: "+ unitAmt.toString())
        });

        it("Returns withdraw amounts", async () => {
            const [
                amtA,
                amtB,
                unitAmtA,
                unitAmtB
            ] = await pangolin.getWithdrawAmounts(
                "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", 
                "0x60781C2586D68229fde47564546784ab3fACA982", 
                ethers.utils.parseEther("10"),
                BigNumber.from("3"),
            )
            console.log("--- Returns withdraw amounts ---")
            console.log("amtA: "+ amtA.toString())
            console.log("amtB: "+ amtB.toString())
            console.log("unitAmtA: "+ unitAmtA.toString())
            console.log("unitAmtB: "+ unitAmtB.toString())
        });

        it("Returns the getPositionByPair", async () => {
            const [
                position1
            ] = await pangolin.getPositionByPair(
                signer.address,
                [
                    {tokenA: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE", tokenB: "0x60781C2586D68229fde47564546784ab3fACA982"}
                ]
            )
            const [
                tokenA,
                tokenB,
                lpAddress,
                reserveA,
                reserveB,
                tokenAShareAmt,
                tokenBShareAmt,
                tokenABalance,
                tokenBBalance,
                lpAmount,
                totalSupply,
            ] = position1
            console.log("--- Returns the getPositionByPair ---")
            console.log("tokenA: "+ tokenA.toString())
            console.log("tokenB: "+ tokenB.toString())
            console.log("lpAddress: "+ lpAddress.toString())
            console.log("reserveA: "+ reserveA.toString())
            console.log("reserveB: "+ reserveB.toString())
            console.log("tokenAShareAmt: "+ tokenAShareAmt.toString())
            console.log("tokenBShareAmt: "+ tokenBShareAmt.toString())
            console.log("tokenABalance: "+ tokenABalance.toString())
            console.log("tokenBBalance: "+ tokenBBalance.toString())
            console.log("lpAmount: "+ lpAmount.toString())
            console.log("totalSupply: "+ totalSupply.toString())
        });

        it("Returns the getpooldata", async () => {
            const [
                tokenA,
                tokenB,
                lpAddress,
                reserveA,
                reserveB,
                tokenAShareAmt,
                tokenBShareAmt,
                tokenABalance,
                tokenBBalance,
                lpAmount,
                totalSupply,
            ] = await pangolin.getpooldata(
                "0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367",
                signer.address,
            )
            console.log("--- Returns the getpooldata ---")
            console.log("tokenA: "+ tokenA.toString())
            console.log("tokenB: "+ tokenB.toString())
            console.log("lpAddress: "+ lpAddress.toString())
            console.log("reserveA: "+ reserveA.toString())
            console.log("reserveB: "+ reserveB.toString())
            console.log("tokenAShareAmt: "+ tokenAShareAmt.toString())
            console.log("tokenBShareAmt: "+ tokenBShareAmt.toString())
            console.log("tokenABalance: "+ tokenABalance.toString())
            console.log("tokenBBalance: "+ tokenBBalance.toString())
            console.log("lpAmount: "+ lpAmount.toString())
            console.log("unitAmtotalSupplytB: "+ totalSupply.toString())
        });

        it("Returns the getPosition", async () => {
            const [
                position1,

            ] = await pangolin.getPosition(
                signer.address,
                ["0xd7538cABBf8605BdE1f4901B47B8D42c61DE0367"],
            )
            const [
                tokenA,
                tokenB,
                lpAddress,
                reserveA,
                reserveB,
                tokenAShareAmt,
                tokenBShareAmt,
                tokenABalance,
                tokenBBalance,
                lpAmount,
                totalSupply,
            ] = position1
            console.log("--- Returns the getPosition ---")
            console.log("tokenA: "+ tokenA.toString())
            console.log("tokenB: "+ tokenB.toString())
            console.log("lpAddress: "+ lpAddress.toString())
            console.log("reserveA: "+ reserveA.toString())
            console.log("reserveB: "+ reserveB.toString())
            console.log("tokenAShareAmt: "+ tokenAShareAmt.toString())
            console.log("tokenBShareAmt: "+ tokenBShareAmt.toString())
            console.log("tokenABalance: "+ tokenABalance.toString())
            console.log("tokenBBalance: "+ tokenBBalance.toString())
            console.log("lpAmount: "+ lpAmount.toString())
            console.log("unitAmtotalSupplytB: "+ totalSupply.toString())
        });

    });
});