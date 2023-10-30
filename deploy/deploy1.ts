import { Wallet } from "zksync-web3";
import * as ethers from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync-deploy";

// load env file
import dotenv from "dotenv";
dotenv.config();

// load wallet private key from env file
const PRIVATE_KEY = process.env.WALLET_PRIVATE_KEY || "";

if (!PRIVATE_KEY)
  throw "⛔️ Private key not detected! Add it to the .env file!";

// An example of a deploy script that will deploy and call a simple contract.
export default async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Running deploy script for the touch fan contract`);

  // Initialize the wallet.
  const owner = new Wallet(PRIVATE_KEY);

  console.log(`owner1 address is ${owner.address}`);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const deployer = new Deployer(hre, owner);


  const TFCommunitySharesV1Artifact = await deployer.loadArtifact("TFCommunitySharesV1");

  const TFCommunitySharesV1Contract = await deployer.deploy(TFCommunitySharesV1Artifact, []);

  console.log('TFCommunitySharesV1Contract address: ' + TFCommunitySharesV1Contract.address);


  const TFCommunitySharesV1ContractFullyQualifedName = "contracts/TFCommunitySharesV1_flat.sol:TFCommunitySharesV1";

  // // Verify contract programmatically
  // const verificationId2 = await hre.run("verify:verify", {
  //   address: TFCommunitySharesV1Contract.address,
  //   contract: TFCommunitySharesV1ContractFullyQualifedName,
  //   constructorArguments: [],
  //   bytecode: TFCommunitySharesV1Artifact.bytecode,
  // });


  const setCommunityFeeDestinationTX = await TFCommunitySharesV1Contract.setFeeDestination("0x444156834BC8Fc991324Bb2b5790Af0F1c57f825");
  await setCommunityFeeDestinationTX.wait()

  const setCommunityProtocolFeePercentTX = await TFCommunitySharesV1Contract.setProtocolFeePercent("70000000000000000");
  await setCommunityProtocolFeePercentTX.wait()

  const setCommunityReferrerFeePercentTx = await TFCommunitySharesV1Contract.setReferrerFeePercent("30000000000000000");
  await setCommunityReferrerFeePercentTx.wait()

  const setReferrerStorageTx = await TFCommunitySharesV1Contract.setReferrerStorage("0x1D68ae39BF07d05d41755C6342a6F724129D9FE0")
  await setReferrerStorageTx.wait()

  const setManagerTX = await TFCommunitySharesV1Contract.setManager(owner.address);
  await setManagerTX.wait()


  const setProposalFeeTX =  await TFCommunitySharesV1Contract.setProposalFee("50000000000000");
  await setProposalFeeTX.wait()


  const createProposalTx = await TFCommunitySharesV1Contract.createProposal("tf_123456",{value:"50000000000000"});
  await createProposalTx.wait()

  const updateProposalStateTX =  await TFCommunitySharesV1Contract.updateProposalState(1,100);
  await updateProposalStateTX.wait()



  let amount = await  TFCommunitySharesV1Contract.getCommunityBuyPriceAfterFee(1,"1000000")
  console.log("buy shares the right amount = "+ amount.toString());

  const buyCommunitySharesTX = await TFCommunitySharesV1Contract.buyCommunityShares(1,"1000000",{value:amount});
  await buyCommunitySharesTX.wait()


  const transferOwnershipCommunityTx = await TFCommunitySharesV1Contract.transferOwnership("0x0eAF6Be67D7cB0ADE23f3dD8180e43ca41824226")
  await transferOwnershipCommunityTx.wait()

  console.log(`deploy end`);
}
