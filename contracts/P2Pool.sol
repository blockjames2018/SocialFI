// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from "./SafeMath.sol";
import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {Address} from "./Address.sol";
import {IP2PoolAddressesProvider} from "./IP2PoolAddressesProvider.sol";
import {IP2Pool} from "./IP2Pool.sol";
import {VersionedInitializable} from "./VersionedInitializable.sol";
import {Errors} from "./Errors.sol";
import {WadRayMath} from "./WadRayMath.sol";
import {PercentageMath} from "./PercentageMath.sol";
import {DataTypes} from "./DataTypes.sol";
import {P2PoolStorage} from "./P2PoolStorage.sol";

/**
 * @title P2Pool contract
 * @dev Main point of interaction with an p2p protocol's market
 * - Users can:
 *   # CreateCiecle
 *   # changeCircleAdmin
 *   # applyToJoinCircle
 *   # manageApply
 *   # deleteUserFromCircle
 *   # createIOU
 *   # supply
 *   # claim
 *   # repay
 *   # withdraw
 * - To be covered by a proxy contract, owned by the P2PoolAddressesProvider of the specific market
 * - All admin functions are callable by the P2PoolConfigurator contract defined also in the
 *   P2PoolAddressesProvider
 * @author P2Proto
 **/
contract P2Pool is VersionedInitializable, IP2Pool, P2PoolStorage {
    using SafeMath for uint256;
    using WadRayMath for uint256;
    using PercentageMath for uint256;
    using SafeERC20 for IERC20;

    //main configuration parameters
    uint256 public constant P2POOL_REVISION = 0x1;
    mapping(address => mapping(uint256 => ApplyState)) internal _userInCircles;

    enum ApplyState {
        none,
        applying,
        refused,
        Approval
    }

    modifier whenNotPaused() {
        _whenNotPaused();
        _;
    }

    modifier onlyP2PoolConfigurator() {
        _onlyP2PoolConfigurator();
        _;
    }

    modifier onlyCircleAdmin(uint256 _id) {
        _onlyCircleAdmin(_id);
        _;
    }

    modifier onlyLegalAddress(address _user) {
        _onlyLegalAddress(_user);
        _;
    }

    function _whenNotPaused() internal view {
        require(!_paused, Errors.IOU_IS_PAUSED);
    }

    function _onlyP2PoolConfigurator() internal view {
        require(
            _addressesProvider.getP2PoolConfigurator() == msg.sender,
            Errors.IOU_CALLER_NOT_CONFIGURATOR
        );
    }

    function _onlyCircleAdmin(uint256 _id) internal view {
        require(
            _circlesAdmin[_id] == msg.sender,
            Errors.CALLER_NOT_CIRCLE_ADMIN
        );
    }

    function _onlyLegalAddress(address _user) internal view {
        DataTypes.UserData storage userData = _userDates[_user];
        require(!userData.isInBlacklist, Errors.BANNED_ADDRESS);
    }

    function getRevision() internal pure override returns (uint256) {
        return P2POOL_REVISION;
    }

    /**
     * @dev Function is invoked by the proxy contract when the P2Pool contract is added to the
     * P2PoolAddressesProvider of the market.
     * - Caching the address of the P2PoolAddressesProvider in order to reduce gas consumption
     *   on subsequent operations
     * @param provider The address of the P2PoolAddressesProvider
     * @param wethAddress The address of the weth
     **/
    function initialize(IP2PoolAddressesProvider provider, address wethAddress)
        public
        initializer
    {
        _addressesProvider = provider;
        _wethAddress = wethAddress;
    }

    function setBorrowFee(uint8 _fee) external override onlyP2PoolConfigurator {
        require(_fee <= 100, "fee can't be more than 1%");
        borrowFee = _fee;
    }

    function setCirclesAdminProportion(uint8 proportion)
        external
        override
        onlyP2PoolConfigurator
    {
        require(proportion <= 100, "Admin proportion can't be more than 100%");
        circlesAdminProportion = proportion;
    }

    function setMaxIOUAmount(uint8 num)
        external
        override
        onlyP2PoolConfigurator
    {
        maxIOUAmount = num;
    }

    /**
     * @dev Create a new circle
     * @param name The name of the circle, recorded only in the event
     * @param desc The description of the circle, recorded only in the event
     **/
    function createCircle(string memory name, string memory desc)
        external
        override
        whenNotPaused
        onlyLegalAddress(msg.sender)
    {
        _circlesAdmin[_circlesCount] = msg.sender;
        _userInCircles[msg.sender][_circlesCount] = ApplyState.Approval;
        emit CreateCircle(msg.sender, _circlesCount, name, desc);
        _circlesCount += 1;
    }

    /**
     * @dev Transfer the administrator status of the circle
     * @param id The id of the circle
     * @param user The address of the new administrator
     **/
    function changeCircleAdmin(uint256 id, address payable user)
        external
        override
        whenNotPaused
        onlyCircleAdmin(id)
        onlyLegalAddress(msg.sender)
        onlyLegalAddress(user)
    {
        require(user != address(0), Errors.INVALID_ADDRESS);
        _circlesAdmin[id] = user;
        emit SetCircleAdmin(id, msg.sender, user);
    }

    /**
     * @dev Users apply to join the circle
     * @param id The id of the circle
     **/
    function applyToJoinCircle(uint256 id)
        external
        override
        whenNotPaused
        onlyLegalAddress(msg.sender)
    {
        ApplyState applyState = _userInCircles[msg.sender][id];
        require(applyState == ApplyState.none, Errors.CE_USER_HAS_BEEN_APPLIED);
        _userInCircles[msg.sender][id] = ApplyState.applying;
        emit ApplyToJoinCircle(id, msg.sender);
    }

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
    )
        external
        override
        whenNotPaused
        onlyCircleAdmin(id)
        onlyLegalAddress(user)
    {
        ApplyState applyState = _userInCircles[user][id];
        require(
            applyState == ApplyState.applying,
            Errors.CE_USER_HAS_NOT_APPLY
        );
        if (isApprove) {
            _userInCircles[user][id] = ApplyState.Approval;
            emit ApprovalJoinCircle(id, user);
        } else {
            _userInCircles[user][id] = ApplyState.refused;
            emit RefusedJoinCircle(id, user);
        }
    }

    /**
     * @dev Remove the user from the circle
     * @param id The id of the circle
     * @param user The address of the _user
     **/
    function deleteUserFromCircle(uint256 id, address user)
        external
        override
        whenNotPaused
        onlyCircleAdmin(id)
        onlyLegalAddress(msg.sender)
    {
        // DataTypes.UserData storage userData = _userDates[user];
        // require(
        //     userData.activeIOUAmount == 0,
        //     Errors.CE_USER_HAS_IOU
        // );
        ApplyState applyState = _userInCircles[user][id];
        require(
            applyState == ApplyState.Approval,
            Errors.CE_USER_NOT_IN_CIRCLE
        );
        _userInCircles[user][id] = ApplyState.none;
        emit DeleteUserFromCircle(id, user);
    }

    function createIOU(DataTypes.IOUData memory iou)
        external
        override
        whenNotPaused
        onlyLegalAddress(msg.sender)
    {
        ApplyState applyState = _userInCircles[msg.sender][iou.circleId];
        require(
            applyState == ApplyState.Approval,
            Errors.CE_USER_NOT_IN_CIRCLE
        );
        DataTypes.UserData storage userData = _userDates[msg.sender];
        require(
            userData.activeIOUAmount < maxIOUAmount,
            Errors.IOU_TOO_MANY_IOUS
        );
        require(iou.needAmount > 0, Errors.AMOUNT_IS_0);
        require(iou.startTime > uint40(block.timestamp), Errors.IOU_TIME_ERROR);
        require(iou.endTime > iou.startTime, Errors.IOU_TIME_ERROR);

        iou.borrower = msg.sender;
        iou.debtAmount = 0;
        iou.lastUpdateTimestamp = 0;
        iou.status = 0;

        _ious[_iousCount] = iou;
        userData.activeIOUAmount = userData.activeIOUAmount + 1;
        emit CreateIOU(msg.sender, _iousCount, iou.reserve, iou.needAmount);
        _iousCount += 1;
    }

    function supply(uint256 iouId, uint256 amount)
        external
        payable
        override
        whenNotPaused
    {
        DataTypes.IOUData storage iou = _ious[iouId];
        ApplyState applyState = _userInCircles[msg.sender][iou.circleId];
        require(
            applyState == ApplyState.Approval,
            Errors.CE_USER_NOT_IN_CIRCLE
        );
        _onlyLegalAddress(iou.borrower);
        require(uint40(block.timestamp) < iou.startTime, Errors.IOU_TIME_ERROR);
        require(iou.status == 0, Errors.IOU_NONACTIVATED_ERROR);
        require(amount >= iou.minInvestmentAmount, Errors.IOU_NEED_MORE_MONEY);
        require(
            iou.debtAmount.add(amount) <= iou.needAmount,
            Errors.IOU_TOO_MORE_MONEY
        );
        iou.debtAmount = iou.debtAmount.add(amount);
        _userLoanInIOUs[msg.sender][iouId] = _userLoanInIOUs[msg.sender][iouId]
        .add(amount);
        if (iou.reserve == _wethAddress) {
            require(msg.value == amount, Errors.IOU_NO_ENOUGH_ETH);
        } else {
            IERC20(iou.reserve).safeTransferFrom(
                msg.sender,
                address(this),
                amount
            );
        }
        emit Supply(msg.sender, iouId, iou.reserve, amount);
    }

    /**
     * @dev Borrower claims from the loan request(IOU)
     * @param iouId The id of the iou
     **/
    function claim(uint256 iouId)
        external
        override
        whenNotPaused
        onlyLegalAddress(msg.sender)
    {
        DataTypes.IOUData storage iou = _ious[iouId];
        require(iou.borrower == msg.sender, Errors.IOU_NOT_BORROWER);
        require(
            uint40(block.timestamp) >= iou.startTime,
            Errors.IOU_TIME_ERROR
        );
        require(iou.status == 0, Errors.IOU_NONACTIVATED_ERROR);
        require(
            iou.debtAmount >= iou.minStartAmount,
            Errors.IOU_NONACTIVATED_ERROR
        );
        uint256 fee = iou.debtAmount.mul(uint256(borrowFee)).div(10000);
        iou.status = 2;
        if (iou.reserve == _wethAddress) {
            msg.sender.transfer(iou.debtAmount.sub(fee));
        } else {
            IERC20(iou.reserve).safeTransfer(
                msg.sender,
                iou.debtAmount.sub(fee)
            );
        }
        _distributionFee(iou.reserve, _circlesAdmin[iou.circleId], fee);
        emit Claim(msg.sender, iouId, iou.reserve, iou.debtAmount);
    }

    function _distributionFee(
        address _reserve,
        address _circleAdmin,
        uint256 _fee
    ) internal {
        uint256 fee2admin = _fee.mul(uint256(circlesAdminProportion)).div(100);
        address payable treasuryAddress = address(
            uint160(_addressesProvider.getTreasuryAddress())
        );
        if (_reserve == _wethAddress) {
            treasuryAddress.transfer(_fee.sub(fee2admin));
            address(uint160(_circleAdmin)).transfer(fee2admin);
        } else {
            IERC20(_reserve).safeTransfer(treasuryAddress, _fee.sub(fee2admin));
            IERC20(_reserve).safeTransfer(_circleAdmin, fee2admin);
        }
    }

    /**
     * @dev Borrower to repay the loan
     * @param iouId The id of the iou
     **/
    function repay(uint256 iouId) external payable override whenNotPaused {
        DataTypes.IOUData storage iou = _ious[iouId];
        require(iou.borrower == msg.sender, Errors.IOU_NOT_BORROWER);
        require(
            uint40(block.timestamp) >= iou.startTime,
            Errors.IOU_TIME_ERROR
        );
        require(iou.status == 2, Errors.IOU_NONACTIVATED_ERROR);
        uint256 repayAmount;
        if (block.timestamp < iou.endTime) {
            repayAmount = iou.debtAmount.mulRay(
                uint256(iou.BorrowRate)
                .mul(block.timestamp.sub(uint256(iou.startTime)))
                .div(365 days)
            );
        }
        if (
            block.timestamp > uint256(iou.endTime) &&
            block.timestamp <= uint256(iou.endTime).add(_LatePeriod)
        ) {
            repayAmount = iou.debtAmount.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(
                    interestPenalty1.mul(
                        block.timestamp.sub(uint256(iou.endTime))
                    )
                ).div(365 days)
            );
        }
        if (block.timestamp > uint256(iou.endTime).add(_LatePeriod)) {
            repayAmount = iou.debtAmount.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(interestPenalty1.mul(_LatePeriod))
                .add(
                    interestPenalty2.mul(
                        block.timestamp.sub(
                            uint256(iou.endTime).add(_LatePeriod)
                        )
                    )
                ).div(365 days)
            );
        }
        if (iou.reserve == _wethAddress) {
            require(msg.value == repayAmount, Errors.IOU_NO_ENOUGH_ETH);
        } else {
            IERC20(iou.reserve).safeTransferFrom(
                msg.sender,
                address(this),
                repayAmount
            );
        }
        iou.status = 3;
        iou.lastUpdateTimestamp = uint40(block.timestamp);
        DataTypes.UserData storage userData = _userDates[msg.sender];
        userData.activeIOUAmount -= 1;
        emit Repay(msg.sender, iouId, iou.reserve, repayAmount);
    }

    /**
     * @dev The lender to withdraw the loan.
     * @param iouId The id of the iou
     **/
    function withdraw(uint256 iouId) external override whenNotPaused {
        uint256 loanAmount = _userLoanInIOUs[msg.sender][iouId];
        require(loanAmount > 0, Errors.IOU_NO_LOAN);
        DataTypes.IOUData memory iou = _ious[iouId];
        if (
            (iou.status == 0 &&
                uint40(block.timestamp) >= iou.startTime &&
                iou.debtAmount < iou.minStartAmount) || iou.status == 1
        ) {
            _userLoanInIOUs[msg.sender][iouId] = 0;
            if (iou.reserve == _wethAddress) {
                msg.sender.transfer(loanAmount);
            } else {
                IERC20(iou.reserve).safeTransfer(msg.sender, loanAmount);
            }
            emit Refund(msg.sender, iouId, iou.reserve, loanAmount);
        }
        if (iou.status == 3) {
            _userLoanInIOUs[msg.sender][iouId] = 0;
            _calculateEarnings(msg.sender, loanAmount, iouId);
        }
    }

    function _calculateEarnings(
        address payable _user,
        uint256 _amount,
        uint256 _iouId
    ) internal {
        DataTypes.IOUData memory iou = _ious[_iouId];
        uint256 reward;
        if (iou.lastUpdateTimestamp <= iou.endTime) {
            reward = _amount.mulRay(
                uint256(iou.BorrowRate)
                .mul(
                    uint256(iou.lastUpdateTimestamp).sub(uint256(iou.startTime))
                ).div(365 days)
            );
        }
        if (
            iou.lastUpdateTimestamp > iou.endTime &&
            uint256(iou.lastUpdateTimestamp) <=
            uint256(iou.endTime).add(_LatePeriod)
        ) {
            reward = _amount.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(
                    interestPenalty1.mul(
                        uint256(iou.lastUpdateTimestamp).sub(
                            uint256(iou.endTime)
                        )
                    )
                ).div(365 days)
            );
        }
        if (
            uint256(iou.lastUpdateTimestamp) >
            uint256(iou.endTime).add(_LatePeriod)
        ) {
            reward = _amount.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(interestPenalty1.mul(_LatePeriod))
                .add(
                    interestPenalty2.mul(
                        uint256(iou.lastUpdateTimestamp).sub(
                            uint256(iou.endTime).add(_LatePeriod)
                        )
                    )
                ).div(365 days)
            );
        }
        if (iou.reserve == _wethAddress) {
            _user.transfer(reward);
        } else {
            IERC20(iou.reserve).safeTransfer(_user, reward);
        }
        emit GetAward(_user, _iouId, iou.reserve, reward);
    }

    /**
     * @dev Returns the configuration of the IOU
     * @param id The id of the IOU
     * @return The configuration of the IOU
     **/
    function getIOUData(uint256 id)
        external
        view
        override
        returns (DataTypes.IOUData memory)
    {
        return _ious[id];
    }

    function getAmountOwed(uint256 id)
        external
        view
        override
        returns (address, uint256)
    {
        DataTypes.IOUData memory iou = _ious[id];
        address reserve = iou.reserve;
        uint256 reward;
        if (iou.status != 2) {
            return (reserve, 0);
        }
        if (iou.lastUpdateTimestamp <= iou.endTime) {
            reward = reward.mulRay(
                uint256(iou.BorrowRate)
                .mul(
                    uint256(iou.lastUpdateTimestamp).sub(uint256(iou.startTime))
                ).div(365 days)
            );
        }
        if (
            iou.lastUpdateTimestamp > iou.endTime &&
            uint256(iou.lastUpdateTimestamp) <=
            uint256(iou.endTime).add(_LatePeriod)
        ) {
            reward = reward.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(
                    interestPenalty1.mul(
                        uint256(iou.lastUpdateTimestamp).sub(
                            uint256(iou.endTime)
                        )
                    )
                ).div(365 days)
            );
        }
        if (
            uint256(iou.lastUpdateTimestamp) >
            uint256(iou.endTime).add(_LatePeriod)
        ) {
            reward = reward.mulRay(
                uint256(iou.BorrowRate)
                .mul(uint256(iou.endTime).sub(uint256(iou.startTime)))
                .add(interestPenalty1.mul(_LatePeriod))
                .add(
                    interestPenalty2.mul(
                        uint256(iou.lastUpdateTimestamp).sub(
                            uint256(iou.endTime).add(_LatePeriod)
                        )
                    )
                ).div(365 days)
            );
        }
        return (reserve, reward);
    }

    function getCirclesAdmin(uint256 id) external view returns (address) {
        return _circlesAdmin[id];
    }

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserData(address user)
        external
        view
        override
        returns (DataTypes.UserData memory)
    {
        return _userDates[user];
    }

    function setUserData(address user, DataTypes.UserData memory _data)
        external
        override
        onlyP2PoolConfigurator
    {
        _userDates[user] = _data;
    }

    function checkUserInCircle(address user, uint256 id)
        external
        view
        returns (ApplyState)
    {
        return _userInCircles[user][id];
    }

    /**
     * @dev Returns if the P2Pool is paused
     */
    function paused() external view override returns (bool) {
        return _paused;
    }

    /**
     * @dev Returns the cached P2PoolAddressesProvider connected to this contract
     **/
    function getAddressesProvider()
        external
        view
        override
        returns (IP2PoolAddressesProvider)
    {
        return _addressesProvider;
    }

    /**
     * @dev Set the _pause state of a reserve
     * - Only callable by the P2PoolConfigurator contract
     * @param val `true` to pause the reserve, `false` to un-pause it
     */
    function setPause(bool val) external override onlyP2PoolConfigurator {
        _paused = val;
        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }

    function setParams(
        uint256 latePeriod,
        uint256 penalty1,
        uint256 penalty2
    ) external override onlyP2PoolConfigurator {
        _LatePeriod = latePeriod;
        interestPenalty1 = penalty1;
        interestPenalty2 = penalty2;
    }

    function getParams()
        external
        view
        returns (
            uint8,
            uint256,
            uint256,
            uint256
        )
    {
        return (maxIOUAmount, _LatePeriod, interestPenalty1, interestPenalty2);
    }
}
