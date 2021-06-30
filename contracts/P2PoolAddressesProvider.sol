// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Ownable} from "./Ownable.sol";
import "./Address.sol";

// Prettier ignore to prevent buidler flatter bug
// prettier-ignore
import {InitializableImmutableAdminUpgradeabilityProxy} from './InitializableImmutableAdminUpgradeabilityProxy.sol';

import {IP2PoolAddressesProvider} from "./IP2PoolAddressesProvider.sol";

// import './BaseUpgradeabilityProxy.sol';
/**
 * @title P2PoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the P2Proto Governance
 * @author P2Proto
 **/
contract P2PoolAddressesProvider is Ownable, IP2PoolAddressesProvider {
    mapping(bytes32 => address) private _addresses;

    bytes32 private constant P2P_POOL = "P2P_POOL";
    bytes32 private constant P2P_POOL_CONFIGURATOR = "P2P_POOL_CONFIGURATOR";
    bytes32 private constant POOL_ADMIN = "POOL_ADMIN";
    bytes32 private constant EMERGENCY_ADMIN = "EMERGENCY_ADMIN";
    bytes32 private constant TREASURY_ADDRESS = "TREASURY_ADDRESS";

    constructor() public {}

    /**
     * @dev General function to update the implementation of a proxy registered with
     * certain `id`. If there is no proxy registered, it will instantiate one and
     * set as implementation the `implementationAddress`
     * IMPORTANT Use this function carefully, only for ids that don't have an explicit
     * setter function, in order to avoid unexpected consequences
     * @param id The id
     * @param implementationAddress The address of the new implementation
     */
    function setAddressAsProxy(bytes32 id, address implementationAddress)
        external
        override
        onlyOwner
    {
        _updateImpl(id, implementationAddress);
        emit AddressSet(id, implementationAddress, true);
    }

    /**
     * @dev Sets an address for an id replacing the address saved in the addresses map
     * IMPORTANT Use this function carefully, as it will do a hard replacement
     * @param id The id
     * @param newAddress The address to set
     */
    function setAddress(bytes32 id, address newAddress)
        external
        override
        onlyOwner
    {
        _addresses[id] = newAddress;
        emit AddressSet(id, newAddress, false);
    }

    /**
     * @dev Returns an address by id
     * @return The address
     */
    function getAddress(bytes32 id) public view override returns (address) {
        return _addresses[id];
    }

    /**
     * @dev Returns the address of the P2Pool proxy
     * @return The P2Pool proxy address
     **/
    function getP2Pool() external view override returns (address) {
        return getAddress(P2P_POOL);
    }

    /**
     * @dev Updates the implementation of the P2Pool, or creates the proxy
     * setting the new `pool` implementation on the first time calling it
     * @param pool The new P2Pool implementation
     **/
    function setP2PoolImpl(address pool, address _weth)
        external
        override
        onlyOwner
    {
        _updatePoolImpl(P2P_POOL, pool, _weth);
        emit P2PoolUpdated(pool);
    }

    /**
     * @dev Returns the address of the P2PoolConfigurator proxy
     * @return The P2PoolConfigurator proxy address
     **/
    function getP2PoolConfigurator() external view override returns (address) {
        return getAddress(P2P_POOL_CONFIGURATOR);
    }

    /**
     * @dev Updates the implementation of the P2PoolConfigurator, or creates the proxy
     * setting the new `configurator` implementation on the first time calling it
     * @param configurator The new P2PoolConfigurator implementation
     **/
    function setP2PoolConfiguratorImpl(address configurator)
        external
        override
        onlyOwner
    {
        _updateImpl(P2P_POOL_CONFIGURATOR, configurator);
        emit P2PoolConfiguratorUpdated(configurator);
    }

    /**
     * @dev The functions below are getters/setters of addresses that are outside the context
     * of the protocol hence the upgradable proxy pattern is not used
     **/

    function getPoolAdmin() external view override returns (address) {
        return getAddress(POOL_ADMIN);
    }

    function setPoolAdmin(address admin) external override onlyOwner {
        _addresses[POOL_ADMIN] = admin;
        emit ConfigurationAdminUpdated(admin);
    }

    function getEmergencyAdmin() external view override returns (address) {
        return getAddress(EMERGENCY_ADMIN);
    }

    function setEmergencyAdmin(address emergencyAdmin)
        external
        override
        onlyOwner
    {
        _addresses[EMERGENCY_ADMIN] = emergencyAdmin;
        emit EmergencyAdminUpdated(emergencyAdmin);
    }

    function getTreasuryAddress() external view override returns (address) {
        return getAddress(TREASURY_ADDRESS);
    }

    function setTreasuryAddress(address treasuryAddress)
        external
        override
        onlyOwner
    {
        _addresses[TREASURY_ADDRESS] = treasuryAddress;
        emit TreasuryAddressUpdated(treasuryAddress);
    }

    /**
     * @dev Internal function to update the implementation of a specific proxied component of the protocol
     * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
     *   as implementation and calls the initialize() function on the proxy
     * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     **/
    function _updateImpl(bytes32 id, address newAddress) internal {
        address payable proxyAddress = payable(_addresses[id]);


            InitializableImmutableAdminUpgradeabilityProxy proxy
         = InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature(
            "initialize(address)",
            address(this)
        );

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            proxy.initialize(newAddress, params);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    /**
     * @dev Internal function to update the implementation of a specific proxied component of the protocol
     * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
     *   as implementation and calls the initialize() function on the proxy
     * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     **/
    function _updateImpl(
        bytes32 id,
        address newAddress,
        address UniswapRouter,
        address _weth
    ) internal {
        address payable proxyAddress = payable(_addresses[id]);


            InitializableImmutableAdminUpgradeabilityProxy proxy
         = InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature(
            "initialize(address,address,address)",
            address(this),
            UniswapRouter,
            _weth
        );

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            proxy.initialize(newAddress, params);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeToAndCall(newAddress, params);
        }
    }

    /**
     * @dev Internal function to update the implementation of a specific proxied component of the protocol
     * - If there is no proxy registered in the given `id`, it creates the proxy setting `newAdress`
     *   as implementation and calls the initialize() function on the proxy
     * - If there is already a proxy registered, it just updates the implementation to `newAddress` and
     *   calls the initialize() function via upgradeToAndCall() in the proxy
     * @param id The id of the proxy to be updated
     * @param newAddress The address of the new implementation
     **/
    function _updatePoolImpl(
        bytes32 id,
        address newAddress,
        address _weth
    ) internal {
        address payable proxyAddress = payable(_addresses[id]);


            InitializableImmutableAdminUpgradeabilityProxy proxy
         = InitializableImmutableAdminUpgradeabilityProxy(proxyAddress);
        bytes memory params = abi.encodeWithSignature(
            "initialize(address,address)",
            address(this),
            _weth
        );

        if (proxyAddress == address(0)) {
            proxy = new InitializableImmutableAdminUpgradeabilityProxy(
                address(this)
            );
            proxy.initialize(newAddress, params);
            _addresses[id] = address(proxy);
            emit ProxyCreated(id, address(proxy));
        } else {
            proxy.upgradeToAndCall(newAddress, params);
        }
    }
}
