const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("Contract Upgrades", function () {
  let invoiceNFT, paymentProcessor;
  let invoiceNFTV2, paymentProcessorV2;
  let owner, creator, recipient;
  let invoiceNFTAddress, paymentProcessorAddress;

  beforeEach(async function () {
    [owner, creator, recipient] = await ethers.getSigners();

    const InvoiceNFT = await ethers.getContractFactory("InvoiceNFT");
    invoiceNFT = await upgrades.deployProxy(
      InvoiceNFT,
      [owner.address],
      { initializer: "initialize", kind: "uups" }
    );
    await invoiceNFT.waitForDeployment();
    invoiceNFTAddress = await invoiceNFT.getAddress();

    const PaymentProcessor = await ethers.getContractFactory("PaymentProcessor");
    paymentProcessor = await upgrades.deployProxy(
      PaymentProcessor,
      [owner.address, invoiceNFTAddress, owner.address],
      { initializer: "initialize", kind: "uups" }
    );
    await paymentProcessor.waitForDeployment();
    paymentProcessorAddress = await paymentProcessor.getAddress();

    const MINTER_ROLE = await invoiceNFT.MINTER_ROLE();
    await invoiceNFT.grantRole(MINTER_ROLE, paymentProcessorAddress);
  });

  describe("InvoiceNFT Upgrade to V2", function () {
    it("Should upgrade to V2 and maintain state", async function () {
      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await invoiceNFT.connect(creator).createInvoice(
        recipient.address,
        amount,
        ethers.ZeroAddress,
        "Test Invoice",
        dueDate
      );

      const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
      invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTAddress, InvoiceNFTV2);

      expect(await invoiceNFTV2.ownerOf(1)).to.equal(creator.address);
      expect(await invoiceNFTV2.version()).to.equal("2.0.0");
    });

    it("Should have new statistics feature", async function () {
      const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
      invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTAddress, InvoiceNFTV2);

      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await invoiceNFTV2.connect(creator).createInvoice(
        recipient.address,
        amount,
        ethers.ZeroAddress,
        "Test Invoice",
        dueDate
      );

      const stats = await invoiceNFTV2.getStatistics();
      expect(stats[0]).to.equal(1);
      expect(stats[1]).to.equal(1);
    });

    it("Should support batch invoice creation", async function () {
      const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
      invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTAddress, InvoiceNFTV2);

      const recipients = [recipient.address, recipient.address, recipient.address];
      const amounts = [
        ethers.parseEther("1.0"),
        ethers.parseEther("2.0"),
        ethers.parseEther("3.0")
      ];
      const tokens = [ethers.ZeroAddress, ethers.ZeroAddress, ethers.ZeroAddress];
      const descriptions = ["Invoice 1", "Invoice 2", "Invoice 3"];
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      const dueDates = [dueDate, dueDate, dueDate];

      const tx = await invoiceNFTV2.connect(creator).batchCreateInvoices(
        recipients,
        amounts,
        tokens,
        descriptions,
        dueDates
      );

      const stats = await invoiceNFTV2.getStatistics();
      expect(stats[0]).to.equal(3);
    });

    it("Should track user statistics", async function () {
      const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
      invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTAddress, InvoiceNFTV2);

      const amount = ethers.parseEther("5.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await invoiceNFTV2.connect(creator).createInvoice(
        recipient.address,
        amount,
        ethers.ZeroAddress,
        "Test Invoice",
        dueDate
      );

      const userStats = await invoiceNFTV2.getUserStatistics(creator.address);
      expect(userStats.totalAmount).to.equal(amount);
      expect(userStats.invoiceCount).to.equal(1);
    });
  });

  describe("PaymentProcessor Upgrade to V2", function () {
    it("Should upgrade to V2 and maintain configuration", async function () {
      const oldFee = await paymentProcessor.platformFee();

      const PaymentProcessorV2 = await ethers.getContractFactory("PaymentProcessorV2");
      paymentProcessorV2 = await upgrades.upgradeProxy(paymentProcessorAddress, PaymentProcessorV2);

      expect(await paymentProcessorV2.platformFee()).to.equal(oldFee);
      expect(await paymentProcessorV2.version()).to.equal("2.0.0");
    });

    it("Should have global statistics feature", async function () {
      const PaymentProcessorV2 = await ethers.getContractFactory("PaymentProcessorV2");
      paymentProcessorV2 = await upgrades.upgradeProxy(paymentProcessorAddress, PaymentProcessorV2);

      const stats = await paymentProcessorV2.getGlobalStatistics();
      expect(stats.totalPayments).to.equal(0);
      expect(stats.totalVolume).to.equal(0);
    });

    it("Should support batch token support updates", async function () {
      const PaymentProcessorV2 = await ethers.getContractFactory("PaymentProcessorV2");
      paymentProcessorV2 = await upgrades.upgradeProxy(paymentProcessorAddress, PaymentProcessorV2);

      const tokens = [
        "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
        "0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb"
      ];
      const supported = [true, true];

      await paymentProcessorV2.batchUpdateTokenSupport(tokens, supported);

      expect(await paymentProcessorV2.supportedTokens(tokens[0])).to.be.true;
      expect(await paymentProcessorV2.supportedTokens(tokens[1])).to.be.true;
    });
  });

  describe("Integration after Upgrade", function () {
    it("Should maintain invoice data and create new with statistics", async function () {
      const InvoiceNFTV2 = await ethers.getContractFactory("InvoiceNFTV2");
      invoiceNFTV2 = await upgrades.upgradeProxy(invoiceNFTAddress, InvoiceNFTV2);

      const PaymentProcessorV2 = await ethers.getContractFactory("PaymentProcessorV2");
      paymentProcessorV2 = await upgrades.upgradeProxy(paymentProcessorAddress, PaymentProcessorV2);

      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await invoiceNFTV2.connect(creator).createInvoice(
        recipient.address,
        amount,
        ethers.ZeroAddress,
        "Test Invoice",
        dueDate
      );

      const invoiceStats = await invoiceNFTV2.getStatistics();
      expect(invoiceStats[0]).to.equal(1);
      expect(invoiceStats[1]).to.equal(1);

      const userStats = await invoiceNFTV2.getUserStatistics(creator.address);
      expect(userStats.totalAmount).to.equal(amount);
      expect(userStats.invoiceCount).to.equal(1);

      const globalPaymentStats = await paymentProcessorV2.getGlobalStatistics();
      expect(globalPaymentStats.totalPayments).to.equal(0);
    });
  });
});
