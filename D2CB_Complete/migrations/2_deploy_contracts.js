const SafeMath = artifacts.require("SafeMath");
const Strings = artifacts.require("Strings");
const D2CB = artifacts.require("D2CB");

module.exports = function(deployer) {
  deployer.deploy(SafeMath);
  deployer.link(SafeMath, D2CB);
  deployer.deploy(Strings);
  deployer.link(Strings, D2CB);
  deployer.deploy(D2CB);
};
