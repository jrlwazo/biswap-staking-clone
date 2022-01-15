const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const AURAToken = artifacts.require('AURAToken');
const SmartChef = artifacts.require('SmartChef');
const MockBEP20 = artifacts.require('MockERC20');
const perBlock = '100';
const startBlock = '200';
const endBlock = '1000';
contract('SmartChef', ([alice, bob, carol, dev, refFeeAddr, minter]) => {
    beforeEach(async () => {
        this.aura = await AURAToken.new({ from: minter });// create AURAToken
        this.rewardToken = await MockBEP20.new('Reward Token', 'RW1', '1000000', { from: minter });// create reward token.
        this.chef = await SmartChef.new(this.aura.address, this.rewardToken.address, perBlock, startBlock, endBlock, { from: minter });// create smartchef contract.

        await this.aura.addMinter(minter, { from: minter });
        // await this.aura.addMinter(this.chef.address, { from: minter });

        await this.aura.mint(alice, '1000', { from: minter });
        await this.aura.mint(bob, '1000', { from: minter });
        await this.rewardToken.transfer(this.chef.address, '1000', { from: minter });
        console.log('balance chef for reward token: ', (await this.rewardToken.balanceOf(this.chef.address)).toString());
        console.log((await time.latestBlock()).toString());
    });

    describe("basic scenario", async () => {
        beforeEach("Approve and stake Aura; Wait for time to pass.", async () => {

            await time.advanceBlockTo("200");

            // approve address
            await this.aura.approve(this.chef.address, '1000', { from: alice });
            await this.aura.approve(this.chef.address, '1000', { from: bob });
            // deposit LP in chef
            await this.chef.deposit('1', { from: alice });
            await this.chef.deposit('1', { from: bob });

            assert.equal((await this.aura.balanceOf(alice)).toString(), '999');
            assert.equal((await this.aura.balanceOf(bob)).toString(), '999');
            assert.equal((await this.aura.balanceOf(this.chef.address)).toString(), '2');

            await time.advanceBlockTo('210');
        });

        it('should withdraw AURA and receive reward token', async () => {

            await this.chef.withdraw('1', { from: alice });

            await this.chef.withdraw('1', { from: bob });

            // await this.chef.withdrawRefFee({ from: minter });
            console.log('-----');

            assert.equal((await this.aura.balanceOf(alice)).toString(), '1000');
            assert.equal((await this.aura.balanceOf(bob)).toString(), '1000');
            assert.equal((await this.aura.balanceOf(this.chef.address)).toString(), '0');
            assert.equal((await this.rewardToken.balanceOf(alice)).toString(), '450');
            assert.equal((await this.rewardToken.balanceOf(bob)).toString(), '450');
            assert.equal((await this.rewardToken.balanceOf(this.chef.address)).toString(), '100');

            // console.log('balance reward token for ref fee: ', (await this.rewardToken.balanceOf(refFeeAddr)).toString());

        })

    });
    describe("updatePool before token added", async () => {
        beforeEach("unauthorized pool update", async () => {

            await time.advanceBlockTo('220');


            var { lpToken, allocPoint, lastRewardBlock, accAURAPerShare } = await this.chef.poolInfo(0);
            console.log('lpToken0:', lpToken);
            console.log('allocPoint0:', allocPoint.toString());
            console.log('lastRewardBlock0:', lastRewardBlock.toString());
            console.log('accAURAPerShare0:', accAURAPerShare.toString());
            console.log('--------');
            // var chefBal = await this.aura.balanceOf(this.chef.address);
            // console.log(chefBal.toString());
            await this.aura.transfer(this.chef.address, '10', { from: alice });
            var chefBal = await this.aura.balanceOf(this.chef.address);
            console.log(chefBal.toString());
            await this.chef.updatePool('0', { from: alice });

            var { lpToken, allocPoint, lastRewardBlock, accAURAPerShare } = await this.chef.poolInfo(0);
            console.log('lpToken1:', lpToken);
            console.log('allocPoint1:', allocPoint.toString());
            console.log('lastRewardBlock1:', lastRewardBlock.toString());
            console.log('accAURAPerShare1:', accAURAPerShare.toString());
            console.log('--------');
        });

        it('should update pool', async () => {


            // approve address
            await this.aura.approve(this.chef.address, '1000', { from: alice });
            await this.aura.approve(this.chef.address, '1000', { from: bob });
            // deposit LP in chef
            await this.chef.deposit('1', { from: alice });
            await this.chef.deposit('1', { from: bob });

            await time.advanceBlockTo('236');//+10

            console.log((await this.chef.pendingReward(alice)).toString());
            console.log((await this.chef.pendingReward(bob)).toString());

            // await this.chef.withdraw('1', { from: bob });


            var { lpToken, allocPoint, lastRewardBlock, accAURAPerShare } = await this.chef.poolInfo(0);
            console.log('lpToken:', lpToken);
            console.log('allocPoint:', allocPoint.toString());
            console.log('lastRewardBlock:', lastRewardBlock.toString());
            console.log('accAURAPerShare:', accAURAPerShare.toString());
            console.log('--------');
            // assert.equal((await this.aura.balanceOf(alice)).toString(), '1000');
            // assert.equal((await this.aura.balanceOf(bob)).toString(), '1000');
            // assert.equal((await this.aura.balanceOf(this.chef.address)).toString(), '0');
            // assert.equal((await this.rewardToken.balanceOf(alice)).toString(), '450');
            // assert.equal((await this.rewardToken.balanceOf(bob)).toString(), '450');
            // assert.equal((await this.rewardToken.balanceOf(this.chef.address)).toString(), '100');

            // console.log('balance reward token for ref fee: ', (await this.rewardToken.balanceOf(refFeeAddr)).toString());

        })

    });


});
