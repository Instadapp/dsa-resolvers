// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interface.sol";
import { MarketParams, Market, IMorpho } from "./interfaces/IMorpho.sol";
import { IIrm } from "./interfaces/IIrm.sol";
import { IMetaMorpho } from "./interfaces/IMetaMorpho.sol";
import { MathLib } from "./libraries/MathLib.sol";
import { MorphoBalancesLib } from "./libraries/periphery/MorphoBalancesLib.sol";

contract MetamorphoResolver {
    using MathLib for uint256;
    using MorphoBalancesLib for IMorpho;

    address internal constant MORPHO_BLUE = 0xBBBBBbbBBb9cC5e90e3b3Af64bdAF62C37EEFFCb;

    struct VaultData {
        bool isToken;
        string name;
        string symbol;
        uint256 decimals;
        address asset;
        uint256 totalAssets;
        uint256 totalSupply;
        uint256 convertToShares;
        uint256 convertToAssets;
    }

    struct UserPosition {
        uint256 underlyingBalance;
        uint256 vaultBalance;
    }

    struct VaultPreview {
        uint256 previewDeposit;
        uint256 previewMint;
        uint256 previewWithdraw;
        uint256 previewRedeem;
        uint256 decimals;
        uint256 underlyingDecimals;
    }

    struct MetaMorphoDetails {
        uint256 totalCap;
        address loanToken;
        address collateralToken;
        uint256 lltv;
        uint256 fee;
        bool enabled; // Whether the market is in the withdraw queue
        uint256 apy;
        VaultData vaultData;
    }

    function getVaultDetails(address[] memory vaultAddresses) public view returns (VaultData[] memory) {
        VaultData[] memory _vaultData = new VaultData[](vaultAddresses.length);
        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);
            bool isToken = true;

            try vaultToken.symbol() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.name() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.decimals() {} catch {
                isToken = false;
                continue;
            }

            try vaultToken.asset() {} catch {
                isToken = false;
                continue;
            }

            TokenInterface _underlyingToken = TokenInterface(vaultToken.asset());

            _vaultData[i] = VaultData(
                isToken,
                vaultToken.name(),
                vaultToken.symbol(),
                vaultToken.decimals(),
                vaultToken.asset(),
                vaultToken.totalAssets(),
                vaultToken.totalSupply(),
                vaultToken.convertToShares(10 ** _underlyingToken.decimals()), // example convertToShares
                vaultToken.convertToAssets(10 ** vaultToken.decimals()) // example convertToAssets for 10 ** decimal
            );
        }

        return _vaultData;
    }

    function getPositions(address owner, address[] memory vaultAddress) public view returns (UserPosition[] memory) {
        UserPosition[] memory _userPosition = new UserPosition[](vaultAddress.length);
        for (uint256 i = 0; i < vaultAddress.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddress[i]);

            address _underlyingAddress = vaultToken.asset();
            TokenInterface underlyingToken = TokenInterface(_underlyingAddress);

            _userPosition[i].underlyingBalance = underlyingToken.balanceOf(owner);
            _userPosition[i].vaultBalance = vaultToken.balanceOf(owner);
        }

        return _userPosition;
    }

    function getAllowances(address owner, address[] memory vaultAddresses) public view returns (uint256[] memory) {
        uint256[] memory _tokenAllowance = new uint256[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);
            _tokenAllowance[i] = vaultToken.allowance(owner, vaultAddresses[i]);
        }

        return _tokenAllowance;
    }

    function getVaultPreview(
        uint256 amount,
        address[] memory vaultAddresses
    ) public view returns (VaultPreview[] memory) {
        VaultPreview[] memory _vaultPreview = new VaultPreview[](vaultAddresses.length);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            VaultInterface vaultToken = VaultInterface(vaultAddresses[i]);

            _vaultPreview[i].previewDeposit = vaultToken.previewDeposit(amount);
            _vaultPreview[i].previewMint = vaultToken.previewMint(amount);
            _vaultPreview[i].previewWithdraw = vaultToken.previewWithdraw(amount);
            _vaultPreview[i].previewRedeem = vaultToken.previewRedeem(amount);
            _vaultPreview[i].decimals = vaultToken.decimals();
            TokenInterface _underlyingToken = TokenInterface(vaultToken.asset());
            _vaultPreview[i].underlyingDecimals = _underlyingToken.decimals();
        }

        return _vaultPreview;
    }

    function getMetaMorphoDetails(address[] memory vaultAddresses) public view returns (MetaMorphoDetails[] memory) {
        MetaMorphoDetails[] memory _metaMorphotData = new MetaMorphoDetails[](vaultAddresses.length);

        VaultData[] memory _vaultDatas = getVaultDetails(vaultAddresses);

        for (uint256 i = 0; i < vaultAddresses.length; i++) {
            MetaMorphoInterface vaultToken = MetaMorphoInterface(vaultAddresses[i]);

            _metaMorphotData[i].apy = supplyAPYVault(vaultAddresses[i]);

            try vaultToken.fee() {} catch {
                continue;
            }

            try vaultToken.supplyQueue(0) {} catch {
                continue;
            }

            (
                _metaMorphotData[i].loanToken,
                _metaMorphotData[i].collateralToken,
                ,
                ,
                _metaMorphotData[i].lltv
            ) = MorphoBlueInterface(MORPHO_BLUE).idToMarketParams(vaultToken.supplyQueue(0));

            uint184 cap;
            (cap, _metaMorphotData[i].enabled, ) = vaultToken.config(vaultToken.supplyQueue(0));

            _metaMorphotData[i].totalCap = uint256(cap);

            _metaMorphotData[i].fee = vaultToken.fee();

            _metaMorphotData[i].vaultData = _vaultDatas[i];
        }

        return _metaMorphotData;
    }

    /// @notice Returns the current APY of the vault on a Morpho Blue market.
    /// @param marketParams The morpho blue market parameters.
    /// @param market The morpho blue market state.
    function supplyAPYMarket(MarketParams memory marketParams, Market memory market)
        public
        view
        returns (uint256 supplyRate)
    {
        // Get the borrow rate
        uint256 borrowRate;
        if (marketParams.irm == address(0)) {
            return 0;
        } else {
            borrowRate = IIrm(marketParams.irm).borrowRateView(marketParams, market).wTaylorCompounded(365 days);
        }

        (uint256 totalSupplyAssets,, uint256 totalBorrowAssets,) =
            IMorpho(MORPHO_BLUE).expectedMarketBalances(marketParams);

        // Get the supply rate
        uint256 utilization = totalBorrowAssets == 0 ? 0 : totalBorrowAssets.wDivUp(totalSupplyAssets);

        supplyRate = borrowRate.wMulDown(1 ether - market.fee).wMulDown(utilization);
    }

    /// @notice Returns the current APY of a MetaMorpho vault.
    /// @dev It is computed as the sum of all APY of enabled markets weighted by the supply on these markets.
    /// @param vault The address of the MetaMorpho vault.
    function supplyAPYVault(address vault) public view returns (uint256 avgSupplyRate) {
        uint256 ratio;
        uint256 queueLength = IMetaMorpho(vault).withdrawQueueLength();

        uint256 totalAmount = totalDepositVault(vault);

        for (uint256 i; i < queueLength; ++i) {
            Id idMarket = IMetaMorpho(vault).withdrawQueue(i);

            MarketParams memory marketParams = IMorpho(MORPHO_BLUE).idToMarketParams(idMarket);
            Market memory market = IMorpho(MORPHO_BLUE).market(idMarket);

            uint256 currentSupplyAPY = supplyAPYMarket(marketParams, market);
            uint256 vaultAsset = vaultAssetsInMarket(vault, marketParams);
            ratio += currentSupplyAPY.wMulDown(vaultAsset);
        }

        avgSupplyRate = ratio.wDivUp(totalAmount);
    }

    /// @notice Returns the total assets deposited into a MetaMorpho `vault`.
    /// @param vault The address of the MetaMorpho vault.
    function totalDepositVault(address vault) public view returns (uint256 totalAssets) {
        totalAssets = IMetaMorpho(vault).totalAssets();
    }

    /// @notice Returns the total assets supplied into a specific morpho blue market by a MetaMorpho `vault`.
    /// @param vault The address of the MetaMorpho vault.
    /// @param marketParams The morpho blue market.
    function vaultAssetsInMarket(address vault, MarketParams memory marketParams)
        public
        view
        returns (uint256 assets)
    {
        assets = IMorpho(MORPHO_BLUE).expectedSupplyAssets(marketParams, vault);
    }
}

contract InstaMetamorphoResolver is MetamorphoResolver {
    string public constant name = "Metamorpho-Resolver-v1.0";
}
