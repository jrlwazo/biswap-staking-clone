const RewardTokens = artifacts.require('RewardTokens.sol');

contract('RewardTokens', (accounts) => {
    const owner = accounts[0];

    beforeEach(async () => {
        this.rewardTokens = await RewardTokens.deployed(); 
    });

    describe('When the contract is deployed', async () => {
        it('deploys successfully', async () => {
            const address = await this.rewardTokens.address;
            assert.notEqual(address, 0x0);
            assert.notEqual(address, '');
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });

        it('has an assigned owner', async () => {
            const _owner = await this.rewardTokens.owner();
            assert.equal(owner, _owner.toString());
        });

        it('has no preexisting RewardTokens', async () => {
            const rewardTokensList = await this.rewardTokens.getRewardTokensList();
            const emptyList = [];
            assert.equal(rewardTokensList.length, emptyList.length);
            assert.equal(rewardTokensList[0], emptyList[0]);
        });
    });

    describe('When a new RewardToken is created', async () => {
        it('a CreateRewardToken Event is emitted', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const rewardPerBlock = 10;
            const result = await this.rewardTokens.createRewardToken(address, rewardPerBlock);
            const event = result.logs[0].args;
            assert.equal(event.newToken, '0x6b97a384E32e28f75202B78548037b0AEA27875e', {from: owner});
            assert.equal(event.rewardPerBlock, 10);
        });

        it('recognizes that the new RewardToken exists', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const result = await this.rewardTokens.isRewardToken(address);
            assert.equal(result, true);
        });

        it('adds the new RewardToken to the list', async () => {
            const rewardTokensList = await this.rewardTokens.getRewardTokensList();
            assert.equal(rewardTokensList.length, 1);
            assert.equal(rewardTokensList[0], '0x6b97a384E32e28f75202B78548037b0AEA27875e');
        });

        it('adds the new RewardToken to the mapping', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const rewardToken = await this.rewardTokens.getRewardToken(address);
            assert.equal(rewardToken.rewardPerBlock, 10);
            assert.equal(rewardToken.enabled, true);
        });
    });

    describe('When an existing RewardToken rewardPerBlock is changed', async () => {
        it('a SetRewardPerBlock event is emitted', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const newRewardPerBlock = 20;
            const result = await this.rewardTokens.setRewardPerBlock(address, newRewardPerBlock, {from: owner});
            const event = result.logs[0].args;
            assert.equal(event.newRewardPerBlock, 20);
        });

        it('the rewardPerBlock value is changed', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const rewardToken = await this.rewardTokens.getRewardToken(address);
            assert.equal(rewardToken.rewardPerBlock, 20);
            assert.equal(rewardToken.enabled, true);
        });
    });

    describe('When an existing RewardToken enabled status is changed', async() => {
        it('a SetEventEnabled event is emitted', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const newEnabled = false;
            const result = await this.rewardTokens.setEnabled(address, newEnabled, {from: owner});
            const event = result.logs[0].args;
            assert.equal(event.newEnabled, false);
        });

        it('the enabled status is changed', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const rewardToken = await this.rewardTokens.getRewardToken(address);
            assert.equal(rewardToken.rewardPerBlock, 20);
            assert.equal(rewardToken.enabled, false);
        });
    });

    describe('When an existing RewardToken is destroyed', async () => {
        it('a DestroyRewardToken event is emitted', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const result = await this.rewardTokens.destroyRewardToken(address, {from: owner});
            const event = result.logs[0].args;
            assert.equal(event.destroyedBy, owner);
        });

        it('recognizes that the RewardToken no longer exists', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const result = await this.rewardTokens.isRewardToken(address);
            assert.equal(result, false);
        });

        it('removes the new RewardToken from the list', async () => {
            const rewardTokensList = await this.rewardTokens.getRewardTokensList();
            const emptyList = [];
            assert.equal(rewardTokensList.length, 0);
            assert.equal(rewardTokensList[0], emptyList[0]);
        });

        it('removes the new RewardToken from the mapping', async () => {
            const address = '0x6b97a384E32e28f75202B78548037b0AEA27875e';
            const rewardToken = await this.rewardTokens.getRewardToken(address);
            assert.equal(rewardToken.rewardPerBlock, 0);
            assert.equal(rewardToken.enabled, false);
        });
    });
});
