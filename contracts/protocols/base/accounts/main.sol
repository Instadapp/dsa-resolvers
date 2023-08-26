/**
 *Submitted for verification at polygonscan.com on 2021-06-30
 */

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces.sol";

contract Helpers {
    address public index;
    address public list;
    address public connectors;
    IndexInterface indexContract;
    ListInterface listContract;
    ConnectorsInterface connectorsContract;

    GnosisFactoryInterface[] public gnosisFactoryContracts;

    function getContractCode(address _addr) public view returns (bytes memory o_code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(_addr)
            // allocate output byte array - this could also be done without assembly
            // by using o_code = new bytes(size)
            o_code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(o_code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(o_code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(_addr, add(o_code, 0x20), 0, size)
        }
    }
}

contract AccountResolver is Helpers {
    function getID(address account) public view returns (uint256 id) {
        return listContract.accountID(account);
    }

    function getAccount(uint64 id) public view returns (address account) {
        return listContract.accountAddr(uint64(id));
    }

    function getAuthorityIDs(address authority) public view returns (uint64[] memory) {
        ListInterface.UserLink memory userLink = listContract.userLink(authority);
        uint64[] memory IDs = new uint64[](userLink.count);
        uint64 id = userLink.first;
        for (uint256 i = 0; i < userLink.count; i++) {
            IDs[i] = id;
            ListInterface.UserList memory userList = listContract.userList(authority, id);
            id = userList.next;
        }
        return IDs;
    }

    function getAuthorityAccounts(address authority) public view returns (address[] memory) {
        uint64[] memory IDs = getAuthorityIDs(authority);
        address[] memory accounts = new address[](IDs.length);
        for (uint256 i = 0; i < IDs.length; i++) {
            accounts[i] = getAccount(IDs[i]);
        }
        return accounts;
    }

    function getIDAuthorities(uint256 id) public view returns (address[] memory) {
        ListInterface.AccountLink memory accountLink = listContract.accountLink(uint64(id));
        address[] memory authorities = new address[](accountLink.count);
        address authority = accountLink.first;
        for (uint256 i = 0; i < accountLink.count; i++) {
            authorities[i] = authority;
            ListInterface.AccountList memory accountList = listContract.accountList(uint64(id), authority);
            authority = accountList.next;
        }
        return authorities;
    }

    function getAccountAuthorities(address account) public view returns (address[] memory) {
        return getIDAuthorities(getID(account));
    }

    function getAccountVersions(address[] memory accounts) public view returns (uint256[] memory) {
        uint256[] memory versions = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            versions[i] = AccountInterface(accounts[i]).version();
        }
        return versions;
    }

    struct AuthorityData {
        uint64[] IDs;
        address[] accounts;
        uint256[] versions;
    }

    struct AccountData {
        uint256 ID;
        address account;
        uint256 version;
        address[] authorities;
    }

    function getAuthorityDetails(address authority) public view returns (AuthorityData memory) {
        address[] memory accounts = getAuthorityAccounts(authority);
        return AuthorityData(getAuthorityIDs(authority), accounts, getAccountVersions(accounts));
    }

    function getAccountIdDetails(uint256 id) public view returns (AccountData memory) {
        address account = getAccount(uint64(id));
        return AccountData(id, account, AccountInterface(account).version(), getIDAuthorities(id));
    }

    function getAccountDetails(address account) public view returns (AccountData memory) {
        uint256 id = getID(account);
        return AccountData(id, account, AccountInterface(account).version(), getIDAuthorities(id));
    }

    function isShield(address account) public view returns (bool shield) {
        shield = AccountInterface(account).sheild();
    }

    struct AuthType {
        address owner;
        uint256 authType;
    }

    function getAuthorityTypes(address[] memory authorities) public view returns (AuthType[] memory) {
        AuthType[] memory types = new AuthType[](authorities.length);
        for (uint256 i = 0; i < authorities.length; i++) {
            bytes memory _contractCode = getContractCode(authorities[i]);
            bool isSafe;
            for (uint256 k = 0; k < gnosisFactoryContracts.length; k++) {
                bytes memory multiSigCode = gnosisFactoryContracts[k].proxyRuntimeCode();
                if (keccak256(abi.encode(multiSigCode)) == keccak256(abi.encode(_contractCode))) {
                    isSafe = true;
                }
            }
            if (isSafe) {
                types[i] = AuthType({ owner: authorities[i], authType: 1 });
            } else {
                types[i] = AuthType({ owner: authorities[i], authType: 0 });
            }
        }
        return types;
    }

    function getAccountAuthoritiesTypes(address account) public view returns (AuthType[] memory) {
        return getAuthorityTypes(getAccountAuthorities(account));
    }
}

contract ConnectorsResolver is AccountResolver {
    struct ConnectorsData {
        address connector;
        uint256 connectorID;
        string name;
    }

    function getEnabledConnectors() public view returns (address[] memory) {
        uint256 enabledCount = connectorsContract.connectorCount();
        address[] memory addresses = new address[](enabledCount);
        uint256 connectorArrayLength = connectorsContract.connectorLength();
        uint256 count;
        for (uint256 i = 0; i < connectorArrayLength; i++) {
            address connector = connectorsContract.connectorArray(i);
            if (connectorsContract.connectors(connector)) {
                addresses[count] = connector;
                count++;
            }
        }
        return addresses;
    }

    function getEnabledConnectorsData() public view returns (ConnectorsData[] memory) {
        uint256 enabledCount = connectorsContract.connectorCount();
        ConnectorsData[] memory connectorsData = new ConnectorsData[](enabledCount);
        uint256 connectorArrayLength = connectorsContract.connectorLength();
        uint256 count;
        for (uint256 i = 0; i < connectorArrayLength; i++) {
            address connector = connectorsContract.connectorArray(i);
            if (connectorsContract.connectors(connector)) {
                connectorsData[count] = ConnectorsData(connector, i + 1, ConnectorInterface(connector).name());
                count++;
            }
        }
        return connectorsData;
    }

    function getStaticConnectors() public view returns (address[] memory) {
        uint256 staticLength = connectorsContract.staticConnectorLength();
        address[] memory staticConnectorArray = new address[](staticLength);
        for (uint256 i = 0; i < staticLength; i++) {
            staticConnectorArray[i] = connectorsContract.staticConnectorArray(i);
        }
        return staticConnectorArray;
    }

    function getStaticConnectorsData() public view returns (ConnectorsData[] memory) {
        uint256 staticLength = connectorsContract.staticConnectorLength();
        ConnectorsData[] memory staticConnectorsData = new ConnectorsData[](staticLength);
        for (uint256 i = 0; i < staticLength; i++) {
            address staticConnector = connectorsContract.staticConnectorArray(i);
            staticConnectorsData[i] = ConnectorsData(
                staticConnector,
                i + 1,
                ConnectorInterface(staticConnector).name()
            );
        }
        return staticConnectorsData;
    }
}

contract InstaDSAResolverBase is ConnectorsResolver {
    string public constant name = "DSA-Resolver-v1";
    uint256 public constant version = 1;

    constructor(address _index) public {
        index = _index;
        indexContract = IndexInterface(index);
        list = indexContract.list();
        listContract = ListInterface(list);
        connectors = indexContract.connectors(version);
        connectorsContract = ConnectorsInterface(connectors);
    }
}
