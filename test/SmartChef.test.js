const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const JSBI = require('jsbi')
const AURAToken = artifacts.require('AURAToken');
const SmartChef = artifacts.require('SmartChef');
const MockBEP20 = artifacts.require('MockERC20');
const perBlock = '100';
contract('SmartChef', ([alice, bob, carol, dev, refFeeAddr, minter]) => {
    beforeEach(async () => {
        this.aura = await AURAToken.new({ from: minter });// create AURAToken
        this.rewardToken = await MockBEP20.new('Reward Token', 'RW1', '1000000', { from: minter });// create reward token.
        this.chef = await SmartChef.new(this.aura.address, this.rewardToken.address, perBlock, '200', '1000', { from: minter });// create smartchef contract.

        await this.aura.addMinter(minter, { from: minter });
        // await this.aura.addMinter(this.chef.address, { from: minter });

        await this.aura.mint(alice, '1000', { from: minter });
        await this.aura.mint(bob, '1000', { from: minter });
        await this.rewardToken.transfer(this.chef.address, '1000', { from: minter });
        console.log('balance chef for reward token: ', (await this.rewardToken.balanceOf(this.chef.address)).toString());
    });
    describe("basic scenario", async () => {
        beforeEach("Approve and stake Aura; Wait for time to pass.", async () => {
            console.log((await time.latestBlock()).toString());
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


});
