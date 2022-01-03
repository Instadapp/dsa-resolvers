import { expect, use, assert } from "chai";
import { solidity } from "ethereum-waffle";
import chaiPromised from "chai-as-promised";
import { BigNumber as BN } from "ethers";

export const useChai = (): typeof expect => {
  use(solidity);
  use(chaiPromised);
  return expect;
};

export const DEFAULT_DECIMALS = 18;

export const simpleToExactAmount = (amount: number | string | BN, decimals: number | BN = DEFAULT_DECIMALS): BN => {
  let amountString = amount.toString();
  const decimalsBN = BN.from(decimals);

  if (decimalsBN.gt(100)) {
    throw new Error(`Invalid decimals amount`);
  }

  const scale = BN.from(10).pow(decimals);
  const scaleString = scale.toString();

  // Is it negative?
  const negative = amountString.substring(0, 1) === "-";
  if (negative) {
    amountString = amountString.substring(1);
  }

  if (amountString === ".") {
    throw new Error(`Error converting number ${amountString} to precise unit, invalid value`);
  }

  // Split it into a whole and fractional part
  // eslint-disable-next-line prefer-const
  let [whole, fraction, ...rest] = amountString.split(".");
  if (rest.length > 0) {
    throw new Error(`Error converting number ${amountString} to precise unit, too many decimal points`);
  }

  if (!whole) {
    whole = "0";
  }
  if (!fraction) {
    fraction = "0";
  }

  if (fraction.length > scaleString.length - 1) {
    throw new Error(`Error converting number ${amountString} to precise unit, too many decimal places`);
  }

  while (fraction.length < scaleString.length - 1) {
    fraction += "0";
  }

  const wholeBN = BN.from(whole);
  const fractionBN = BN.from(fraction);
  let result = wholeBN.mul(scale).add(fractionBN);

  if (negative) {
    result = result.mul("-1");
  }

  return result;
};

export const fullScale: BN = BN.from(10).pow(18);

export const assertBNClosePercent = (a: BN, b: BN, variance: string | number = "0.02", reason: string = ""): void => {
  if (a.eq(b)) return;
  const varianceBN = simpleToExactAmount(variance.toString().substr(0, 6), 16);
  const diff = a.sub(b).abs().mul(2).mul(fullScale).div(a.add(b));
  const str = reason ? `\n\tReason: ${reason}\n\t${a.toString()} vs ${b.toString()}` : "";
  assert.ok(
    diff.lte(varianceBN),
    `Numbers exceed ${variance}% diff (Delta between a and b is ${diff.toString()}%, but variance was only ${varianceBN.toString()})${str}`,
  );
};
