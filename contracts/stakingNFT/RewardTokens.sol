// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title This contract manages RewardTokens which are the rewards earned for staking.
 */
contract RewardTokens is Ownable {
    address[] private rewardTokensList;

    struct RewardToken {
        uint rewardPerBlock; // Invariant: rewardPerBlock may not be zero.
        bool enabled;
    }

    mapping (address => RewardToken) private rewardTokens;

    event CreateRewardToken(
        address newToken,
        uint rewardPerBlock
    );

    event SetRewardPerBlock(uint newRewardPerBlock);
    event SetEnabled(bool newEnabled);
    event DestroyRewardToken(address destroyedBy);

    /**
     * @return true if `_token` is RewardToken and false otherwise.
     */
    function isRewardToken(address _token) public view returns(bool) {
        return rewardTokens[_token].rewardPerBlock != 0;
    }

    /**
     * @return the addresses of the tokens that are currently RewardTokens.
     */
    function getRewardTokensList() public view returns(address[] memory) {
        return rewardTokensList;
    }

    /**
     * @return The RewardSettings for a given RewardToken.
     */
    function getRewardToken(address _rewardToken) public view returns(RewardToken memory) {
        return rewardTokens[_rewardToken];
    }

    /**
     * @notice Creates a new RewardToken with the given settings.
     * @param _newToken address to be recognized as a RewardToken.
     * @param _rewardPerBlock the amount paid to the staker per block their token is staked.
     */
    function createRewardToken(address _newToken, uint _rewardPerBlock) external onlyOwner {
        require(_newToken != address(0), "Invalid token address.");
        require(!isRewardToken(_newToken), "This RewardToken already exists.");
        require(_rewardPerBlock > 0, "The reward must not be zero.");

        // Add token to the list.
        rewardTokensList.push(_newToken);

        // Add token to the mapping.
        rewardTokens[_newToken].rewardPerBlock = _rewardPerBlock;
        rewardTokens[_newToken].enabled = true;

        emit CreateRewardToken(_newToken, _rewardPerBlock);
    }

    /**
     * @param _rewardToken the RewardToken to remove from being a RewardToken.
     */
    function destroyRewardToken(address _rewardToken) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address.");
    
        // Remove the rewardToken from the list.
        for (uint i = 0; i < rewardTokensList.length; i++) {
            if (_rewardToken == rewardTokensList[i]) { 
                remove(i);
                break;
            }
        }

        // Remove the rewardToken from the mapping.
        delete rewardTokens[_rewardToken];
        
        emit DestroyRewardToken(msg.sender);
    }

    /**
     * @dev Utility function used by destroyRewardToken.
     *      Removes index from rewardTokensList by copying the last 
     *      element into the place to remove.
     */
    function remove(uint index) private {
        rewardTokensList[index] = rewardTokensList[rewardTokensList.length - 1];
        rewardTokensList.pop();
    }

    /**
     * @dev Set the rewardPerBlock for a given RewardToken.
     */
    function setRewardPerBlock(address _rewardToken, uint _rewardPerBlock) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address.");
        require(isRewardToken(_rewardToken), "This RewardToken doesn't exist.");
        require(_rewardPerBlock > 0, "Try disabling instead.");

        rewardTokens[_rewardToken].rewardPerBlock = _rewardPerBlock; 

        emit SetRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @dev Set the enabled status for a given RewardToken.
     */
    function setEnabled(address _rewardToken, bool _enabled) external onlyOwner {
        require(_rewardToken != address(0), "Invalid token address.");
        require(isRewardToken(_rewardToken), "This RewardToken doesn't exist.");

        rewardTokens[_rewardToken].enabled = _enabled;

        emit SetEnabled(_enabled);
    }
}
