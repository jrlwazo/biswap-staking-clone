const { expectRevert, time } = require('@openzeppelin/test-helpers');
const { assert, expect } = require('chai');


const JSBI = require('jsbi')
const GeometryToken = artifacts.require('GXOToken');



contract('GXOToken', ([alice, bob, carol, dev, refFeeAddr, safuAddr, minter]) => {
    beforeEach(async () => {
        //deploy 
        this.geometry = await GeometryToken.new({ from: minter });
        console.log((await this.geometry.name()));


        // add minter
        await this.geometry.addMinter(minter, { from: minter });
        // await this.geometry.addMinter(this.chef.address, { from: minter });
        await this.geometry.mint(alice, "1", { from: minter });
        //await this.geometry.transferOwnership(this.chef.address, { from: minter });



    });

    it('should have a name and symbol', async () => {
        expect((await this.geometry.name()).toString()).to.be.equal("Geometry");
        assert.equal(await this.geometry.symbol(), 'GXO');
    });
    it('should have a minter with value address', async () => {
        expect((await this.geometry.getMinter(0, { from: minter }))).to.be.properAddress;

    });




});
