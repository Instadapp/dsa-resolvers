// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ManagerLike {
    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);
}

interface BManagerLike is ManagerLike {
    function cushion(uint256) external view returns (uint256);
}

interface CdpsLike {
    function getCdpsAsc(address, address)
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            bytes32[] memory
        );
}

interface VatLike {
    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function gem(bytes32, address) external view returns (uint256);

    function debt() external view returns (uint256);

    function Line() external view returns (uint256);
}

interface JugLike {
    function ilks(bytes32) external view returns (uint256, uint256);

    function base() external view returns (uint256);
}

interface PotLike {
    function dsr() external view returns (uint256);

    function pie(address) external view returns (uint256);

    function chi() external view returns (uint256);
}

interface SpotLike {
    function ilks(bytes32) external view returns (PipLike, uint256);
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
}

interface InstaMcdAddress {
    function manager() external view returns (address);

    function vat() external view returns (address);

    function jug() external view returns (address);

    function spot() external view returns (address);

    function pot() external view returns (address);

    function getCdps() external view returns (address);
}
