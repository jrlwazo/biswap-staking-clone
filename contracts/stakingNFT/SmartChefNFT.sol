// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
import "./RewardTokens.sol";

interface IAuraNFT {
    function getStakingInfo(uint256 tokenId)
        external
        view
        returns (address tokenOwner, bool isStaked);

    function setIsStaked(uint256 tokenId, bool isStaked) external;
}

contract AuraChefNFT is ReentrancyGuard {
    RewardTokens private rewardTokens = new RewardTokens();

    IAuraNFT public auraNFT;

    // userAddress => tokenId => isStaked
    mapping(address => mapping(uint256 => bool)) private usersStakedTokens;
    mapping(address => uint256) private numUsersStakedTokens;

    event StakeTokens(address indexed user, uint256[] tokenIds);
    event UnstakeTokens(address indexed user, uint256[] tokenIds);

    constructor(IAuraNFT _auraNFT) {
        auraNFT = _auraNFT;
    }

    /**
     * @dev Add the caller's provided `tokenIds` to the staking pool and start earning rewards.
     */
    function stake(uint256[] calldata tokenIds) external nonReentrant {
        withdrawReward();

        for (uint256 i = 0; i < tokenIds.length; i++) {
            (address tokenOwner, bool isStaked) = auraNFT.getStakingInfo(
                tokenIds[i]
            );
            require(
                tokenOwner == msg.sender,
                "Caller is not this token's owner."
            );
            require(!isStaked, "This token is already staked.");

            auraNFT.setIsStaked(tokenIds[i], true);
            usersStakedTokens[msg.sender][tokenIds[i]] = true;
            numUsersStakedTokens[msg.sender]++;
        }

        emit StakeTokens(msg.sender, tokenIds);
    }

    /**
     * @dev Remove the callers provided `tokenIds` from the staking pool and cease earning rewards.
     */
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        require(
            numUsersStakedTokens[msg.sender] >= tokenIds.length,
            "Can't unstake more tokens than the caller has staked."
        );

        withdrawReward();

        // Match and unstake the tokens the caller wants to unstake with the tokens the caller has staked.
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (usersStakedTokens[msg.sender][tokenIds[i]]) {
                usersStakedTokens[msg.sender][tokenIds[i]] = false;
                numUsersStakedTokens[msg.sender]--;
                auraNFT.setIsStaked(tokenIds[i], false);
            } else {
                require(false, "The caller hasn't staked this token.");
            }
        }

        emit UnstakeTokens(msg.sender, tokenIds);
    }

    /**
     * @dev Transfer the callers earned staking rewards to their address.
     */
    function withdrawReward() public {
        updateStakingPoolRewards();

        address[] memory rewardTokensList = rewardTokens.getRewardTokensList();

        for (uint256 i = 0; i < rewardTokensList.length; i++) {
            // TODO
        }
    }

    /**
     * @dev Get a list of the tokens that the `_user` has staked in the pool.
     */
    function getUserStakedTokens(address _user)
        external
        view
        returns (uint256[] memory)
    {}

    /**
     * @dev Get the `_user`'s earned staking rewards for each reward token.
     */
    function getUserPendingRewards(address _user)
        external
        view
        returns (address[] memory, uint256[] memory)
    {}

    /**
     * @dev Update the staking pool's accumulated rewards.
     */
    function updateStakingPoolRewards() private {}

    /**
     * @return the reward multiplier as the difference between `_to` and `_from` blocks.
     */
    function getRewardMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return (_to > _from) ? _to - _from : 0;
    }
}
