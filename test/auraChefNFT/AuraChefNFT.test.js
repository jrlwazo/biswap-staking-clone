const AuraChefNFT = artifacts.require('AuraChefNFT');

contract('AuraChefNFT', ([owner]) => {
    beforeEach(async () => {
        this.auraChefNFT = await AuraChefNFT.deployed();
    });

    describe('When the contract is deployed', async () => {
        it('deploys successfully', async () => {
            const address = await this.auraChefNFT.address;
            assert.notEqual(address, 0x0);
            assert.notEqual(address, '');
            assert.notEqual(address, null);
            assert.notEqual(address, undefined);
        });
    });
});
