const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const JSBI = require('jsbi')
const GXOToken = artifacts.require('GXOToken');
const SmartChef = artifacts.require('SmartChef');
const MockBEP20 = artifacts.require('libs/MockBEP20');
const perBlock = '100';
contract('SmartChef', ([alice, bob, carol, dev, refFeeAddr, minter]) => {
    beforeEach(async () => {
        this.gxo = await GXOToken.new({ from: minter });// create GXOToken
        this.rewardToken = await MockBEP20.new('Reward Token', 'RW1', '1000000', { from: minter });// create reward token.
        this.chef = await SmartChef.new(this.gxo.address, this.rewardToken.address, perBlock, '200', '1000', { from: minter });// create smartchef contract.

        await this.gxo.addMinter(minter, { from: minter });
        // await this.gxo.addMinter(this.chef.address, { from: minter });

        await this.gxo.mint(alice, '1000', { from: minter });
        await this.gxo.mint(bob, '1000', { from: minter });
        await this.rewardToken.transfer(this.chef.address, '1000', { from: minter });
        console.log('balance chef for reward token: ', (await this.rewardToken.balanceOf(this.chef.address)).toString());
    });
    it('real case', async () => {

        console.log((await time.latestBlock()).toString());
        // approve address
        await this.gxo.approve(this.chef.address, '1000', { from: alice });
        await this.gxo.approve(this.chef.address, '1000', { from: bob });
        // deposit LP in chef
        await this.chef.deposit('1', { from: alice });
        await this.chef.deposit('1', { from: bob });

        let aliseGXOBalance = await this.gxo.balanceOf(alice);
        console.log('alise gxo balance: ', aliseGXOBalance.toString());
        console.log('balance gxo for chef: ', (await this.gxo.balanceOf(this.chef.address)).toString());
        let bobGXOBalance = await this.gxo.balanceOf(bob);
        console.log('bob gxo balance: ', bobGXOBalance.toString());
        console.log('balance gxo for chef: ', (await this.gxo.balanceOf(this.chef.address)).toString());

        // wait a few blocks before withdrawing.
        // var latestBlock = (await time.latestBlock()).toString();
        // console.log(latestBlock);
        await time.advanceBlockTo('225');

        await this.chef.withdraw('1', { from: alice });
        await this.chef.withdraw('1', { from: bob });
        // await this.chef.withdrawRefFee({ from: minter });
        console.log('-----');
        aliseGXOBalance = await this.gxo.balanceOf(alice);
        bobGXOBalance = await this.gxo.balanceOf(bob);
        console.log('alise gxo balance: ', aliseGXOBalance.toString());
        console.log('balance gxo for chef: ', (await this.gxo.balanceOf(this.chef.address)).toString());
        console.log('balance reward token for alice: ', (await this.rewardToken.balanceOf(alice)).toString());
        console.log('bob gxo balance: ', bobGXOBalance.toString());
        console.log('balance gxo for chef: ', (await this.gxo.balanceOf(this.chef.address)).toString());
        console.log('balance reward token for bob: ', (await this.rewardToken.balanceOf(bob)).toString());
        console.log('balance reward token for ref fee: ', (await this.rewardToken.balanceOf(refFeeAddr)).toString());

    })

});
