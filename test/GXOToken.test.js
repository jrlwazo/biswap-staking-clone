const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert, expect } = require('chai');


const JSBI = require('jsbi')
const GeometryToken = artifacts.require('GXOToken');



contract('GXOToken', ([alice, bob, carol, dev, refFeeAddr, safuAddr, minter]) => {
    beforeEach(async () => {
        //deploy 
        this.gxo = await GeometryToken.new({ from: minter });

        // add minter
        await this.gxo.addMinter(minter, { from: minter });
        // await this.gxo.addMinter(this.chef.address, { from: minter });
        await this.gxo.mint(alice, "10", { from: minter });
        //await this.gxo.transferOwnership(this.chef.address, { from: minter });



    });

    it('should have a name and symbol', async () => {
        expect((await this.gxo.name()).toString()).to.be.equal("Geometry");
        assert.equal(await this.gxo.symbol(), 'GXO');
    });
    it('should have a minter with valid address', async () => {
        expect((await this.gxo.getMinter(0, { from: minter }))).to.be.properAddress;

    });
    it('alice should have 10 GXO tokens', async () => {
        expect((await this.gxo.balanceOf(alice)).toString()).to.equal("10");

    });

    it('alice should delegate 5 GXO tokens', async () => {
        console.log("alice addr", alice);
        console.log(await this.gxo.delegates(alice));

        await this.gxo.delegate(bob, { from: alice });
        //    expect(await this.delegates(bob))

        console.log("alice addr", alice);
        console.log(await this.gxo.delegates(alice));
        console.log("bob addr", bob);
        console.log(await this.gxo.delegates(bob));

    });





});
