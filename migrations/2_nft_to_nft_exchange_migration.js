const NftToNftExchange = artifacts.require("NftToNftExchange");

module.exports = function (deployer) {
  deployer.deploy(NftToNftExchange);
};
