// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title P2PoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the P2Proto Governance
 * @author P2Proto
 **/
interface IP2PoolAddressesProvider {
    event P2PoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event P2PoolConfiguratorUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);
    event P2ProtoTokenUpdated(address indexed newAddress);
    event TreasuryAddressUpdated(address indexed newAddress);
    event RewardsDistributionUpdated(address indexed newAddress);
    event OrderBookUpdated(address indexed newAddress);
    event SwapMinerUpdated(address indexed newAddress);

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getP2Pool() external view returns (address);

    function setP2PoolImpl(address pool, address weth) external;

    function getP2PoolConfigurator() external view returns (address);

    function setP2PoolConfiguratorImpl(address configurator) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getTreasuryAddress() external view returns (address);

    function setTreasuryAddress(address treasuryAddress) external;
}
