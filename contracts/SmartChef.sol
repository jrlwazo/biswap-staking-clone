//SPDX-License-Identifier:MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/safeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Contract that allows staking of AURA to receive BEP20Token reward.
 *
 *
 */
contract SmartChef is Ownable, ReentrancyGuard {
    // using SafeMath for uint256;
    using SafeERC20 for IERC20Metadata;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20Metadata lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. AURAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that AURAs distribution occurs.
        uint256 accAURAPerShare; // Accumulated AURAs per share, times PRECISION_FACTOR. See below.
    }

    // The AURA TOKEN!
    IERC20Metadata public aura;
    IERC20Metadata public rewardToken;

    // AURA tokens created per block.
    uint256 public rewardPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when AURA mining starts.
    uint256 public startBlock;
    // The block number when AURA mining ends.
    uint256 public bonusEndBlock;
    // limit 100 AURA
    uint256 public limitAmount = 100000000000000000000;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RefPercentChanged(uint256 currentPercent);

    constructor(
        IERC20Metadata _aura,
        IERC20Metadata _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        aura = _aura;
        rewardToken = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        require(decimalsRewardToken < 30, "Must be inferior to 30");

        PRECISION_FACTOR = uint256(10**(uint256(30) - decimalsRewardToken));

        // staking pool
        poolInfo.push(
            PoolInfo({
                lpToken: _aura,
                allocPoint: 1000,
                lastRewardBlock: startBlock,
                accAURAPerShare: 0
            })
        );
        totalAllocPoint = 1000;
    }

    // Set the limit amount.
    function setLimitAmount(uint256 _amount) public onlyOwner {
        limitAmount = _amount;
    }

    // Return remaining limit amount
    function remainingLimitAmount() public view returns (uint256) {
        if (userInfo[msg.sender].amount >= limitAmount) {
            return 0;
        }
        return limitAmount - userInfo[msg.sender].amount;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to - _from;
        } else if (_from >= bonusEndBlock) {
            return 0;
        } else {
            return bonusEndBlock - _from;
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[_user];
        uint256 accAURAPerShare = pool.accAURAPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 AURAReward = (multiplier *
                rewardPerBlock *
                pool.allocPoint) / totalAllocPoint;
            accAURAPerShare =
                accAURAPerShare +
                (AURAReward * PRECISION_FACTOR) /
                lpSupply;
        }
        return
            (user.amount * accAURAPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 AURAReward = (multiplier * rewardPerBlock * pool.allocPoint) /
            totalAllocPoint;
        pool.accAURAPerShare =
            pool.accAURAPerShare +
            (AURAReward * PRECISION_FACTOR) /
            lpSupply;
        pool.lastRewardBlock = block.number;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Stake aura tokens to SmartChef
    function deposit(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount + _amount <= limitAmount, "Exceed limit amount");

        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = (user.amount * pool.accAURAPerShare) /
                PRECISION_FACTOR -
                user.rewardDebt;
            if (pending > 0) {
                rewardToken.safeTransfer(address(msg.sender), pending);
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            user.amount = user.amount + _amount;
        }
        user.rewardDebt =
            (user.amount * pool.accAURAPerShare) /
            PRECISION_FACTOR;

        emit Deposit(msg.sender, _amount);
    }

    // Withdraw aura tokens from STAKING.
    function withdraw(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = (user.amount * pool.accAURAPerShare) /
            PRECISION_FACTOR -
            user.rewardDebt;
        if (pending > 0) {
            rewardToken.safeTransfer(address(msg.sender), pending);
        }
        if (_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt =
            (user.amount * pool.accAURAPerShare) /
            PRECISION_FACTOR;

        emit Withdraw(msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToTransfer = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        if (amountToTransfer > 0) {
            pool.lpToken.safeTransfer(address(msg.sender), amountToTransfer);
        }
        emit EmergencyWithdraw(msg.sender, amountToTransfer);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) public onlyOwner {
        require(
            _amount <= rewardToken.balanceOf(address(this)),
            "not enough token"
        );
        rewardToken.safeTransfer(address(msg.sender), _amount);
    }
}
