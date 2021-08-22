const {
    constants,
    expectEvent,
    expectRevert,
    balance,
    time,
    ether,
} = require("@openzeppelin/test-helpers");
const web3 = require("web3");
const duration = time.duration;
const BN = web3.utils.BN;
const zero = new BN("0");
// Chai
const chai = require("chai");
chai.use(require("chai-bn")(BN));
chai.should();
// Artifacts imports
const FakeERC721 = artifacts.require("FakeERC721");
const NFTToNFTExchange = artifacts.require("NftToNftExchange");


contract("NFT to NFT Exchange TEST", (accounts) => {
    let [owner, firstAddr, secondAddr] = accounts;
    let NFTToNFTExchangeInstance;
    let FakeERC721InstanceOne;
    let FakeERC721InstanceTwo;

        beforeEach(async () => {
            NFTToNFTExchangeInstance = await NFTToNFTExchange.new(600);
            FakeERC721InstanceOne = await FakeERC721.new();
            await FakeERC721InstanceOne.mint(1, firstAddr);
            FakeERC721InstanceTwo = await FakeERC721.new();
            await FakeERC721InstanceTwo.mint(2, secondAddr);
        });
    
    it(`Create bid and check`, async () => {
        const tradeId = await NFTToNFTExchangeInstance.createBid(
            1,
            FakeERC721InstanceOne.address,
            FakeERC721InstanceTwo.address,
            2,
            700,
            {from: firstAddr, value: 3000}
        );
        const trade = await NFTToNFTExchangeInstance.getTradeById(
            tradeId
        );
    });

    // it(`Contract creation and mint`, async ()=>{
    //     const tenMlnTokens = new BN('10000000000000000000000000');

    //     const mintedTokens = await nomoTokenInstance.balanceOf("0x9e9CFeaC18c4987CB18bD25d3E11Af27EA6AaAc9");

    //     tenMlnTokens.should.bignumber.equal(mintedTokens);
    // });
    // it(`Name and symbol check`, async ()=>{
    //     (await nomoTokenInstance.name()).should.equal("Nomo Governance Token");
    //     (await nomoTokenInstance.symbol()).should.equal("NOMO");
    // });
});