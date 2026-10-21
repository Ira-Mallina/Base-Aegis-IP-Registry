const hre = require("hardhat");
async function main() {
  const RegistryCore = await hre.ethers.getContractFactory("AegisIpRegistry");
  const registry = await RegistryCore.deploy();
  await registry.deployed();
  console.log("-> IP Licensing Core live at:", registry.address);
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
