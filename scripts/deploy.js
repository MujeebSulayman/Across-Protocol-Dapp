const hre = require("hardhat");
const ethers = hre.ethers;
const fs = require("fs");
const path = require("path");

async function main() {
  const network = hre.network.name;

  const deploymentsDir = path.join(__dirname, "..", "deployments", network);
  fs.mkdirSync(deploymentsDir, { recursive: true });

  const HemswapCrossBridge = await ethers.getContractFactory(
    "HemswapCrossBridge"
  );

  // Get network-specific addresses
  const CORE_ROUTER_ADDRESS =
    process.env[`${network.toUpperCase()}_CORE_ROUTER_ADDRESS`];
  const SPOKE_POOL_ADDRESS =
    process.env[`${network.toUpperCase()}_SPOKE_POOL_ADDRESS`];
  const HUB_POOL_ADDRESS =
    process.env[`${network.toUpperCase()}_HUB_POOL_ADDRESS`];

  if (!CORE_ROUTER_ADDRESS || !SPOKE_POOL_ADDRESS || !HUB_POOL_ADDRESS) {
    throw new Error(`Missing contract addresses for network: ${network}`);
  }

  const [deployer] = await ethers.getSigners();

  console.log(`Deploying HemswapCrossBridge to ${network}...`);
  const hemswapCrossBridge = await HemswapCrossBridge.deploy(
    CORE_ROUTER_ADDRESS,
    SPOKE_POOL_ADDRESS,
    HUB_POOL_ADDRESS
  );

  await hemswapCrossBridge.deployed();

  const deploymentDetails = {
    network: network,
    contractName: "HemswapCrossBridge",
    contractAddress: hemswapCrossBridge.address,
    deployer: deployer.address,
    deploymentTimestamp: Date.now(),
    constructorArgs: {
      coreRouterAddress: CORE_ROUTER_ADDRESS,
      spokePoolAddress: SPOKE_POOL_ADDRESS,
      hubPoolAddress: HUB_POOL_ADDRESS,
    },
  };

  const filename = `${network}_${Date.now()}_deployment.json`;
  const fullPath = path.join(deploymentsDir, filename);

  // Write deployment details
  fs.writeFileSync(fullPath, JSON.stringify(deploymentDetails, null, 2));

  const latestDeploymentPath = path.join(
    deploymentsDir,
    "latest_deployment.json"
  );
  fs.writeFileSync(
    latestDeploymentPath,
    JSON.stringify(deploymentDetails, null, 2)
  );

  console.log(`Deployment details saved to ${fullPath}`);
  console.log(`HemswapCrossBridge deployed to: ${hemswapCrossBridge.address}`);

  try {
    await hre.run("verify:verify", {
      address: hemswapCrossBridge.address,
      constructorArguments: [
        CORE_ROUTER_ADDRESS,
        SPOKE_POOL_ADDRESS,
        HUB_POOL_ADDRESS,
      ],
    });
    console.log("Contract verification successful");
  } catch (error) {
    console.error("Verification failed:", error);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment error:", error);
    process.exit(1);
  });
