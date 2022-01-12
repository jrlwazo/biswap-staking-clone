const { time } = require('@openzeppelin/test-helpers');
const AURAToken = artifacts.require('AURAToken');
const InvestorMine = artifacts.require('InvestorMine');

const perBlock = '1633604000000000000';

contract('InvestorMine', ([devAddr, refFeeAddr, safuAddr, investorAddr, minter, test]) => {//address,address,address,address,uint,uint
    beforeEach(async () => {
        this.aura = await AURAToken.new({ from: minter });
        this.investor = await InvestorMine.new(this.aura.address, devAddr, refFeeAddr, safuAddr, investorAddr, perBlock, '0', { from: minter });

        await this.aura.addMinter(this.investor.address, { from: minter });
    });
    it('change addresses to test', async () => {
        await this.investor.setNewAddresses(test, test, test, test, { from: minter });

        assert.equal(await this.investor.investoraddr.call(), test);
        assert.equal(await this.investor.devaddr.call(), test);
        assert.equal(await this.investor.refaddr.call(), test);
        assert.equal(await this.investor.safuaddr.call(), test);

        await this.investor.setNewAddresses(investorAddr, devAddr, refFeeAddr, safuAddr, { from: minter });

        assert.equal(await this.investor.investoraddr.call(), investorAddr);
        assert.equal(await this.investor.devaddr.call(), devAddr);
        assert.equal(await this.investor.refaddr.call(), refFeeAddr);
        assert.equal(await this.investor.safuaddr.call(), safuAddr);

        await this.investor.updateGxoPerBlock('1633604000000000000', { from: minter });
        assert.equal(await this.investor.AURAPerBlock.call(), '1633604000000000000');

        await this.investor.updateGxoPerBlock('1633604000000000000', { from: minter });
        assert.equal(await this.investor.AURAPerBlock.call(), '1633604000000000000');

        await this.investor.changePercents('100000', '100000', '100000', '700000', { from: minter });

        assert.equal(await this.investor.investorPercent.call(), '100000');
        assert.equal(await this.investor.devPercent.call(), '100000');
        assert.equal(await this.investor.refPercent.call(), '100000');
        assert.equal(await this.investor.safuPercent.call(), '700000');

        await this.investor.changePercents('857000', '90000', '43000', '10000', { from: minter });

        assert.equal(await this.investor.investorPercent.call(), '857000');
        assert.equal(await this.investor.devPercent.call(), '90000');
        assert.equal(await this.investor.refPercent.call(), '43000');
        assert.equal(await this.investor.safuPercent.call(), '10000');

        console.log((await time.latestBlock()).toString());

        // await this.investor.updateLastWithdrawBlock('9', { from: minter });
        // assert.equal(await this.investor.lastBlockWithdraw.call(), '9');

        await time.advanceBlockTo('99');

        await this.investor.withdraw({ from: minter });
        console.log('-----');
        const devAddrBalance = await this.aura.balanceOf(devAddr);
        const refFeeAddrBalance = await this.aura.balanceOf(refFeeAddr);
        const safuAddrBalance = await this.aura.balanceOf(safuAddr);
        const investorAddrBalance = await this.aura.balanceOf(investorAddr);

        console.log('devAddrBalance aura balance: ', devAddrBalance / 1e18);
        console.log('refFeeAddrBalance aura balance: ', refFeeAddrBalance / 1e18);
        console.log('safuAddrBalance aura balance: ', safuAddrBalance / 1e18);
        console.log('investorAddrBalance aura balance: ', investorAddrBalance / 1e18);
    });
});
