interface TokensObject {
  [key: string]: {
    addr: string;
    caddr: string;
    decimals: number;
  };
}

export const Tokens: TokensObject = {
  DAI: {
    addr: "0x6b175474e89094c44da98b954eedeac495271d0f",
    decimals: 18,
    caddr: "0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643",
  },
  USDC: {
    addr: "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
    decimals: 6,
    caddr: "0x39aa39c021dfbae8fac545936693ac917d5e7563",
  },
};
