// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Reserve.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Staking is Ownable {
    using Counters for Counters.Counter;
    StakingReserve public immutable reserve;
    IERC20 public immutable gold;
    event StakeUpdate(
        address account,
        uint256 packageId,
        uint256 amount,
        uint256 totalProfit
    );
    event StakeReleased(
        address account,
        uint256 packageId,
        uint256 amount,
        uint256 totalProfit
    );
    struct StakePackage {
        uint256 rate;
        uint256 decimal;
        uint256 minStaking;
        uint256 lockTime;
        bool isOffline;
    }
    struct StakingInfo {
        uint256 startTime;
        uint256 timePoint;
        uint256 amount;
        uint256 totalProfit;
    }
    Counters.Counter private _stakePackageCount;
    mapping(uint256 => StakePackage) public stakePackages;
    mapping(address => mapping(uint256 => StakingInfo)) public stakes;

    /**
     * @dev Initialize
     * @notice This is the initialize function, run on deploy event
     * @param tokenAddr_ address of main token
     * @param reserveAddress_ address of reserve contract
     */
    constructor(address tokenAddr_, address reserveAddress_) {
        require(
            tokenAddr_ != address(0),
            "StakingSC: tokenAddr_ is zero address"
        );
        require(
            reserveAddress_ != address(0),
            "StakingSC: reserveAddress_ is zero address"
        );
        gold = IERC20(tokenAddr_);
        reserve = StakingReserve(reserveAddress_);
        _stakePackageCount.increment();
    }

    /**
     * @dev Add new staking package
     * @notice New package will be added with an id
     */
    function addStakePackage(
        uint256 rate_,
        uint256 decimal_,
        uint256 minStaking_,
        uint256 lockTime_
    ) public onlyOwner {
        uint256 _stakeId = _stakePackageCount.current();
        stakePackages[_stakeId] = StakePackage(
            rate_,
            decimal_,
            minStaking_,
            lockTime_,
            true
        );
        _stakePackageCount.increment();
    }

    /**
     * @dev Remove an stake package
     * @notice A stake package with packageId will be set to offline
     * so none of new staker can stake to an offine stake package
     */
    function removeStakePackage(uint256 packageId_) public onlyOwner {
        StakePackage storage _stakePackage = stakePackages[packageId_];
        _stakePackage.isOffline = true;
    }

    /**
     * @dev User stake amount of gold to stakes[address][packageId]
     * @notice if is there any amount of gold left in the stake package,
     * calculate the profit and add it to total Profit,
     * otherwise just add completely new stake. 
     */
    function stake(uint256 amount_, uint256 packageId_) external {
        StakePackage storage _stakePackage = stakePackages[packageId_];
        require(amount_ >= _stakePackage.minStaking);
        require(amount_ <= gold.balanceOf(_msgSender()), "StakingSC: Not enough STATE tokens in your wallet, please try lesser amount");
        uint256 _totalProfit =(_stakePackage.rate * amount_) / 10**(_stakePackage.decimal + 2);
        stakes[_msgSender()][packageId_] = StakingInfo(
            block.timestamp,
            1,
            amount_,
            _totalProfit
        );
    }
    /**
     * @dev Take out all the stake amount and profit of account's stake from reserve contract
     */
    function unStake(uint256 packageId_) external {
        // validate available package and approved amount
    }
    /**
     * @dev calculate current profit of an package of user known packageId
     */

    function calculateProfit(uint256 packageId_)
        public
        view
        returns (uint256)
    {
        StakePackage storage _stakePackage = stakePackages[packageId_];
        return _stakePackage.rate / 10**(_stakePackage.decimal + 2);
    }

    function getAprOfPackage(uint256 packageId_)
        public
        view
        returns (uint256)
    {}
}
