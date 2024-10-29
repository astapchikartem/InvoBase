const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Network:", network.name);
  console.log("Chain ID:", network.chainId);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  console.log("\n1. Deploying InvoiceNFT with UUPS proxy...");
  const InvoiceNFT = await ethers.getContractFactory("InvoiceNFT");
  const invoiceNFT = await upgrades.deployProxy(
    InvoiceNFT,
    [deployer.address],
    { 
      initializer: "initialize",
      kind: "uups"
    }
  );
  await invoiceNFT.waitForDeployment();
  const invoiceNFTAddress = await invoiceNFT.getAddress();
  console.log("InvoiceNFT Proxy deployed to:", invoiceNFTAddress);
  
  const invoiceNFTImpl = await upgrades.erc1967.getImplementationAddress(invoiceNFTAddress);
  console.log("InvoiceNFT Implementation:", invoiceNFTImpl);

  console.log("\n2. Deploying PaymentProcessor with UUPS proxy...");
  const PaymentProcessor = await ethers.getContractFactory("PaymentProcessor");
  const paymentProcessor = await upgrades.deployProxy(
    PaymentProcessor,
    [deployer.address, invoiceNFTAddress, deployer.address],
    { 
      initializer: "initialize",
      kind: "uups"
    }
  );
  await paymentProcessor.waitForDeployment();
  const paymentProcessorAddress = await paymentProcessor.getAddress();
  console.log("PaymentProcessor Proxy deployed to:", paymentProcessorAddress);
  
  const paymentProcessorImpl = await upgrades.erc1967.getImplementationAddress(paymentProcessorAddress);
  console.log("PaymentProcessor Implementation:", paymentProcessorImpl);

  console.log("\n3. Granting MINTER_ROLE to PaymentProcessor...");
  const MINTER_ROLE = await invoiceNFT.MINTER_ROLE();
  const tx = await invoiceNFT.grantRole(MINTER_ROLE, paymentProcessorAddress);
  await tx.wait();
  console.log("MINTER_ROLE granted successfully");

  const deploymentData = {
    network: network.name,
    chainId: network.chainId.toString(),
    deployer: deployer.address,
    timestamp: new Date().toISOString(),
    contracts: {
      InvoiceNFT: {
        proxy: invoiceNFTAddress,
        implementation: invoiceNFTImpl
      },
      PaymentProcessor: {
        proxy: paymentProcessorAddress,
        implementation: paymentProcessorImpl
      }
    }
  };

  const networksDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(networksDir)) {
    fs.mkdirSync(networksDir, { recursive: true });
  }

  const filename = path.join(networksDir, `${network.name}-${network.chainId}.json`);
  fs.writeFileSync(filename, JSON.stringify(deploymentData, null, 2));
  console.log("\nDeployment data saved to:", filename);

  console.log("\n=== Deployment Summary ===");
  console.log("InvoiceNFT Proxy:", invoiceNFTAddress);
  console.log("PaymentProcessor Proxy:", paymentProcessorAddress);
  console.log("\nVerify contracts with:");
  console.log(`npx hardhat verify --network ${network.name} ${invoiceNFTImpl}`);
  console.log(`npx hardhat verify --network ${network.name} ${paymentProcessorImpl}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
