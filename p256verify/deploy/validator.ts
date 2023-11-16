import {
    utils,
    Wallet,
    Provider,
    Contract,
    EIP712Signer,
    types,
  } from "zksync-web3";
  import * as ethers from "ethers";
  import { HardhatRuntimeEnvironment } from "hardhat/types";
  
  const ACCOUNT_ADDRESS = "0xC222602E616ABb2B1A50D7162e218ecbBFedc6e9";
  
  export default async function (hre: HardhatRuntimeEnvironment) {
    // @ts-ignore target zkSyncTestnet in config file which can be testnet or local
    const provider = new Provider(hre.config.networks.zkSyncTestnet.url);
    const owner = new Wallet("2c204cd103db06e84c958d479372ce60567d98bf24ace26a0cc5191870fed067",provider);
    const accountArtifact = await hre.artifacts.readArtifact("Validator");
    const account = new Contract(ACCOUNT_ADDRESS, accountArtifact.abi, owner);
  
    let setLimitTx = await account.validateSignature("0x03e17259cbdd698089d9edac71d5fbb505b5d3f724e5776dd31711108e3f8dd9","0x0dfc52f4a13c03848e5553601685a5b262a06c50eaa6ef9fe997d6f7fcca9110615a29fdf780d6e60b030bddd268f0ffb2a4c0d05b8942c462f57929a5eba750",["0x779def53aa6758bf8fceebdc9778f843032ab0938fdcc260af677af87f40d8be","0x4c7ac9619e91a27693c3e57f1dbd3c64c9c47e66cc5aef322ac5dc935cc22de1"]);
    console.log(setLimitTx)
}
  