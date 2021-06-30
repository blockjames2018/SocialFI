// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @title Errors library
 * @author P2Proto
 * @notice Defines the error messages emitted by the different contracts of the P2Proto protocol
 * @dev Error messages prefix glossary:
 *  - MATH = Math libraries
 *  - IOU = P2Pool
 *  - MPAPR = P2PoolAddressesProviderRegistry
 *  - MPC = P2PoolConfiguration
 *  - P = Pausable
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_CIRCLE_ADMIN = "1"; // 'The caller must be the circle admin'
    string public constant INVALID_ADDRESS = "2"; // 'The address must be legitimate'
    string public constant BANNED_ADDRESS = "3"; // 'The user is banned'
    string public constant AMOUNT_IS_0 = "61"; // 'The number cannot be 0'
    string public constant CALLER_NOT_POOL_ADMIN = "62"; // 'The caller must be admin'

    //contract specific errors
    string public constant CE_USER_HAS_BEEN_APPLIED = "4"; // 'The user has applied'
    string public constant CE_USER_HAS_NOT_APPLY = "5"; // 'The user hasn't apply'
    string public constant CE_USER_HAS_IOU = "6"; // 'The user has outstanding loans'
    string public constant CE_USER_NOT_IN_CIRCLE = "7"; // 'The user are not in this circle'
    string public constant IOU_TIME_ERROR = "8"; // 'Time is a problem.'
    string public constant IOU_TOO_MANY_IOUS = "9"; // 'Exceeding the maximum number of debit orders'
    string public constant IOU_NONACTIVATED_ERROR = "10"; // 'The loan is over'
    string public constant IOU_NEED_MORE_MONEY = "11"; // 'The amount is below the minimum limit'
    string public constant IOU_TOO_MORE_MONEY = "12"; // 'That's too much money'
    string public constant IOU_NOT_BORROWER = "13"; // 'It can only be received by the borrower'
    string public constant IOU_NO_LOAN = "14"; // 'No reserve is lent'
    string public constant IOU_NO_ENOUGH_ETH = "15"; // 'There is not enough ether to transfer'
    string public constant IOU_CALLER_NOT_CONFIGURATOR = "16"; // 'The caller of the function is not the pool configurator'
    string public constant MPC_CALLER_NOT_EMERGENCY_ADMIN = "18"; // 'The caller must be the emergency admin'
    string public constant MPAPR_PROVIDER_NOT_REGISTERED = "19"; // 'Provider is not registered'
    string public constant MPCM_NO_ERRORS = "20"; // 'No errors'
    string public constant MATH_MULTIPLICATION_OVERFLOW = "21";
    string public constant MATH_ADDITION_OVERFLOW = "22";
    string public constant MATH_DIVISION_BY_ZERO = "23";
    string public constant IOU_IS_PAUSED = "24"; // 'Pool is paused'
}
