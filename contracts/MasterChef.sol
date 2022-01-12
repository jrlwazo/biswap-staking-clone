//SPDX-License-Identifier:MIT
pragma solidity >=0.8.10;

// library SafeBEP20 {
//     using SafeMath for uint256;
//     using Address for address;

//     function safeTransfer(
//         IBEP20 token,
//         address to,
//         uint256 value
//     ) internal {
//         _callOptionalReturn(
//             token,
//             abi.encodeWithSelector(token.transfer.selector, to, value)
//         );
//     }

//     function safeTransferFrom(
//         IBEP20 token,
//         address from,
//         address to,
//         uint256 value
//     ) internal {
//         _callOptionalReturn(
//             token,
//             abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
//         );
//     }

//     /**
//      * @dev Deprecated. This function has issues similar to the ones found in
//      * {IBEP20-approve}, and its usage is discouraged.
//      *
//      * Whenever possible, use {safeIncreaseAllowance} and
//      * {safeDecreaseAllowance} instead.
//      */
//     function safeApprove(
//         IBEP20 token,
//         address spender,
//         uint256 value
//     ) internal {
//         // safeApprove should only be called when setting an initial allowance,
//         // or when resetting it to zero. To increase and decrease it, use
//         // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
//         // solhint-disable-next-line max-line-length
//         require(
//             (value == 0) || (token.allowance(address(this), spender) == 0),
//             "SafeBEP20: approve from non-zero to non-zero allowance"
//         );
//         _callOptionalReturn(
//             token,
//             abi.encodeWithSelector(token.approve.selector, spender, value)
//         );
//     }

//     function safeIncreaseAllowance(
//         IBEP20 token,
//         address spender,
//         uint256 value
//     ) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).add(
//             value
//         );
//         _callOptionalReturn(
//             token,
//             abi.encodeWithSelector(
//                 token.approve.selector,
//                 spender,
//                 newAllowance
//             )
//         );
//     }

//     function safeDecreaseAllowance(
//         IBEP20 token,
//         address spender,
//         uint256 value
//     ) internal {
//         uint256 newAllowance = token.allowance(address(this), spender).sub(
//             value,
//             "SafeBEP20: decreased allowance below zero"
//         );
//         _callOptionalReturn(
//             token,
//             abi.encodeWithSelector(
//                 token.approve.selector,
//                 spender,
//                 newAllowance
//             )
//         );
//     }

//     /**
//      * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
//      * on the return value: the return value is optional (but if data is returned, it must not be false).
//      * @param token The token targeted by the call.
//      * @param data The call data (encoded using abi.encode or one of its variants).
//      */
//     function _callOptionalReturn(IBEP20 token, bytes memory data) private {
//         // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
//         // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
//         // the target address contains contract code and also asserts for success in the low-level call.

//         bytes memory returndata = address(token).functionCall(
//             data,
//             "SafeBEP20: low-level call failed"
//         );
//         if (returndata.length > 0) {
//             // Return data is optional
//             // solhint-disable-next-line max-line-length
//             require(
//                 abi.decode(returndata, (bool)),
//                 "SafeBEP20: BEP20 operation did not succeed"
//             );
//         }
//     }
// }

// import "./AURAToken.sol";

// interface IMigratorChef {
//     function migrate(IBEP20 token) external returns (IBEP20);
// }

// // MasterChef is the master of GXO. He can make GXO and he is a fair guy.
// //
// // Note that it's ownable and the owner wields tremendous power. The ownership
// // will be transferred to a governance smart contract once GXO is sufficiently
// // distributed and the community can show to govern itself.
// //
// // Have fun reading it. Hopefully it's bug-free. God bless.
// contract MasterChef is Ownable {
//     using SafeMath for uint256;
//     using SafeBEP20 for IBEP20;
//     // Info of each user.
//     struct UserInfo {
//         uint256 amount; // How many LP tokens the user has provided.
//         uint256 rewardDebt; // Reward debt. See explanation below.
//         //
//         // We do some fancy math here. Basically, any point in time, the amount of GXOs
//         // entitled to a user but is pending to be distributed is:
//         //
//         //   pending reward = (user.amount * pool.accGXOPerShare) - user.rewardDebt
//         //
//         // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
//         //   1. The pool's `accGXOPerShare` (and `lastRewardBlock`) gets updated.
//         //   2. User receives the pending reward sent to his/her address.
//         //   3. User's `amount` gets updated.
//         //   4. User's `rewardDebt` gets updated.
//     }
//     // Info of each pool.
//     struct PoolInfo {
//         IBEP20 lpToken; // Address of LP token contract.
//         uint256 allocPoint; // How many allocation points assigned to this pool. GXOs to distribute per block.
//         uint256 lastRewardBlock; // Last block number that GXOs distribution occurs.
//         uint256 accGXOPerShare; // Accumulated GXOs per share, times 1e12. See below.
//     }
//     // The GXO TOKEN!
//     AURAToken public GXO;
//     //Pools, Farms, Dev, Refs percent decimals
//     uint256 public percentDec = 1000000;
//     //Pools and Farms percent from token per block
//     uint256 public stakingPercent;
//     //Developers percent from token per block
//     uint256 public devPercent;
//     //Referrals percent from token per block
//     uint256 public refPercent;
//     //Safu fund percent from token per block
//     uint256 public safuPercent;
//     // Dev address.
//     address public devaddr;
//     // Safu fund.
//     address public safuaddr;
//     // Refferals commision address.
//     address public refAddr;
//     // Last block then develeper withdraw dev and ref fee
//     uint256 public lastBlockDevWithdraw;
//     // GXO tokens created per block.
//     uint256 public GXOPerBlock;
//     // Bonus muliplier for early GXO makers.
//     uint256 public BONUS_MULTIPLIER = 1;
//     // The migrator contract. It has a lot of power. Can only be set through governance (owner).
//     IMigratorChef public migrator;
//     // Info of each pool.
//     PoolInfo[] public poolInfo;
//     // Info of each user that stakes LP tokens.
//     mapping(uint256 => mapping(address => UserInfo)) public userInfo;
//     // Total allocation poitns. Must be the sum of all allocation points in all pools.
//     uint256 public totalAllocPoint = 0;
//     // The block number when GXO mining starts.
//     uint256 public startBlock;
//     // Deposited amount GXO in MasterChef
//     uint256 public depositedGxo;

//     event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
//     event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
//     event EmergencyWithdraw(
//         address indexed user,
//         uint256 indexed pid,
//         uint256 amount
//     );

//     constructor(
//         AURAToken _GXO,
//         address _devaddr,
//         address _refAddr,
//         address _safuaddr,
//         uint256 _GXOPerBlock,
//         uint256 _startBlock,
//         uint256 _stakingPercent,
//         uint256 _devPercent,
//         uint256 _refPercent,
//         uint256 _safuPercent
//     ) public {
//         GXO = _GXO;
//         devaddr = _devaddr;
//         refAddr = _refAddr;
//         safuaddr = _safuaddr;
//         GXOPerBlock = _GXOPerBlock;
//         startBlock = _startBlock;
//         stakingPercent = _stakingPercent;
//         devPercent = _devPercent;
//         refPercent = _refPercent;
//         safuPercent = _safuPercent;
//         lastBlockDevWithdraw = _startBlock;

//         // staking pool
//         poolInfo.push(
//             PoolInfo({
//                 lpToken: _GXO,
//                 allocPoint: 1000,
//                 lastRewardBlock: startBlock,
//                 accGXOPerShare: 0
//             })
//         );

//         totalAllocPoint = 1000;
//     }

//     function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
//         BONUS_MULTIPLIER = multiplierNumber;
//     }

//     function poolLength() external view returns (uint256) {
//         return poolInfo.length;
//     }

//     function withdrawDevAndRefFee() public {
//         require(lastBlockDevWithdraw < block.number, "wait for new block");
//         uint256 multiplier = getMultiplier(lastBlockDevWithdraw, block.number);
//         uint256 GXOReward = multiplier.mul(GXOPerBlock);
//         GXO.mint(devaddr, GXOReward.mul(devPercent).div(percentDec));
//         GXO.mint(safuaddr, GXOReward.mul(safuPercent).div(percentDec));
//         GXO.mint(refAddr, GXOReward.mul(refPercent).div(percentDec));
//         lastBlockDevWithdraw = block.number;
//     }

//     // Add a new lp to the pool. Can only be called by the owner.
//     // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
//     //TODO: create check to see if lp token has already been added.
//     function add(
//         uint256 _allocPoint,
//         IBEP20 _lpToken,
//         bool _withUpdate
//     ) public onlyOwner {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         uint256 lastRewardBlock = block.number > startBlock
//             ? block.number
//             : startBlock;
//         totalAllocPoint = totalAllocPoint.add(_allocPoint);
//         poolInfo.push(
//             PoolInfo({
//                 lpToken: _lpToken,
//                 allocPoint: _allocPoint,
//                 lastRewardBlock: lastRewardBlock,
//                 accGXOPerShare: 0
//             })
//         );
//     }

//     // Update the given pool's GXO allocation point. Can only be called by the owner.
//     function set(
//         uint256 _pid,
//         uint256 _allocPoint,
//         bool _withUpdate
//     ) public onlyOwner {
//         if (_withUpdate) {
//             massUpdatePools();
//         }
//         totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
//             _allocPoint
//         );
//         poolInfo[_pid].allocPoint = _allocPoint;
//     }

//     // Set the migrator contract. Can only be called by the owner.
//     function setMigrator(IMigratorChef _migrator) public onlyOwner {
//         migrator = _migrator;
//     }

//     // Migrate lp token to another lp contract. Can be called by anyone. We trust that migrator contract is good.
//     function migrate(uint256 _pid) public {
//         require(address(migrator) != address(0), "migrate: no migrator");
//         PoolInfo storage pool = poolInfo[_pid];
//         IBEP20 lpToken = pool.lpToken;
//         uint256 bal = lpToken.balanceOf(address(this));
//         lpToken.safeApprove(address(migrator), bal);
//         IBEP20 newLpToken = migrator.migrate(lpToken);
//         require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
//         pool.lpToken = newLpToken;
//     }

//     // Return reward multiplier over the given _from to _to block.
//     function getMultiplier(uint256 _from, uint256 _to)
//         public
//         view
//         returns (uint256)
//     {
//         return _to.sub(_from).mul(BONUS_MULTIPLIER);
//     }

//     // View function to see pending GXOs on frontend.
//     function pendingGXO(uint256 _pid, address _user)
//         external
//         view
//         returns (uint256)
//     {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][_user];
//         uint256 accGXOPerShare = pool.accGXOPerShare;
//         uint256 lpSupply = pool.lpToken.balanceOf(address(this));
//         if (_pid == 0) {
//             lpSupply = depositedGxo;
//         }
//         if (block.number > pool.lastRewardBlock && lpSupply != 0) {
//             uint256 multiplier = getMultiplier(
//                 pool.lastRewardBlock,
//                 block.number
//             );
//             uint256 GXOReward = multiplier
//                 .mul(GXOPerBlock)
//                 .mul(pool.allocPoint)
//                 .div(totalAllocPoint)
//                 .mul(stakingPercent)
//                 .div(percentDec);
//             accGXOPerShare = accGXOPerShare.add(
//                 GXOReward.mul(1e12).div(lpSupply)
//             );
//         }
//         return user.amount.mul(accGXOPerShare).div(1e12).sub(user.rewardDebt);
//     }

//     // Update reward vairables for all pools. Be careful of gas spending!
//     function massUpdatePools() public {
//         uint256 length = poolInfo.length;
//         for (uint256 pid = 0; pid < length; ++pid) {
//             updatePool(pid);
//         }
//     }

//     // Update reward variables of the given pool to be up-to-date.
//     function updatePool(uint256 _pid) public {
//         PoolInfo storage pool = poolInfo[_pid];
//         if (block.number <= pool.lastRewardBlock) {
//             return;
//         }
//         uint256 lpSupply = pool.lpToken.balanceOf(address(this));
//         if (_pid == 0) {
//             lpSupply = depositedGxo;
//         }
//         if (lpSupply <= 0) {
//             pool.lastRewardBlock = block.number;
//             return;
//         }
//         uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
//         uint256 GXOReward = multiplier
//             .mul(GXOPerBlock)
//             .mul(pool.allocPoint)
//             .div(totalAllocPoint)
//             .mul(stakingPercent)
//             .div(percentDec);
//         GXO.mint(address(this), GXOReward);
//         pool.accGXOPerShare = pool.accGXOPerShare.add(
//             GXOReward.mul(1e12).div(lpSupply)
//         );
//         pool.lastRewardBlock = block.number;
//     }

//     // Deposit LP tokens to MasterChef for GXO allocation.
//     function deposit(uint256 _pid, uint256 _amount) public {
//         require(_pid != 0, "deposit GXO by staking");

//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         updatePool(_pid);
//         if (user.amount > 0) {
//             uint256 pending = user
//                 .amount
//                 .mul(pool.accGXOPerShare)
//                 .div(1e12)
//                 .sub(user.rewardDebt);
//             safeGXOTransfer(msg.sender, pending);
//         }
//         pool.lpToken.safeTransferFrom(
//             address(msg.sender),
//             address(this),
//             _amount
//         );
//         user.amount = user.amount.add(_amount);
//         user.rewardDebt = user.amount.mul(pool.accGXOPerShare).div(1e12);
//         emit Deposit(msg.sender, _pid, _amount);
//     }

//     // Withdraw LP tokens from MasterChef.
//     function withdraw(uint256 _pid, uint256 _amount) public {
//         require(_pid != 0, "withdraw GXO by unstaking");

//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         require(user.amount >= _amount, "withdraw: not good");
//         updatePool(_pid);
//         uint256 pending = user.amount.mul(pool.accGXOPerShare).div(1e12).sub(
//             user.rewardDebt
//         );
//         safeGXOTransfer(msg.sender, pending);
//         user.amount = user.amount.sub(_amount);
//         user.rewardDebt = user.amount.mul(pool.accGXOPerShare).div(1e12);
//         pool.lpToken.safeTransfer(address(msg.sender), _amount);
//         emit Withdraw(msg.sender, _pid, _amount);
//     }

//     // Stake GXO tokens to MasterChef
//     function enterStaking(uint256 _amount) public {
//         PoolInfo storage pool = poolInfo[0];
//         UserInfo storage user = userInfo[0][msg.sender];
//         updatePool(0);
//         if (user.amount > 0) {
//             uint256 pending = user
//                 .amount
//                 .mul(pool.accGXOPerShare)
//                 .div(1e12)
//                 .sub(user.rewardDebt);
//             if (pending > 0) {
//                 safeGXOTransfer(msg.sender, pending);
//             }
//         }
//         if (_amount > 0) {
//             pool.lpToken.safeTransferFrom(
//                 address(msg.sender),
//                 address(this),
//                 _amount
//             );
//             user.amount = user.amount.add(_amount);
//             depositedGxo = depositedGxo.add(_amount);
//         }
//         user.rewardDebt = user.amount.mul(pool.accGXOPerShare).div(1e12);
//         emit Deposit(msg.sender, 0, _amount);
//     }

//     // Withdraw GXO tokens from STAKING.
//     function leaveStaking(uint256 _amount) public {
//         PoolInfo storage pool = poolInfo[0];
//         UserInfo storage user = userInfo[0][msg.sender];
//         require(user.amount >= _amount, "withdraw: not good");
//         updatePool(0);
//         uint256 pending = user.amount.mul(pool.accGXOPerShare).div(1e12).sub(
//             user.rewardDebt
//         );
//         if (pending > 0) {
//             safeGXOTransfer(msg.sender, pending);
//         }
//         if (_amount > 0) {
//             user.amount = user.amount.sub(_amount);
//             pool.lpToken.safeTransfer(address(msg.sender), _amount);
//             depositedGxo = depositedGxo.sub(_amount);
//         }
//         user.rewardDebt = user.amount.mul(pool.accGXOPerShare).div(1e12);
//         emit Withdraw(msg.sender, 0, _amount);
//     }

//     // Withdraw without caring about rewards. EMERGENCY ONLY.
//     function emergencyWithdraw(uint256 _pid) public {
//         PoolInfo storage pool = poolInfo[_pid];
//         UserInfo storage user = userInfo[_pid][msg.sender];
//         pool.lpToken.safeTransfer(address(msg.sender), user.amount);
//         emit EmergencyWithdraw(msg.sender, _pid, user.amount);
//         user.amount = 0;
//         user.rewardDebt = 0;
//     }

//     // Safe GXO transfer function, just in case if rounding error causes pool to not have enough GXOs.
//     function safeGXOTransfer(address _to, uint256 _amount) internal {
//         uint256 GXOBal = GXO.balanceOf(address(this));
//         if (_amount > GXOBal) {
//             GXO.transfer(_to, GXOBal);
//         } else {
//             GXO.transfer(_to, _amount);
//         }
//     }

//     function setDevAddress(address _devaddr) public onlyOwner {
//         devaddr = _devaddr;
//     }

//     function setRefAddress(address _refaddr) public onlyOwner {
//         refAddr = _refaddr;
//     }

//     function setSafuAddress(address _safuaddr) public onlyOwner {
//         safuaddr = _safuaddr;
//     }

//     function updateGxoPerBlock(uint256 newAmount) public onlyOwner {
//         require(newAmount <= 30 * 1e18, "Max per block 30 GXO");
//         require(newAmount >= 1 * 1e18, "Min per block 1 GXO");
//         GXOPerBlock = newAmount;
//     }
// }
