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
  const referrerStorageArtifact = await deployer.loadArtifact("ReferrerStorage");


  const ReferrerStorageContract = await deployer.deploy(referrerStorageArtifact,[]);

  // Show the contract info.
  const contractAddress = ReferrerStorageContract.address;
  console.log(`ReferrerStorage was deployed to ${contractAddress}`);



  var setReferrerTx = await ReferrerStorageContract.setReferrer("0xEcb6f9d167F514d7C5764751468EC7658272Be5c");
  await setReferrerTx.wait()


  const ReferrerStorageContractFullyQualifedName = "contracts/ReferrerStorage_flat.sol:ReferrerStorage";

  // Verify contract programmatically
  const verificationId = await hre.run("verify:verify", {
    address: ReferrerStorageContract.address,
    contract: ReferrerStorageContractFullyQualifedName,
    constructorArguments: [],
    bytecode: referrerStorageArtifact.bytecode,
  });


  const TouchFanSharesV1Artifact = await deployer.loadArtifact("TouchFanSharesV1");


  const TouchFanSharesV1Contract = await deployer.deploy(TouchFanSharesV1Artifact, []);


  console.log('TouchFanSharesV1Contract address: ' + TouchFanSharesV1Contract.address)


  const TouchFanSharesV1ContractFullyQualifedName = "contracts/TouchFanSharesV1_flat.sol:TouchFanSharesV1";

  // Verify contract programmatically
  const verificationId1 = await hre.run("verify:verify", {
    address: TouchFanSharesV1Contract.address,
    contract: TouchFanSharesV1ContractFullyQualifedName,
    constructorArguments: [],
    bytecode: TouchFanSharesV1Artifact.bytecode,
  });



  const setFeeDestinationTX = await TouchFanSharesV1Contract.setFeeDestination("0xCAf79DB7a1450af467539a5a18c81785B4aAb4D9");
  await setFeeDestinationTX.wait()

  const setProtocolFeePercentTx = await TouchFanSharesV1Contract.setProtocolFeePercent("50000000000000000");
  await setProtocolFeePercentTx.wait()

  const setSubjectFeePercentTX = await TouchFanSharesV1Contract.setSubjectFeePercent("40000000000000000");
  await setSubjectFeePercentTX.wait()

  const setReferrerFeePercentTX = await TouchFanSharesV1Contract.setReferrerFeePercent("10000000000000000");
  await setReferrerFeePercentTX.wait()


  const setReferrerStorageTX = await TouchFanSharesV1Contract.setReferrerStorage(ReferrerStorageContract.address)
  await setReferrerStorageTX.wait()

  let amount = await  TouchFanSharesV1Contract.getBuyPriceAfterFee(owner.address,"1000000")
  console.log("buy shares the right amount = "+ amount.toString());
  const buySharesTx = await TouchFanSharesV1Contract.buyShares(owner.address,"1000000",{value:amount});
  await buySharesTx.wait()


  const transferOwnershipTx = await TouchFanSharesV1Contract.transferOwnership("0xEe506f213874D70DD1de66EDf32784BEB4917B87")
  await transferOwnershipTx.wait()


  const TFCommunitySharesV1Artifact = await deployer.loadArtifact("TFCommunitySharesV1");

  const TFCommunitySharesV1Contract = await deployer.deploy(TFCommunitySharesV1Artifact, []);

  console.log('TFCommunitySharesV1Contract address: ' + TFCommunitySharesV1Contract.address);


  const TFCommunitySharesV1ContractFullyQualifedName = "contracts/TFCommunitySharesV1_flat.sol:TFCommunitySharesV1";

  // Verify contract programmatically
  const verificationId2 = await hre.run("verify:verify", {
    address: TFCommunitySharesV1Contract.address,
    contract: TFCommunitySharesV1ContractFullyQualifedName,
    constructorArguments: [],
    bytecode: TFCommunitySharesV1Artifact.bytecode,
  });


  const setCommunityFeeDestinationTX = await TFCommunitySharesV1Contract.setFeeDestination("0xCAf79DB7a1450af467539a5a18c81785B4aAb4D9");
  await setCommunityFeeDestinationTX.wait()

  const setCommunityProtocolFeePercentTX = await TFCommunitySharesV1Contract.setProtocolFeePercent("70000000000000000");
  await setCommunityProtocolFeePercentTX.wait()

  const setCommunityReferrerFeePercentTx = await TFCommunitySharesV1Contract.setReferrerFeePercent("30000000000000000");
  await setCommunityReferrerFeePercentTx.wait()

  const setReferrerStorageTx = await TFCommunitySharesV1Contract.setReferrerStorage(ReferrerStorageContract.address)
  await setReferrerStorageTx.wait()

  const setManagerTX = await TFCommunitySharesV1Contract.setManager(owner.address);
  await setManagerTX.wait()


  const setProposalFeeTX =  await TFCommunitySharesV1Contract.setProposalFee("500000000000000");
  await setProposalFeeTX.wait()


  // const createProposalTx = await TFCommunitySharesV1Contract.createProposal("tf_123456",{value:"500000000000000"});
  // await createProposalTx.wait()
  //
  // const updateProposalStateTX =  await TFCommunitySharesV1Contract.updateProposalState(1,100);
  // await updateProposalStateTX.wait()
  //
  //
  //
  // amount = await  TFCommunitySharesV1Contract.getCommunityBuyPriceAfterFee(1,"1000000")
  // console.log("buy shares the right amount = "+ amount.toString());
  //
  // const buyCommunitySharesTX = await TFCommunitySharesV1Contract.buyCommunityShares(1,"1000000",{value:amount});
  // await buyCommunitySharesTX.wait()


  const transferOwnershipCommunityTx = await TFCommunitySharesV1Contract.transferOwnership("0xEe506f213874D70DD1de66EDf32784BEB4917B87")
  await transferOwnershipCommunityTx.wait()

  console.log(`deploy end`);
}
