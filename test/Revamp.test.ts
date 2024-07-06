import { expect } from "chai";
import { ethers } from "hardhat";
import { MockUSDT, NalndaMarketplace } from "../typechain-types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("MarketplaceNonCustodial test cases", () => {
  let owner: SignerWithAddress,
    bookCreator: SignerWithAddress,
    A: SignerWithAddress,
    B: SignerWithAddress,
    C: SignerWithAddress,
    D: SignerWithAddress,
    E: SignerWithAddress,
    F: SignerWithAddress;
  let ZERO_ADDR: string;
  let marketplace: NalndaMarketplace;
  let usdt: MockUSDT;

  before(async () => {
    [owner, bookCreator, A, B, C, D, E, F] = await ethers.getSigners();
    ZERO_ADDR = ethers.constants.AddressZero;
    const USDT = await ethers.getContractFactory("MockUSDT");
    usdt = await USDT.deploy();
    await usdt.deployed();

    const NalndaMarketplace = await ethers.getContractFactory(
      "NalndaMarketplace"
    );
    marketplace = await NalndaMarketplace.deploy(
      usdt.address,
      owner.address,
      bookCreator.address
    );
    await marketplace.deployed();
  });
  it("Deployments and Initilizations successful", async () => {
    expect(marketplace.address).to.not.equal(ZERO_ADDR);
    expect(usdt.address).to.not.equal(ZERO_ADDR);
    expect(await marketplace.owner()).to.equal(owner.address);
    expect(await marketplace.purchaseToken()).to.equal(usdt.address);
  });

  describe("Creating new book:", () => {
    it("createNewBook(): should revert if address of the author passed is null", async function () {
      await expect(
        marketplace
          .connect(bookCreator)
          .createNewBook(
            ZERO_ADDR,
            "test_uri",
            ethers.utils.parseEther("1"),
            "91",
            "1",
            ["1", "3"]
          )
      ).to.revertedWith("NalndaMarketplace: Author address can't be null!");
    });
    it("createNewBook(): should revert if cover uri passed is empty", async () => {
      await expect(
        marketplace
          .connect(bookCreator)
          .createNewBook(
            A.address,
            "",
            ethers.utils.parseEther("1"),
            "91",
            "1",
            ["1", "3"]
          )
      ).to.revertedWith("NalndaMarketplace: Empty string passed as cover URI!");
    });

    let bookAddress: string;
    it("Test airdrop", async () => {
      bookAddress = await marketplace.computeNextBookAddress(
        A.address,
        "test_uri",
        ethers.utils.parseUnits("10", 6),
        "91",
        "1",
        ["1", "3"]
      );
      await marketplace
        .connect(bookCreator)
        .createNewBook(
          A.address,
          "test_uri",
          ethers.utils.parseUnits("10", 6),
          "91",
          "1",
          ["1", "3"]
        );

      const book = await ethers.getContractAt("NalndaBook", bookAddress);
      expect(await book.owner()).to.equal(A.address);

      const airdrop = await ethers.getContractAt(
        "NalndaAirdrop",
        await book.airdrop()
      );

      const nalndaToken = await ethers.getContractAt(
        "NalndaToken",
        await airdrop.nalndaToken()
      );
      console.log(
        "Balance of Airdrop(Before): ",
        await nalndaToken.balanceOf(await book.airdrop())
      );

      await usdt.connect(owner).mint(ethers.utils.parseUnits("100", 6));
      await usdt
        .connect(owner)
        .transfer(A.address, ethers.utils.parseUnits("10", 6));
      expect(await usdt.balanceOf(A.address)).to.equal(
        ethers.utils.parseUnits("10", 6)
      );
      await usdt
        .connect(A)
        .approve(book.address, ethers.utils.parseUnits("10", 6));

      await book.connect(A).safeMint(B.address);

      console.log(
        "Balance of Airdrop(After): ",
        await nalndaToken.balanceOf(await book.airdrop())
      );
    });
  });
});
