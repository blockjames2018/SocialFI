// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";
import {VersionedInitializable} from "./VersionedInitializable.sol";
import {InitializableImmutableAdminUpgradeabilityProxy} from "./InitializableImmutableAdminUpgradeabilityProxy.sol";
import {IP2PoolAddressesProvider} from "./IP2PoolAddressesProvider.sol";
import {IP2Pool} from "./IP2Pool.sol";
import {Errors} from "./Errors.sol";
import {PercentageMath} from "./PercentageMath.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title P2PoolConfigurator contract
 * @author P2Proto
 * @dev Implements the configuration methods for the P2Proto protocol
 **/

contract P2PoolConfigurator is VersionedInitializable {
    using SafeMath for uint256;
    using PercentageMath for uint256;

    /**
     * @dev Emitted when a user be blacklisted
     * @param user The address be blacklisted
     **/
    event AddBlackList(address indexed user);

    /**
     * @dev Emitted when a user be removed from the blacklist
     * @param user The address be removed from the blacklist
     **/
    event RemoveBlackList(address indexed user);
    /**
     * @dev Emitted when adjust the administrator bonus proportion
     * @param proportion bonus proportion
     **/
    event AdminProportionChanged(uint8 proportion);
    /**
     * @dev Emitted when adjust the maximum number of IOUs
     * @param num the maximum number of IOUs
     **/
    event SetMaxIOUAmount(uint8 num);

    event BorrowFeeChanged(uint256 fee);

    event SetParams(uint256 param1, uint256 param2, uint256 param3);

    IP2PoolAddressesProvider public addressesProvider;
    IP2Pool public pool;

    modifier onlyPoolAdmin {
        require(
            addressesProvider.getPoolAdmin() == msg.sender,
            Errors.CALLER_NOT_POOL_ADMIN
        );
        _;
    }

    modifier onlyEmergencyAdmin {
        require(
            addressesProvider.getEmergencyAdmin() == msg.sender,
            Errors.MPC_CALLER_NOT_EMERGENCY_ADMIN
        );
        _;
    }

    uint256 internal constant CONFIGURATOR_REVISION = 0x2;

    function getRevision() internal pure override returns (uint256) {
        return CONFIGURATOR_REVISION;
    }

    function initialize(IP2PoolAddressesProvider provider) public initializer {
        addressesProvider = provider;
        pool = IP2Pool(addressesProvider.getP2Pool());
    }

    /**
     * @dev Freezes a user. A frozen user doesn't allow any new borrow
     *  but allows repayments
     * @param user The address of the user
     **/
    function addBlackList(address user) external onlyPoolAdmin {
        DataTypes.UserData memory userData = pool.getUserData(user);

        userData.isInBlacklist = true;

        pool.setUserData(user, userData);

        emit AddBlackList(user);
    }

    /**
     * @dev Unfreezes a user
     * @param user The address of the user
     **/
    function removeBlackList(address user) external onlyPoolAdmin {
        DataTypes.UserData memory userData = pool.getUserData(user);

        userData.isInBlacklist = false;

        pool.setUserData(user, userData);

        emit RemoveBlackList(user);
    }

    function setBorrowFee(uint8 fee) external onlyPoolAdmin {
        pool.setBorrowFee(fee);
        emit BorrowFeeChanged(fee);
    }

    function setCirclesAdminProportion(uint8 proportion)
        external
        onlyPoolAdmin
    {
        pool.setCirclesAdminProportion(proportion);
        emit AdminProportionChanged(proportion);
    }

    function setMaxIOUAmount(uint8 num) external onlyPoolAdmin {
        pool.setMaxIOUAmount(num);
        emit SetMaxIOUAmount(num);
    }

    function setParams(
        uint256 param1,
        uint256 param2,
        uint256 param3
    ) external onlyPoolAdmin {
        pool.setParams(param1, param2, param3);
        emit SetParams(param1, param2, param3);
    }

    /**
     * @dev pauses or unpauses all the actions of the protocol
     * @param val true if protocol needs to be paused, false otherwise
     **/
    function setPoolPause(bool val) external onlyPoolAdmin {
        pool.setPause(val);
    }
}
