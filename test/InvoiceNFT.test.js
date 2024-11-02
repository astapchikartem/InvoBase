const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");

describe("InvoiceNFT", function () {
  let invoiceNFT;
  let owner, creator, recipient;

  beforeEach(async function () {
    [owner, creator, recipient] = await ethers.getSigners();

    const InvoiceNFT = await ethers.getContractFactory("InvoiceNFT");
    invoiceNFT = await upgrades.deployProxy(
      InvoiceNFT,
      [owner.address],
      { initializer: "initialize", kind: "uups" }
    );
    await invoiceNFT.waitForDeployment();
  });

  describe("Initialization", function () {
    it("Should set the correct name and symbol", async function () {
      expect(await invoiceNFT.name()).to.equal("InvoBase Invoice");
      expect(await invoiceNFT.symbol()).to.equal("INVB");
    });

    it("Should grant roles to owner", async function () {
      const DEFAULT_ADMIN_ROLE = await invoiceNFT.DEFAULT_ADMIN_ROLE();
      expect(await invoiceNFT.hasRole(DEFAULT_ADMIN_ROLE, owner.address)).to.be.true;
    });
  });

  describe("Invoice Creation", function () {
    it("Should create a new invoice", async function () {
      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await expect(
        invoiceNFT.connect(creator).createInvoice(
          recipient.address,
          amount,
          ethers.ZeroAddress,
          "Test Invoice",
          dueDate
        )
      ).to.emit(invoiceNFT, "InvoiceCreated");

      expect(await invoiceNFT.ownerOf(1)).to.equal(creator.address);
    });

    it("Should revert with zero amount", async function () {
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await expect(
        invoiceNFT.connect(creator).createInvoice(
          recipient.address,
          0,
          ethers.ZeroAddress,
          "Test Invoice",
          dueDate
        )
      ).to.be.revertedWithCustomError(invoiceNFT, "InvalidAmount");
    });

    it("Should revert with invalid recipient", async function () {
      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      await expect(
        invoiceNFT.connect(creator).createInvoice(
          ethers.ZeroAddress,
          amount,
          ethers.ZeroAddress,
          "Test Invoice",
          dueDate
        )
      ).to.be.revertedWithCustomError(invoiceNFT, "InvalidRecipient");
    });
  });

  describe("Invoice Management", function () {
    let tokenId;

    beforeEach(async function () {
      const amount = ethers.parseEther("1.0");
      const dueDate = Math.floor(Date.now() / 1000) + 86400;
      
      const tx = await invoiceNFT.connect(creator).createInvoice(
        recipient.address,
        amount,
        ethers.ZeroAddress,
        "Test Invoice",
        dueDate
      );
      tokenId = 1;
    });

    it("Should retrieve invoice details", async function () {
      const invoice = await invoiceNFT.getInvoice(tokenId);
      expect(invoice.creator).to.equal(creator.address);
      expect(invoice.recipient).to.equal(recipient.address);
      expect(invoice.status).to.equal(0);
    });

    it("Should cancel invoice by creator", async function () {
      await expect(
        invoiceNFT.connect(creator).cancelInvoice(tokenId)
      ).to.emit(invoiceNFT, "InvoiceCancelled");

      const invoice = await invoiceNFT.getInvoice(tokenId);
      expect(invoice.status).to.equal(2);
    });
  });
});
