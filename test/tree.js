const AccessRestriction = artifacts.require("AccessRestriction");
const Tree = artifacts.require("Tree.sol");

const assert = require("chai").assert;
require("chai").use(require("chai-as-promised")).should();
const { deployProxy } = require("@openzeppelin/truffle-upgrades");
const truffleAssert = require("truffle-assertions");
const Common = require("./common");

const {
  CommonErrorMsg,

  PlanterErrorMsg,
  erc721ErrorMsg,
} = require("./enumes");

//gsn
const WhitelistPaymaster = artifacts.require("WhitelistPaymaster");
const Gsn = require("@opengsn/provider");
const { GsnTestEnvironment } = require("@opengsn/cli/dist/GsnTestEnvironment");
const ethers = require("ethers");

contract("Tree", (accounts) => {
  let treeInstance;

  let arInstance;

  const dataManager = accounts[0];
  const deployerAccount = accounts[1];
  const userAccount1 = accounts[2];
  const userAccount2 = accounts[3];
  const userAccount3 = accounts[4];
  const userAccount4 = accounts[5];
  const userAccount5 = accounts[6];
  const userAccount6 = accounts[7];
  const userAccount7 = accounts[8];
  const userAccount8 = accounts[9];

  const zeroAddress = "0x0000000000000000000000000000000000000000";

  beforeEach(async () => {
    arInstance = await deployProxy(AccessRestriction, [deployerAccount], {
      initializer: "initialize",
      unsafeAllowCustomTypes: true,
      from: deployerAccount,
    });

    treeInstance = await deployProxy(Tree, [arInstance.address, "base uri"], {
      initializer: "initialize",
      from: deployerAccount,
      unsafeAllowCustomTypes: true,
    });
  });

  afterEach(async () => {});
  //////////////////------------------------------------ deploy successfully ----------------------------------------//

  it("deploys successfully", async () => {
    const address = treeInstance.address;
    assert.notEqual(address, 0x0);
    assert.notEqual(address, "");
    assert.notEqual(address, null);
    assert.notEqual(address, undefined);
  });
  it("set base uri", async () => {
    await treeInstance
      .setBaseURI("base uri", { from: userAccount1 })
      .should.be.rejectedWith(CommonErrorMsg.CHECK_ADMIN);

    await treeInstance.setBaseURI("base uri", { from: deployerAccount });
  });

  it("safe mint and exist", async () => {
    const tokenId1 = 2;
    await treeInstance
      .safeMint(userAccount1, tokenId1, { from: userAccount2 })
      .should.be.rejectedWith(CommonErrorMsg.CHECK_TREEJER_CONTTRACT);

    await treeInstance
      .safeMint(userAccount1, tokenId1, { from: deployerAccount })
      .should.be.rejectedWith(CommonErrorMsg.CHECK_TREEJER_CONTTRACT);

    await Common.addTreejerContractRole(
      arInstance,
      userAccount3,
      deployerAccount
    );

    const isExistBefore = await treeInstance.exists(tokenId1);

    assert.equal(isExistBefore, false, "exist is not true");

    await treeInstance.safeMint(userAccount1, tokenId1, { from: userAccount3 });

    const owner = await treeInstance.ownerOf(tokenId1);
    const isExistAfter = await treeInstance.exists(tokenId1);

    assert.equal(owner, userAccount1, "owner is not correct");
    assert.equal(isExistAfter, true, "exist is not correct");
  });

  it("minted before", async () => {
    const tokenId1 = 2;

    await Common.addTreejerContractRole(
      arInstance,
      userAccount3,
      deployerAccount
    );

    await treeInstance.safeMint(userAccount1, tokenId1, { from: userAccount3 });

    await treeInstance
      .safeMint(userAccount2, tokenId1, { from: userAccount3 })
      .should.be.rejectedWith(erc721ErrorMsg.MINTED_BEFORE);
  });
});