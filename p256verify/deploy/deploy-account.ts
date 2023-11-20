import { utils, Wallet, Provider } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";
import dotenv from "dotenv";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  // @ts-ignore target zkSyncTestnet in config file which can be testnet or local
  const provider = new Provider("http://127.0.0.1:8011");
  const wallet = new Wallet("0x7726827caac94a7f9e1b160f7ea819f172f7b6f9d2a97f992c38edeab82d4110", provider);
  const deployer = new Deployer(hre, wallet);
  const factoryArtifact = await deployer.loadArtifact("AAFactory");
  const aaArtifact = await deployer.loadArtifact("PasskeyAccount");

  const GASLIMIT = {
    gasLimit: ethers.utils.hexlify(1000000)}

  // Bridge funds if the wallet on zkSync doesn't have enough funds.
  // const depositAmount = ethers.utils.parseEther('0.1');
  // const depositHandle = await deployer.zkWallet.deposit({
  //   to: deployer.zkWallet.address,
  //   token: utils.ETH_ADDRESS,
  //   amount: depositAmount,
  // });
  // await depositHandle.wait();

  const factory = await deployer.deploy(
    factoryArtifact,
    [utils.hashBytecode(aaArtifact.bytecode)],
    undefined,
    [aaArtifact.bytecode],
  );

  console.log(`AA factory address: ${factory.address}`);

  const aaFactory = new ethers.Contract(
    factory.address,
    factoryArtifact.abi,
    wallet,
  );

  const salt = ethers.constants.HashZero;
  //   const tx = await aaFactory.deployAccount(salt);
 //   await tx.wait();

    const transaction = await(await aaFactory.deployAccount(salt,GASLIMIT)).wait();
    const accountAddr = (await utils.getDeployedContracts(transaction))[0].deployedAddress
    const accountContract = new ethers.Contract(accountAddr, aaArtifact.abi, wallet)
    console.log(`account: "${accountContract.address}",`)

  //console.log(`SC Account deployed on address ${accountAddress}`);

  console.log("Funding smart contract account with some ETH");
  await (
    await wallet.sendTransaction({
      to: accountContract.address,
      value: ethers.utils.parseEther("0.005"),
    })
  ).wait();
  console.log(`Done!`);
}