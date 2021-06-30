// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IP2PoolAddressesProvider} from "./IP2PoolAddressesProvider.sol";
import {DataTypes} from "./DataTypes.sol";

interface IP2Pool {
    /**
     * @dev Emitted on createCircle()
     * @param user The admin of the circle
     * @param id The id of the circle
     * @param name The name of the circle, recorded only in the event
     * @param desc The description of the circle, recorded only in the event
     **/
    event CreateCircle(
        address indexed user,
        uint256 id,
        string name,
        string desc
    );

    /**
     * @dev Emitted on changeCircleAdmin()
     * @param id The id of the circle
     * @param admin The address of the administrator
     * @param newAdmin The address of the new administrator
     **/
    event SetCircleAdmin(uint256 indexed id, address admin, address newAdmin);

    /**
     * @dev Emitted on applyToJoinCircle()
     * @param id The id of the circle
     * @param user The address of applicant
     **/
    event ApplyToJoinCircle(uint256 indexed id, address indexed user);

    /**
     * @dev Emitted on manageApply()
     * @param id The id of the circle
     * @param user The address of applicant
     **/
    event ApprovalJoinCircle(uint256 indexed id, address indexed user);
    /**
     * @dev Emitted on manageApply()
     * @param id The id of the circle
     * @param user The address of applicant
     **/
    event RefusedJoinCircle(uint256 indexed id, address indexed user);

    /**
     * @dev Emitted on deleteUserFromCircle()
     * @param id The id of the circle
     * @param user The address of expellee
     **/
    event DeleteUserFromCircle(uint256 indexed id, address indexed user);

    /**
     * @dev Emitted on createIOU()
     * @param user The address of the borrower
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param borrowAmount The amount of borrowings
     **/
    event CreateIOU(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 borrowAmount
    );

    /**
     * @dev Emitted on supply()
     * @param user The address of the lender
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param amount The amount lent out
     **/
    event Supply(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 amount
    );

    /**
     * @dev Emitted on claim()
     * @param user The address of the borrower
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param amount The borrowings
     **/
    event Claim(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 amount
    );

    /**
     * @dev Emitted on repay()
     * @param user The address of the borrower
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param amount The amount of repaid
     **/
    event Repay(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 amount
    );

    /**
     * @dev Emitted on withdraw(),When the loan does not meet the conditions
     * @param user The address of the lender
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param amount The amount of funds to be withdrawn
     **/
    event Refund(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 amount
    );

    /**
     * @dev Emitted on withdraw(),When the loan has been repaid
     * @param user The address of the lender
     * @param iouId The id of the IOU
     * @param reserve The address of the borrow reserve
     * @param amount The amount of funds to be withdrawn
     **/
    event GetAward(
        address indexed user,
        uint256 indexed iouId,
        address indexed reserve,
        uint256 amount
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Set the bonus ratio for circle administrators
     * @param proportion The circle Admin's share of the bonus
     **/
    function setCirclesAdminProportion(uint8 proportion) external;

    /**
     * @dev Sets the number of debit orders an individual can issue
     * @param num The maximum
     **/
    function setMaxIOUAmount(uint8 num) external;

    /**
     * @dev Create a new circle
     * @param name The name of the circle, recorded only in the event
     * @param desc The description of the circle, recorded only in the event
     **/
    function createCircle(string memory name, string memory desc) external;

    /**
     * @dev Transfer the administrator status of the circle
     * @param id The id of the circle
     * @param user The address of the new administrator
     **/
    function changeCircleAdmin(uint256 id, address payable user) external;

    /**
     * @dev Users apply to join the circle
     * @param id The id of the circle
     **/
    function applyToJoinCircle(uint256 id) external;

    /**
     * @dev Users apply to join the circle
     * @param id The id of the circle
     * @param user The address of the _user
     * @param isApprove Whether approve or not
     **/
    function manageApply(
        uint256 id,
        address user,
        bool isApprove
    ) external;

    /**
     * @dev Remove the user from the circle
     * @param id The id of the circle
     * @param user The address of the _user
     **/
    function deleteUserFromCircle(uint256 id, address user) external;

    /**
     * @dev Create a debit order
     * @param iou The debit information
     **/
    function createIOU(DataTypes.IOUData memory iou) external;

    function setBorrowFee(uint8 fee) external;

    function setParams(
        uint256 latePeriod,
        uint256 penalty1,
        uint256 penalty2
    ) external;

    /**
     * @dev Lending money to iou
     * @param iouId The id of the iou
     * @param amount Amount of Loan
     **/
    function supply(uint256 iouId, uint256 amount) external payable;

    /**
     * @dev Borrower claims from the loan request(IOU)
     * @param iouId The id of the iou
     **/
    function claim(uint256 iouId) external;

    /**
     * @dev Borrower to repay the loan
     * @param iouId The id of the iou
     **/
    function repay(uint256 iouId) external payable;

    /**
     * @dev The lender to withdraw the loan.
     * @param iouId The id of the iou
     **/
    function withdraw(uint256 iouId) external;

    /**
     * @dev Returns the configuration of the IOU
     * @param id The id of the IOU
     * @return The configuration of the IOU
     **/
    function getIOUData(uint256 id)
        external
        view
        returns (DataTypes.IOUData memory);

    /**
     * @dev Returns the configuration of the IOU
     * @param id The id of the IOU
     * @return the amount to be repaid
     **/
    function getAmountOwed(uint256 id) external view returns (address, uint256);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserData(address user)
        external
        view
        returns (DataTypes.UserData memory);

    function setUserData(address user, DataTypes.UserData memory _data)
        external;

    function getAddressesProvider()
        external
        view
        returns (IP2PoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}
