const RewardTokens = artifacts.require('RewardTokens');
const AuraChefNFT = artifacts.require('AuraChefNFT');

module.exports = (deployer) => {
    deployer.deploy(RewardTokens);
    deployer.deploy(AuraChefNFT);
}
