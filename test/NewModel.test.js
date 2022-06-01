const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("NalndaMarketplace tests", function () {
    const ZERO_ADDR = "0x0000000000000000000000000000000000000000";
    before(async () => {
        accounts = await ethers.getSigners();
        console.log("deploying new contracts and initializing...");
        //deploy mock token for testing
        const Nalnda = await ethers.getContractFactory("Nalnda");
        nalnda_erc20 = await Nalnda.deploy();
        await nalnda_erc20.deployed();
        const NalndaMarketplace = await ethers.getContractFactory("NalndaMarketplace");
        marketplace = await NalndaMarketplace.deploy(nalnda_erc20.address);
        await marketplace.deployed();
        console.log("done...");
    })
    it("createNewBook(): should revert if address of the author passed is null", async function () {
        await expect(marketplace.createNewBook(ZERO_ADDR, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Author address can't be null!");
    });
    it("createNewBook(): should revert if cover uri passed is empty", async () => {
        await expect(marketplace.createNewBook(accounts[0].address, "", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Empty string passed as cover URI!");
    })
    it("createNewBook(): should revert if _daysForSecondarySales is incorrect", async () => {
        await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("89"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Days to secondary sales should be between 90 and 150!");
    })
    // let newBook;
    // it("createNewBook(): should be able to create a new book, with covers prices at 100 NALNDA", async () => {
    //     try {
    //         await primarySale.createNewBook(accounts[1].address, "test_uri", ethers.utils.parseEther("100"));
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     expect(await primarySale.totalBooksCreated()).to.equal(BigNumber.from("1"));
    // })
    // it("the creation of a new book should have pushed its address to the bookAddresses array", async () => {
    //     newBook = await primarySale.bookAddresses(BigNumber.from("0"));
    //     expect(newBook).to.not.equal(ZERO_ADDR);
    // })
    // it("the creation of a new book should update its author's address in the mapping", async () => {
    //     expect(await primarySale.bookToAuthor(newBook)).to.equal(accounts[1].address);
    // })
    // it("withdrawCommissions(): should revery in case some other account than the owner calls it", async () => {
    //     await expect(primarySale.connect(accounts[5]).withdrawCommissions()).to.revertedWith("Ownable: caller is not the owner")
    // })
    // it("withdrawCommissions(): primary sale contract should get 5 percent commission on first sale", async () => {
    //     const NalndaBook = await ethers.getContractFactory("NalndaBook");
    //     const nalnda_book = await NalndaBook.attach(newBook);
    //     //getting NALNDA tokens for minting new book
    //     let buyer = accounts[3];
    //     await nalnda_erc20.connect(buyer).mint(ethers.utils.parseEther("1000"));
    //     expect(await nalnda_erc20.balanceOf(buyer.address)).to.equal(ethers.utils.parseEther("1000"));
    //     //giving allowance to sales contract and mining new book using 100 NALNDA
    //     try {
    //         await nalnda_erc20.connect(buyer).approve(nalnda_book.address, ethers.utils.parseEther("100"))
    //         await nalnda_book.connect(buyer).safeMint(buyer.address);
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     //now the sales contract should have 5 NALNDA as commission for the sale
    //     expect(await nalnda_erc20.balanceOf(primarySale.address)).to.equal(ethers.utils.parseEther("5"));
    //     //now using withdrawCommission we can withdraw this 5 NALNDA to the account of the owner
    //     const bef = await nalnda_erc20.balanceOf(accounts[0].address)
    //     try {
    //         await primarySale.connect(accounts[0]).withdrawCommissions();
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     const aft = await nalnda_erc20.balanceOf(accounts[0].address)
    //     expect(aft).to.above(bef);
    //     expect(aft.sub(bef)).to.equal(ethers.utils.parseEther("5"));
    // })
});