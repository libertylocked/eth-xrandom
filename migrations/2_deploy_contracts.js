const XRandom = artifacts.require('./XRandom.sol')

module.exports = (deployer, network, accounts) => {
  deployer.deploy(XRandom, [accounts[1], accounts[2]], accounts[0])
}
