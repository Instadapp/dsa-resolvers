// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { LimitOrderInterface, CTokenInterface, AaveProtocolDataProvider } from "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract Helpers is DSMath {
    LimitOrderInterface public constant limitOrderContract = LimitOrderInterface(address(0)); // TODO: Add address
    AaveProtocolDataProvider aaveData = AaveProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);

    function convert18ToDec(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = (_amt / 10**(18 - _dec));
    }

    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }

    // route = 1
    function checkUserWithdrawCompound(
        address _dsa,
        address _tokenTo,
        uint256 _toAmount
    ) private view returns (bool, uint256) {
        CTokenInterface _ctoken = limitOrderContract.tokenToCtoken(_tokenTo);
        uint256 _ctokenBal = _ctoken.balanceOf(_dsa);
        uint256 _ctokenExchangeRate = _ctoken.exchangeRateStored();
        uint256 _maxToAmount = div(mul(_ctokenBal, _ctokenExchangeRate), 10**18);
        return (_toAmount < _maxToAmount, _maxToAmount);
    }

    // route = 2
    function checkUserPaybackCompound(
        address _dsa,
        address _tokenFrom,
        uint256 _fromAmount
    ) private view returns (bool, uint256) {
        CTokenInterface _ctoken = limitOrderContract.tokenToCtoken(_tokenFrom);
        uint256 _borrowBal = _ctoken.borrowBalanceStored(_dsa);
        return (_fromAmount < _borrowBal, _borrowBal);
    }

    // route = 3
    function checkUserWithdrawAave(
        address _dsa,
        address _tokenTo,
        uint256 _toAmount
    ) private view returns (bool, uint256) {
        (uint256 _supplyBal, , , , , , , , ) = aaveData.getUserReserveData(_tokenTo, _dsa);
        // TODO: Check the ratio as LL & CF of DAI & USDC are different
        return (_toAmount < _supplyBal, _supplyBal);
    }

    // route = 4
    function checkUserPaybackAave(
        address _dsa,
        address _tokenFrom,
        uint256 _fromAmount
    ) private view returns (bool, uint256) {
        (, , uint256 _borrowBal, , , , , , ) = aaveData.getUserReserveData(_tokenFrom, _dsa);
        // TODO: Check if user can borrow as the position should be under C.F
        return (_fromAmount < _borrowBal, _borrowBal);
    }

    function checkOrderForSell(
        bytes32 _key,
        bytes8 _key2,
        uint256 _tokenToDec,
        uint256 _amountFrom,
        uint256 _amountFrom18
    )
        public
        view
        returns (
            bool _isOk,
            uint256 _amountTo,
            bytes8 _next
        )
    {
        LimitOrderInterface.OrderList memory _order = limitOrderContract.ordersLists(_key, _key2);
        uint256 _amountTo18 = wdiv(_amountFrom18, _order.price);
        _amountTo = convert18ToDec(_tokenToDec, _amountTo18);
        _next = _order.next;
        if (_order.route == 1) {
            (_isOk, ) = checkUserWithdrawCompound(_order.dsa, _order.tokenTo, _amountTo);
        } else if (_order.route == 2) {
            (_isOk, ) = checkUserPaybackCompound(_order.dsa, _order.tokenFrom, _amountFrom);
        } else if (_order.route == 3) {
            (_isOk, ) = checkUserWithdrawAave(_order.dsa, _order.tokenTo, _amountTo);
        } else if (_order.route == 4) {
            (_isOk, ) = checkUserPaybackAave(_order.dsa, _order.tokenFrom, _amountFrom);
        } else {
            return (false, 0, bytes8(0));
        }
    }
}
