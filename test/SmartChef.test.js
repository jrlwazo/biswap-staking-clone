const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const JSBI = require('jsbi')
const AURAToken = artifacts.require('AURAToken');
const SmartChef = artifacts.require('SmartChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');
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
    it('real case', async () => {

        console.log((await time.latestBlock()).toString());
        // approve address
        await this.aura.approve(this.chef.address, '1000', { from: alice });
        await this.aura.approve(this.chef.address, '1000', { from: bob });
        // deposit LP in chef
        await this.chef.deposit('1', { from: alice });
        await this.chef.deposit('1', { from: bob });

        let aliseAURABalance = await this.aura.balanceOf(alice);
        console.log('alise aura balance: ', aliseAURABalance.toString());
        console.log('balance aura for chef: ', (await this.aura.balanceOf(this.chef.address)).toString());
        let bobAURABalance = await this.aura.balanceOf(bob);
        console.log('bob aura balance: ', bobAURABalance.toString());
        console.log('balance aura for chef: ', (await this.aura.balanceOf(this.chef.address)).toString());

        // wait a few blocks before withdrawing.
        // var latestBlock = (await time.latestBlock()).toString();
        // console.log(latestBlock);
        await time.advanceBlockTo('225');

        await this.chef.withdraw('1', { from: alice });
        await this.chef.withdraw('1', { from: bob });
        // await this.chef.withdrawRefFee({ from: minter });
        console.log('-----');
        aliseAURABalance = await this.aura.balanceOf(alice);
        bobAURABalance = await this.aura.balanceOf(bob);
        console.log('alise aura balance: ', aliseAURABalance.toString());
        console.log('balance aura for chef: ', (await this.aura.balanceOf(this.chef.address)).toString());
        console.log('balance reward token for alice: ', (await this.rewardToken.balanceOf(alice)).toString());
        console.log('bob aura balance: ', bobAURABalance.toString());
        console.log('balance aura for chef: ', (await this.aura.balanceOf(this.chef.address)).toString());
        console.log('balance reward token for bob: ', (await this.rewardToken.balanceOf(bob)).toString());
        console.log('balance reward token for ref fee: ', (await this.rewardToken.balanceOf(refFeeAddr)).toString());

    })

});
