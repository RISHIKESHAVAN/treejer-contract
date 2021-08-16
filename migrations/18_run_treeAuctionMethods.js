require("dotenv").config();

const TreeAuction = artifacts.require("TreeAuction.sol");
const TreeFactory = artifacts.require("TreeFactory.sol");
const FinancialModel = artifacts.require("FinancialModel.sol");
const WethFunds = artifacts.require("WethFunds.sol");
const Weth = artifacts.require("Weth.sol");

module.exports = async function (deployer, network, accounts) {
  const isLocal = network === "development";

  const treeFactoryAddress = TreeFactory.address;
  const financialModelAddress = FinancialModel.address;
  const wethFundsAddress = WethFunds.address;
  let wethTokenAddress;
  let trustedForwarder;

  if (isLocal) {
    trustedForwarder = require("../build/gsn/Forwarder.json").address;

    wethTokenAddress = Weth.address;
  } else {
    trustedForwarder = process.env.GSN_FORWARDER;

    wethTokenAddress = eval(
      `process.env.WETH_TOKEN_ADDRESS_${network.toUpperCase()}`
    );
  }

  console.log("Call TreeAuction Methods...");
  await TreeAuction.deployed().then(async (instance) => {
    await instance.setTrustedForwarder(trustedForwarder);
    await instance.setTreeFactoryAddress(treeFactoryAddress);
    await instance.setFinancialModelAddress(financialModelAddress);
    await instance.setWethFundsAddress(wethFundsAddress);
    await instance.setWethTokenAddress(wethTokenAddress);
  });
};