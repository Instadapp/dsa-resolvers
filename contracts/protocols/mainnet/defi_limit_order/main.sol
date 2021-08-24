// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import { LimitOrderInterface, CTokenInterface, AaveProtocolDataProvider, AaveAddressProvider, AaveLendingPool, AavePriceOracle } from "./interfaces.sol";
import "./helpers.sol";

import { IERC20 } from "../../../utils/IERC20.sol";

abstract contract Resolver is Helpers {
    constructor(address _limitOrder) {
        Helpers(_limitOrder);
    }

    function getCreatePos(
        address _tokenFrom,
        address _tokenTo,
        uint128 _price
    ) public view returns (bytes8 _pos) {
        bytes32 _key = limitOrderContract.encodeTokenKey(_tokenFrom, _tokenTo);
        _pos = limitOrderContract.findCreatePos(_key, _price);
    }

    function checkUserPos(address _dsa, uint256 _route) public view returns (bool _isOk, uint256 _netPos) {
        (_isOk, _netPos) = limitOrderContract.checkUserPosition(_dsa, _route);
    }

    bytes8[] private _possStore;

    // Use this function as .call()
    function fetchInvalidPoss(address _tokenFrom, address _tokenTo) public returns (bytes8[] memory _poss) {
        delete _possStore;
        bytes32 _key = limitOrderContract.encodeTokenKey(_tokenFrom, _tokenTo);
        LimitOrderInterface.OrderLink memory _orderLink = limitOrderContract.ordersLinks(_key);
        bytes8 _key2 = _orderLink.first;
        for (uint256 i = 0; i < _orderLink.count; i++) {
            LimitOrderInterface.OrderList memory _order = limitOrderContract.ordersLists(_key, _key2);
            (bool _isOk, ) = checkUserPos(_order.dsa, _order.route);
            if (!_isOk) {
                _possStore.push(_key2);
            }
        }
        _poss = _possStore;
    }

    function fetchUserPos(
        address _dsa,
        bytes32 _key,
        uint256 _route
    ) public view returns (LimitOrderInterface.OrderList memory _order) {
        bytes8 _key2 = limitOrderContract.encodeDsaKey(_dsa, uint32(_route));
        _order = limitOrderContract.ordersLists(_key, _key2);
    }

    function getPositions(
        address _dsa,
        address[][] memory _tokenpairs,
        uint256[] memory _routes
    ) public view returns (LimitOrderInterface.OrderList[][] memory _orders) {
        // [_tokenpairs.length][_routes.length]
        for (uint256 i = 0; i < _tokenpairs.length; i++) {
            bytes32 _key = limitOrderContract.encodeTokenKey(_tokenpairs[i][0], _tokenpairs[i][1]);
            for (uint256 j = 0; j < _routes.length; j++) {
                _orders[i][j] = fetchUserPos(_dsa, _key, j);
            }
        }
    }

    function getSellSingle(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom
    ) public view returns (bytes8 _orderId, uint256 _amountTo) {
        bytes32 _key = limitOrderContract.encodeTokenKey(_tokenTo, _tokenFrom);
        LimitOrderInterface.OrderLink memory _orderLink = limitOrderContract.ordersLinks(_key);
        bytes8 _key2 = _orderLink.first;
        bool _isOk;
        uint256 _amountFrom18 = convertTo18(IERC20(_tokenFrom).decimals(), _amountFrom);
        // TODO: check if borrow/payback & deposit/withdraw is possible on Aave (C.F on Aave & L.L on Compound)
        while (!_isOk) {
            _orderId = _key2;
            if (_key2 == bytes8(0)) {
                _isOk = true;
                break;
            } else {
                (_isOk, _amountTo, _key2) = checkOrderForSell(
                    _key,
                    _orderId,
                    IERC20(_tokenTo).decimals(),
                    _amountFrom,
                    _amountFrom18
                );
            }
        }
    }
}

abstract contract InstaCompoundResolver is Resolver {
    string public constant name = "DeFi-Limit-Order-v1";

    constructor(address _limitOrder) {
        Resolver(_limitOrder);
    }
}
