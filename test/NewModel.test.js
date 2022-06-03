const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");

describe("NalndaMarketplace tests", function () {
    const ZERO_ADDR = "0x0000000000000000000000000000000000000000";
    async function deployContracts() {
        console.log("deploying new contracts and initializing...");
        //deploy mock token for testing
        const Nalnda = await ethers.getContractFactory("Nalnda");
        nalnda_erc20 = await Nalnda.deploy();
        await nalnda_erc20.deployed();
        const NalndaMarketplace = await ethers.getContractFactory("NalndaMarketplace");
        marketplace = await NalndaMarketplace.deploy(nalnda_erc20.address);
        await marketplace.deployed();
        console.log("done...");
    }
    before(async () => {
        accounts = await ethers.getSigners();
        [
            owner,
            ankit, bhuvan, chitra, daksh, ekta, fateh, gagan, hari, isha,
            defaulter_1, defaulter_2, defaulter_3, defaulter_4,
            A, B, C, D, E, USDAO_whale] = accounts;
        await deployContracts();
    })
    let newBook;
    describe('Creating new book:', () => {
        it("createNewBook(): should revert if address of the author passed is null", async function () {
            await expect(marketplace.createNewBook(ZERO_ADDR, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Author address can't be null!");
        });
        it("createNewBook(): should revert if cover uri passed is empty", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Empty string passed as cover URI!");
        })
        it("createNewBook(): should revert if _daysForSecondarySales is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("89"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Days to secondary sales should be between 90 and 150!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("151"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Days to secondary sales should be between 90 and 150!");
        })
        it("createNewBook(): should revert if _lang is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("0"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Book language tag should be between 1 and 100!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("101"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Book language tag should be between 1 and 100!");
        })
        it("createNewBook(): should revert if _genre is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("1"), BigNumber.from("0"))).to.revertedWith("NalndaMarketplace: Book genre tag should be between 1 and 60!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("1"), BigNumber.from("61"))).to.revertedWith("NalndaMarketplace: Book genre tag should be between 1 and 60!");
        })
        it("createNewBook(): should be able to create a new book, with covers prices at 100 NALNDA", async () => {
            try {
                await marketplace.connect(ankit).createNewBook(accounts[1].address, "test_uri", ethers.utils.parseEther("100"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("20"), BigNumber.from("20"));
            } catch (err) {
                console.log(err);
            }
            expect(await marketplace.totalBooksCreated()).to.equal(BigNumber.from("1"));
        })
        it("the creation of a new book should have pushed its address to the bookAddresses array", async () => {
            newBook = await marketplace.bookAddresses(BigNumber.from("0"));
            expect(newBook).to.not.equal(ZERO_ADDR);
        })
        it("the creation of a new book should update its author's address in the mapping", async () => {
            expect(await marketplace.bookToAuthor(newBook)).to.equal(accounts[1].address);
        })
    })
    let nalnda_book;
    describe('Primary sale/lazy mint, transfer fees and burn tests:', () => {
        it("ownerMint(): should revert if someone other than the owner tries to mint", async () => {
            const NalndaBook = await ethers.getContractFactory("NalndaBook");
            nalnda_book = await NalndaBook.attach(newBook);
            await expect(nalnda_book.connect(chitra).ownerMint(ankit.address)).to.revertedWith("Ownable: caller is not the owner");
        })
        let bef;
        it("ownerMint(): Owner should be able to mint its own book cover for free", async () => {
            bef = await nalnda_book.ownedAt(BigNumber.from("1"));
            expect(bef).to.equal(BigNumber.from("0"));
            try {
                await nalnda_book.connect(ankit).ownerMint(ankit.address);
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.balanceOf(ankit.address)).to.equal(BigNumber.from("1"));
            expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(ankit.address);
        })
        it("ownerMint(): Mint should have updated the ownedAt mapping timestamp", async () => {
            let aft = await nalnda_book.ownedAt(BigNumber.from("1"));
            expect(aft).to.above(bef);
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(aft).to.equal(block.timestamp);
        })
        it("safeMint(): Anyone should be able to buy a cover by paying NALNDA", async () => {
            try {
                await nalnda_erc20.connect(daksh).mint(ethers.utils.parseEther("100"));
                await nalnda_erc20.connect(daksh).approve(newBook, ethers.utils.parseEther("100"));
                await nalnda_book.connect(daksh).safeMint(daksh.address);
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.ownerOf(BigNumber.from("2"))).to.equal(daksh.address);
            expect(await nalnda_erc20.balanceOf(daksh.address)).to.equal(BigNumber.from("0"));
        })
        it("safeMint(): Should have sent the protocol fee to the marketplace contract and the rest amount to the book owner", async () => {
            // expect(await nalnda_erc20.balanceOf(nalnda_book.address))
            let sellerCollected = await nalnda_erc20.balanceOf(ankit.address);
            expect(sellerCollected).to.equal(ethers.utils.parseEther("90"))//90%
            let feeCollected = await nalnda_erc20.balanceOf(marketplace.address);
            expect(feeCollected).to.equal(ethers.utils.parseEther("10"))//10%
            expect(sellerCollected.add(feeCollected)).to.equal(ethers.utils.parseEther("100"));
        })
        it("safeMint(): Mint should have updated the ownedAt mapping timestamp", async () => {
            let ownedAt = await nalnda_book.ownedAt(BigNumber.from("2"));
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(ownedAt).to.equal(block.timestamp);
        })
        it("safeMint(): Mint should have updated the lastSoldPrice mapping correctly", async () => {
            expect(await nalnda_book.lastSoldPrice(BigNumber.from("2"))).to.equal(ethers.utils.parseEther("100"));
        })
        let ownedAtBefore;
        it("transferFrom(): Should transfer and charge fees on every transfer", async () => {
            let befBal, befOwnBal, befMktBal;
            try {
                //minting some NALNDA for transfer fee
                await nalnda_erc20.connect(daksh).mint(ethers.utils.parseEther("100"));
                await nalnda_erc20.connect(daksh).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                befBal = await nalnda_erc20.balanceOf(daksh.address);
                befOwnBal = await nalnda_erc20.balanceOf(ankit.address);
                befMktBal = await nalnda_erc20.balanceOf(marketplace.address);
                ownedAtBefore = await nalnda_book.ownedAt(BigNumber.from("2"));
                // transfer the cover
                await nalnda_book.connect(daksh).transferFrom(daksh.address, ekta.address, BigNumber.from("2"));
            } catch (err) {
                console.log(err);
            }
            let aftBal = await nalnda_erc20.balanceOf(daksh.address);
            expect(aftBal).to.below(befBal);
            //10% to the book owner
            let aftOwnBal = await nalnda_erc20.balanceOf(ankit.address);
            expect(aftOwnBal).to.above(befOwnBal);
            expect(aftOwnBal.sub(befOwnBal)).to.equal(ethers.utils.parseEther("10"))
            //2% to the marketplace contract as a protocol fee
            let aftMktBal = await nalnda_erc20.balanceOf(marketplace.address);
            expect(aftMktBal.sub(befMktBal)).to.equal(ethers.utils.parseEther("2"))
        })
        it("transferFrom(): should have updated the ownedAt mapping", async () => {
            let ownedAtLater = await nalnda_book.ownedAt(BigNumber.from("2"));
            expect(ownedAtLater).to.above(ownedAtBefore);
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(ownedAtLater).to.equal(block.timestamp);
        })
        it("safeTransferFrom(): Should transfer and charge fees on every transfer", async () => {
            let befBal, befOwnBal, befMktBal;
            try {
                //minting some NALNDA for transfer fee
                await nalnda_erc20.connect(ekta).mint(ethers.utils.parseEther("100"));
                await nalnda_erc20.connect(ekta).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                befBal = await nalnda_erc20.balanceOf(ekta.address);
                befOwnBal = await nalnda_erc20.balanceOf(ankit.address);
                befMktBal = await nalnda_erc20.balanceOf(marketplace.address);
                ownedAtBefore = await nalnda_book.ownedAt(BigNumber.from("2"));
                // transfer the cover
                await nalnda_book.connect(ekta)["safeTransferFrom(address,address,uint256)"](ekta.address, fateh.address, BigNumber.from("2"));
            } catch (err) {
                console.log(err);
            }
            let aftBal = await nalnda_erc20.balanceOf(ekta.address);
            expect(aftBal).to.below(befBal);
            //10% to the book owner
            let aftOwnBal = await nalnda_erc20.balanceOf(ankit.address);
            expect(aftOwnBal).to.above(befOwnBal);
            expect(aftOwnBal.sub(befOwnBal)).to.equal(ethers.utils.parseEther("10"))
            //2% to the marketplace contract as a protocol fee
            let aftMktBal = await nalnda_erc20.balanceOf(marketplace.address);
            expect(aftMktBal.sub(befMktBal)).to.equal(ethers.utils.parseEther("2"))
        })
        it("transferFrom(): should have updated the ownedAt mapping", async () => {
            let ownedAtLater = await nalnda_book.ownedAt(BigNumber.from("2"));
            expect(ownedAtLater).to.above(ownedAtBefore);
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(ownedAtLater).to.equal(block.timestamp);
        })
        it("burn(): Owner should be able to burn its NFT", async () => {
            try {
                await nalnda_book.connect(ankit).burn(BigNumber.from("1"));
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.balanceOf(ankit.address)).to.equal(BigNumber.from("0"));
            await expect(nalnda_book.ownerOf(BigNumber.from("1"))).to.revertedWith("ERC721: owner query for nonexistent token");
        })
        it("burn(): Should have set the ownedAt timestamp to 0", async () => {
            expect(await nalnda_book.ownedAt(BigNumber.from("1"))).to.equal(BigNumber.from("0"));
        })
    })
    let newBook1;
    describe('Secondary sales tests:', () => {
        it("listCover(): should revert if there are no covers minted yet", async () => {
            await deployContracts();
            try {
                await marketplace.connect(bhuvan).createNewBook(bhuvan.address, "test_uri", ethers.utils.parseEther("100"), BigNumber.from("10"), BigNumber.from("92"), BigNumber.from("20"), BigNumber.from("20"));
            } catch (err) {
                console.log(err);
            }
            newBook1 = await marketplace.bookAddresses(BigNumber.from("0"));
            //try to list book for 100 NALNDA
            await expect(marketplace.listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Invalid tokenId provided!")
        })
        it("listCover(): should revert if wrong address is passed", async () => {
            await expect(marketplace.listCover(ZERO_ADDR, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Invalid book address!")
        })
        let order, lister, extraBal, nalnda_book;
        it("listCover(): should revert if lister does not own the NFT", async () => {
            const NalndaBook = await ethers.getContractFactory("NalndaBook");
            nalnda_book = await NalndaBook.attach(newBook1);
            lister = ankit;
            try {
                //mint some NALNDA
                await nalnda_erc20.connect(lister).mint(ethers.utils.parseEther("1000"));
                //buy a cover to list
                await nalnda_erc20.connect(lister).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                await nalnda_book.connect(lister).safeMint(lister.address);
            } catch (err) {
                console.log(err);
            }
            // const blockNum = await ethers.provider.getBlockNumber();
            // const block = await ethers.provider.getBlock(blockNum)
            // console.log(await nalnda_book.secondarySalesTimestamp(), block.timestamp);
            await expect(marketplace.listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Seller should own the NFT to list!")
        })
        it("listCover(): should revert if listing of book is disabled by owner. Between 3 - 5 months", async () => {
            await expect(marketplace.connect(lister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Listing for this book is disabled by the book owner!")
        })
    })
})