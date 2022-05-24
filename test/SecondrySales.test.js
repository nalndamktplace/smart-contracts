const { expect } = require("chai");
const { BigNumber, providers } = require("ethers");
const { ethers } = require("hardhat");

describe("NalndaBooksSecondarySales tests", function () {
    const ZERO_ADDR = "0x0000000000000000000000000000000000000000";
    before(async () => {
        accounts = await ethers.getSigners();
        console.log("deploying new contracts and initializing...");
        //deploy mock token for testing
        const Nalnda = await ethers.getContractFactory("Nalnda");
        nalnda_erc20 = await Nalnda.deploy();
        await nalnda_erc20.deployed();
        const NalndaBooksPrimarySales = await ethers.getContractFactory("NalndaBooksPrimarySales");
        primarySale = await NalndaBooksPrimarySales.deploy(nalnda_erc20.address);
        await primarySale.deployed();
        const NalndaBooksSecondarySales = await ethers.getContractFactory("NalndaBooksSecondarySales");
        secondarySale = await NalndaBooksSecondarySales.deploy(nalnda_erc20.address);
        await secondarySale.deployed();
        console.log("done...");
    })
    let newBook;
    it("listCover(): should revert if there are no covers minted yet", async () => {
        try {
            await primarySale.createNewBook(accounts[1].address, "test_uri", ethers.utils.parseEther("100"));
        } catch (err) {
            console.log(err);
        }
        newBook = await primarySale.bookAddresses(BigNumber.from("0"));
        //try to list book for 100 NALNDA
        await expect(secondarySale.listCover(newBook, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaBooksSecondarySales: Invalid tokenId provided!")
    })
    it("listCover(): should revert if wrong address is passed", async () => {
        await expect(secondarySale.listCover(ZERO_ADDR, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaBooksSecondarySales: Invalid book address!")
    })
    let order, lister, extraBal, nalnda_book;
    it("listCover(): seller should be able to list its cover", async () => {
        const NalndaBook = await ethers.getContractFactory("NalndaBook");
        nalnda_book = await NalndaBook.attach(newBook);
        lister = accounts[2];
        try {
            //mint some NALNDA
            await nalnda_erc20.connect(lister).mint(ethers.utils.parseEther("1000"));
            //buy a cover to list
            await nalnda_erc20.connect(lister).approve(nalnda_book.address, ethers.utils.parseEther("100"));
            await nalnda_book.connect(lister).safeMint(lister.address);
            //list for sale for 200 NALNDA
            await nalnda_book.connect(lister).setApprovalForAll(secondarySale.address, true);
            await secondarySale.connect(lister).listCover(newBook, BigNumber.from("1"), ethers.utils.parseEther("200"))
        } catch (err) {
            console.log(err);
        }
        extraBal = await nalnda_erc20.balanceOf(lister.address);
        order = await secondarySale.ORDER(BigNumber.from("1"));
        expect(await secondarySale.lastId()).to.equal(BigNumber.from("1"));
    })
    it("listCover(): should revert if the seller does not own the NFT", async () => {
        await expect(secondarySale.listCover(newBook, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaBooksSecondarySales: Seller should own the NFT to list!")
    })
    it("listCover(): ORDER mapping should be populated correctly", async () => {
        expect(order.stage).to.equal(BigNumber.from("1"));//check stage
        expect(order.orderId).to.equal(BigNumber.from("1"));//check order id
        expect(order.seller).to.equal(accounts[2].address);//check seller
        expect(order.book).to.equal(newBook);//check book address
        expect(order.tokenId).to.equal(BigNumber.from("1"));//check tokenId
        expect(order.price).to.equal(ethers.utils.parseEther("200"));//check price
    })
    it("buyCover(): should revert if order id is invalid", async () => {
        await expect(secondarySale.buyCover(BigNumber.from("2"))).to.revertedWith("NalndaBooksSecondarySales: Invalid order id!")
    })
    let theCover, buyer;
    it("buyCover(): should buyer should be able to buy a listed cover", async () => {
        buyer = accounts[4];
        //mint some NALNDA
        try {
            await nalnda_erc20.connect(buyer).mint(ethers.utils.parseEther("1000"));
            await nalnda_erc20.connect(buyer).approve(secondarySale.address, ethers.utils.parseEther("200"));
            await secondarySale.connect(buyer).buyCover(BigNumber.from("1"));
        } catch (err) {
            console.log(err);
        }
        //check if cover is sold
        theCover = await secondarySale.ORDER(BigNumber.from("1"));
        expect(theCover.stage).to.equal(BigNumber.from("2"));
        expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(buyer.address);//ownership check
    })
    it("buyCover(): should revert if someone tries to buy the cover again", async () => {
        const newBuyer = accounts[5];
        await expect(secondarySale.connect(newBuyer).buyCover(BigNumber.from("1"))).to.revertedWith("NalndaBooksSecondarySales: NFT not yet listed / already sold!")
    })
    it("buyCover(): testing for author's share (10%)", async () => {
        // 10% of sale price
        const expected = (ethers.utils.parseEther("200").mul(BigNumber.from("10"))).div(BigNumber.from("100"));
        let bal = await nalnda_erc20.balanceOf(await primarySale.bookToAuthor(newBook));
        expect(expected).to.equal(bal.sub(ethers.utils.parseEther("95"))); //subtracting revenue from selling first book 95% of 100 NALNDA
    })
    it("buyCover(): testing for protocol fee (2%)", async () => {
        // 2% of sale price
        const expected = (ethers.utils.parseEther("200").mul(BigNumber.from("2"))).div(BigNumber.from("100"));
        expect(expected).to.equal(await nalnda_erc20.balanceOf(secondarySale.address));
    })
    it("buyCover(): testing for sellers share (88%)", async () => {
        //remaining = 88% = 100% - 10% - 2%
        const expected = (ethers.utils.parseEther("200").mul(BigNumber.from("88"))).div(BigNumber.from("100"));
        let bal = await nalnda_erc20.balanceOf(lister.address);
        expect(expected).to.equal(bal.sub(extraBal)); //subtracting extra NALNDA from the calculations
    })
    it("unlistCover(): should revert if invalid order id is provided", async () => {
        await expect(secondarySale.unlistCover(BigNumber.from("2"))).to.revertedWith("NalndaBooksSecondarySales: Invalid order id!")
    })
    it("unlistCover(): should revert if order not in LISTED stage", async () => {
        await expect(secondarySale.unlistCover(BigNumber.from("1"))).to.revertedWith("NalndaBooksSecondarySales: NFT not yet listed / already sold!")
    })
    let newLister;
    it("unlistCover(): should revert if anyone other than seller tries to unlist", async () => {
        //listing new book
        const NalndaBook = await ethers.getContractFactory("NalndaBook");
        nalnda_book = await NalndaBook.attach(newBook);
        newLister = buyer; //old buyer
        try {
            //list for sale for 200 NALNDA
            await nalnda_book.connect(newLister).setApprovalForAll(secondarySale.address, true);
            await secondarySale.connect(newLister).listCover(newBook, BigNumber.from("1"), ethers.utils.parseEther("200"))
        } catch (err) {
            console.log(err);
        }
        expect(await secondarySale.lastId()).to.equal(BigNumber.from("2"));
        //testing the test case
        await expect(secondarySale.connect(accounts[7]).unlistCover(BigNumber.from("2"))).to.revertedWith("NalndaBooksSecondarySales: Only seller can unlist!")
    })
    it("unlistCover(): seller should be able to unlist its cover", async () => {
        const balBef = await nalnda_book.balanceOf(newLister.address);
        try {
            await secondarySale.connect(newLister).unlistCover(BigNumber.from("2"));
        } catch (err) {
            console.log(err);
        }
        const balAft = await nalnda_book.balanceOf(newLister.address);
        expect(balAft).to.above(balBef);
        expect(balAft).to.equal(BigNumber.from("1"))
    })
    it("unlistCover(): should revert if seller tries to unlist again", async () => {
        await expect(secondarySale.connect(newLister).unlistCover(BigNumber.from("2"))).to.revertedWith("NalndaBooksSecondarySales: NFT not yet listed / already sold!")
    })
    it("unlistCover(): should update the stage of the order correctly", async () => {
        let newOrder = await secondarySale.ORDER(BigNumber.from("2"));
        expect(newOrder.stage).to.equal(BigNumber.from("0"));
    })
    it("withdrawRevenue(): should revery in case some other account than the owner calls it", async () => {
        await expect(secondarySale.connect(accounts[6]).withdrawRevenue()).to.revertedWith("Ownable: caller is not the owner")
    })
    it("withdrawRevenue(): owner should be able to withdraw its revenue", async () => {
        let balBeforeSecondarySale = await nalnda_erc20.balanceOf(secondarySale.address);
        try {
            await secondarySale.connect(accounts[0]).withdrawRevenue();
        } catch (err) {
            console.log(err);
        }
        let balAfterSecondarySale = await nalnda_erc20.balanceOf(secondarySale.address);
        expect(balAfterSecondarySale).to.equal(BigNumber.from("0"));
        let bal = await nalnda_erc20.balanceOf(accounts[0].address);
        expect(bal).to.equal(balBeforeSecondarySale);
    })
});