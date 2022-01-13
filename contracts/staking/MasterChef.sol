// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/BEP20.sol";
import "../tokens/AURAToken.sol";
import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";

interface IMigratorChef {
    function migrate(BEP20 token) external returns (BEP20);
}

// Note that it's ownable and the owner wields tremendous power. The ownership
// should be transferred to a governance smart contract.
//
contract MasterChef is Ownable, ReentrancyGuard {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of GXOs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accGXOPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accGXOPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        BEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. GXOs to distribute per block.
        uint256 lastRewardBlock; // Last block number that GXOs distribution occurs.
        uint256 accGXOPerShare; // Accumulated GXOs per share, times 1e12. See below.
    }
    // The GXO TOKEN!
    AuraToken public GXO;
    //Pools, Farms percent decimals
    uint256 public percentDec = 1000000;
    //Pools and Farms percent from token per block
    uint256 public stakingPercent;
    // GXO tokens created per block.
    uint256 public GXOPerBlock;
    // Bonus muliplier for early GXO makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when GXO mining starts.
    uint256 public startBlock;
    // Deposited amount GXO in MasterChef
    uint256 public depositedGxo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    constructor(
        AuraToken _GXO,
        uint256 _GXOPerBlock,
        uint256 _startBlock,
        uint256 _stakingPercent
    ) {
        GXO = _GXO;
        GXOPerBlock = _GXOPerBlock;
        startBlock = _startBlock;
        stakingPercent = _stakingPercent;
        
        
        // staking pool
        poolInfo.push(PoolInfo({
            lpToken: _GXO,
            allocPoint: 1000,
            lastRewardBlock: startBlock,
            accGXOPerShare: 0
        }));

        totalAllocPoint = 1000;

    }

    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add( uint256 _allocPoint, BEP20 _lpToken, bool _withUpdate ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint + _allocPoint;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accGXOPerShare: 0
            })
        );
    }

    // Update the given pool's GXO allocation point. Can only be called by the owner.
    function set( uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint - poolInfo[_pid].allocPoint + _allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // Set the migrator contract. Can only be called by the owner.
    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }

    // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        BEP20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.approve(address(migrator), bal);
        BEP20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
         return (_to - _from) * BONUS_MULTIPLIER;
    }

    // View function to see pending GXOs on frontend.
    function pendingGXO(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accGXOPerShare = pool.accGXOPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedGxo;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 GXOReward = (((((multiplier * GXOPerBlock) * pool.allocPoint) / totalAllocPoint) * stakingPercent) / percentDec);
            accGXOPerShare = accGXOPerShare + ((GXOReward * 1e12) / lpSupply);
        }
        return ((user.amount * accGXOPerShare) / 1e12) - user.rewardDebt;
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0){
            lpSupply = depositedGxo;
        }
        if (lpSupply <= 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 GXOReward = (((((multiplier * GXOPerBlock) * pool.allocPoint) / totalAllocPoint) * stakingPercent) / percentDec);
        GXO.mint(address(this), GXOReward);
        pool.accGXOPerShare = pool.accGXOPerShare + ((GXOReward * 1e12) / lpSupply);
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for GXO allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {

        require (_pid != 0, 'deposit GXO by staking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = (((user.amount * pool.accGXOPerShare) / 1e12) - user.rewardDebt);
            safeGXOTransfer(msg.sender, pending);
        }
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount + _amount;
        user.rewardDebt = (user.amount * pool.accGXOPerShare) / 1e12;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {

        require (_pid != 0, 'withdraw GXO by unstaking');

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = (((user.amount * pool.accGXOPerShare) / 1e12) - user.rewardDebt);
        safeGXOTransfer(msg.sender, pending);
        user.amount = user.amount - _amount;
        user.rewardDebt = ((user.amount * pool.accGXOPerShare) / 1e12);
        pool.lpToken.transfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

        // Stake GXO tokens to MasterChef
    function enterStaking(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = (((user.amount * pool.accGXOPerShare) / 1e12) - user.rewardDebt);
            if(pending > 0) {
                safeGXOTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount + _amount;
            depositedGxo = depositedGxo + _amount;
        }
        user.rewardDebt = ((user.amount * pool.accGXOPerShare) / 1e12);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw GXO tokens from STAKING.
    function leaveStaking(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "You can't withdraw more than is available.");
        updatePool(0);
        uint256 pending = (((user.amount * pool.accGXOPerShare) / 1e12) - user.rewardDebt);
        if(pending > 0) {
            safeGXOTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount - _amount;
            pool.lpToken.transfer(address(msg.sender), _amount);
            depositedGxo = depositedGxo - _amount;
        }
        user.rewardDebt = ((user.amount * pool.accGXOPerShare) / 1e12);
        emit Withdraw(msg.sender, 0, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.transfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe GXO transfer function, just in case if rounding error causes pool to not have enough GXOs.
    function safeGXOTransfer(address _to, uint256 _amount) internal {
        uint256 GXOBal = GXO.balanceOf(address(this));
        if (_amount > GXOBal) {
            GXO.transfer(_to, GXOBal);
        } else {
            GXO.transfer(_to, _amount);
        }
    }

    // Set GXO rewards per block - Min and Max hard-coded
    function updateGxoPerBlock(uint256 newAmount) public onlyOwner {
        require(newAmount <= 30 * 1e18, 'Max per block 30 GXO');
        require(newAmount >= 1 * 1e18, 'Min per block 1 GXO');
        GXOPerBlock = newAmount;
    }
}