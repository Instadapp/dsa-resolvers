pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface AccountInterface {
    function isAuth(address user) external view returns (bool);

    function sheild() external view returns (bool);

    function version() external view returns (uint256);
}

interface ListInterface {
    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    function accounts() external view returns (uint256);

    function accountID(address) external view returns (uint64);

    function accountAddr(uint64) external view returns (address);

    function userLink(address) external view returns (UserLink memory);

    function userList(address, uint64) external view returns (UserList memory);

    function accountLink(uint64) external view returns (AccountLink memory);

    function accountList(uint64, address) external view returns (AccountList memory);
}

interface IndexInterface {
    function master() external view returns (address);

    function list() external view returns (address);

    function connectors(uint256) external view returns (address);

    function account(uint256) external view returns (address);

    function check(uint256) external view returns (address);

    function versionCount() external view returns (uint256);
}

interface ConnectorsInterface {
    struct List {
        address prev;
        address next;
    }

    function chief(address) external view returns (bool);

    function connectors(address) external view returns (bool);

    function staticConnectors(address) external view returns (bool);

    function connectorArray(uint256) external view returns (address);

    function connectorLength() external view returns (uint256);

    function staticConnectorArray(uint256) external view returns (address);

    function staticConnectorLength() external view returns (uint256);

    function connectorCount() external view returns (uint256);

    function isConnector(address[] calldata _connectors) external view returns (bool isOk);

    function isStaticConnector(address[] calldata _connectors) external view returns (bool isOk);
}

interface ConnectorInterface {
    function name() external view returns (string memory);
}

interface GnosisFactoryInterface {
    function proxyRuntimeCode() external pure returns (bytes memory);
}
