const { ethers, upgrades } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  
  console.log("Upgrading contracts with account:", deployer.address);
  console.log("Network:", network.name);
  console.log("Chain ID:", network.chainId);

  const deploymentsFile = path.join(
    __dirname,
    "..",
    "deployments",
    `${network.name}-${network.chainId}.json`
  );

  if (!fs.existsSync(deploymentsFile)) {
    console.error("Deployment file not found. Deploy contracts first!");
    process.exit(1);
  }

  const deploymentData = JSON.parse(fs.readFileSync(deploymentsFile, "utf8"));
  const invoiceNFTProxy = deploymentData.contracts.InvoiceNFT.proxy;
  const paymentProcessorProxy = deploymentData.contracts.PaymentProcessor.proxy;

  console.log("\n=== Current Deployment ===");
  console.log("InvoiceNFT Proxy:", invoiceNFTProxy);
  console.log("PaymentProcessor Proxy:", paymentProcessorProxy);

  console.log("\n1. Upgrading InvoiceNFT to V2...");
  const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
  const invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTProxy, InvoiceNFTV2);
  await invoiceNFTV2.waitForDeployment();
  
  const newInvoiceImpl = await upgrades.erc1967.getImplementationAddress(invoiceNFTProxy);
  console.log("New InvoiceNFT Implementation:", newInvoiceImpl);
  
  const version1 = await invoiceNFTV2.version();
  console.log("InvoiceNFT Version:", version1);

  console.log("\n2. Upgrading PaymentProcessor to V2...");
  const PaymentProcessorV2 = await ethers.getContractFactory("PaymentProcessorV2");
  const paymentProcessorV2 = await upgrades.upgradeProxy(paymentProcessorProxy, PaymentProcessorV2);
  await paymentProcessorV2.waitForDeployment();
  
  const newPaymentImpl = await upgrades.erc1967.getImplementationAddress(paymentProcessorProxy);
  console.log("New PaymentProcessor Implementation:", newPaymentImpl);
  
  const version2 = await paymentProcessorV2.version();
  console.log("PaymentProcessor Version:", version2);

  const upgradeData = {
    network: network.name,
    chainId: network.chainId.toString(),
    upgrader: deployer.address,
    timestamp: new Date().toISOString(),
    upgrades: {
      InvoiceNFT: {
        proxy: invoiceNFTProxy,
        oldImplementation: deploymentData.contracts.InvoiceNFT.implementation,
        newImplementation: newInvoiceImpl,
        version: version1
      },
      PaymentProcessor: {
        proxy: paymentProcessorProxy,
        oldImplementation: deploymentData.contracts.PaymentProcessor.implementation,
        newImplementation: newPaymentImpl,
        version: version2
      }
    }
  };

  deploymentData.contracts.InvoiceNFT.implementation = newInvoiceImpl;
  deploymentData.contracts.InvoiceNFT.version = version1;
  deploymentData.contracts.PaymentProcessor.implementation = newPaymentImpl;
  deploymentData.contracts.PaymentProcessor.version = version2;
  deploymentData.lastUpgrade = new Date().toISOString();

  fs.writeFileSync(deploymentsFile, JSON.stringify(deploymentData, null, 2));

  const upgradesDir = path.join(__dirname, "..", "deployments", "upgrades");
  if (!fs.existsSync(upgradesDir)) {
    fs.mkdirSync(upgradesDir, { recursive: true });
  }

  const upgradeFile = path.join(
    upgradesDir,
    `upgrade-${Date.now()}-${network.name}.json`
  );
  fs.writeFileSync(upgradeFile, JSON.stringify(upgradeData, null, 2));

  console.log("\n=== Upgrade Summary ===");
  console.log("InvoiceNFT upgraded to V2");
  console.log("PaymentProcessor upgraded to V2");
  console.log("\nNew features added:");
  console.log("- Global statistics tracking");
  console.log("- User statistics");
  console.log("- Batch operations");
  console.log("- Enhanced analytics");
  console.log("\nUpgrade data saved to:", upgradeFile);
  console.log("Deployment data updated:", deploymentsFile);

  console.log("\n=== Test New Features ===");
  const stats = await invoiceNFTV2.getStatistics();
  console.log("Total invoices created:", stats[0].toString());
  console.log("Pending:", stats[1].toString());
  console.log("Paid:", stats[2].toString());
  console.log("Cancelled:", stats[3].toString());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
