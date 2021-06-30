pragma solidity 0.6.12;
// SPDX-License-Identifier: agpl-3.0

import {IP2PoolAddressesProvider} from "./IP2PoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

contract P2PoolStorage {
    IP2PoolAddressesProvider internal _addressesProvider;

    mapping(uint256 => DataTypes.IOUData) internal _ious;
    //The user's personal information
    mapping(address => DataTypes.UserData) internal _userDates;
    //The amount loaned by the user in IOU
    mapping(address => mapping(uint256 => uint256)) internal _userLoanInIOUs;

    // the list of the available reserves, structured as a mapping for gas savings reasons
    mapping(uint256 => address) internal _circlesAdmin;
    //IOU number
    uint256 internal _iousCount;
    //circle number
    uint256 _circlesCount;
    //Loan fee ratio, ten thousand ratio
    uint8 borrowFee;
    //The percentage of the handling fee given to the administrator
    uint8 circlesAdminProportion;
    //Maximum simultaneous borrowings
    uint8 maxIOUAmount = 1;
    uint256 _LatePeriod = 7 days;

    //If the overdue time is 1, the interest will be calculated with penalty interest 1 during this period, and the interest will be calculated with penalty interest 2 when the overdue time is exceeded
    uint256 interestPenalty1 = 1e26;
    uint256 interestPenalty2 = 15e25;

    address _wethAddress;
    bool internal _paused;
}
