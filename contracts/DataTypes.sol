// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DataTypes {
    struct IOUData {
        address borrower;
        //tokens addresses
        address reserve;
        //The total amount to be borrowed
        uint256 needAmount;
        //Minimum amount borrowed. If not reached, the loan will be cancelled
        uint256 minStartAmount;
        //Minimum amount lent per person
        uint256 minInvestmentAmount;
        //The amount borrowed, and the amount repaid
        uint256 debtAmount;
        //the current borrow rate. Expressed in ray
        uint128 BorrowRate;
        uint128 circleId;
        //loan will not be accepted after the starting time
        uint40 startTime;
        uint40 endTime;
        uint40 lastUpdateTimestamp;
        //0active,1canceled,2received,3repaid,4overdue
        uint8 status;
    }

    struct UserData {
        //The number of loans in progress, exceeding the maximum, cannot create a new loan
        uint256 activeIOUAmount;
        //Whether or not to be blacklisted, the blacklist cannot create a loan.
        bool isInBlacklist;
    }
}
