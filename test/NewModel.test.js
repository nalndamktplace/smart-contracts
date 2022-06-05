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
            await expect(marketplace.createNewBook(ZERO_ADDR, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Author address can't be null!");
        });
        it("createNewBook(): should revert if cover uri passed is empty", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "", ethers.utils.parseEther("1"), BigNumber.from("91"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Empty string passed as cover URI!");
        })
        it("createNewBook(): should revert if _daysForSecondarySales is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("89"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Days to secondary sales should be between 90 and 150!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("151"), BigNumber.from("1"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Days to secondary sales should be between 90 and 150!");
        })
        it("createNewBook(): should revert if _lang is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("0"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Book language tag should be between 1 and 100!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("101"), BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Book language tag should be between 1 and 100!");
        })
        it("createNewBook(): should revert if _genre is out of range", async () => {
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("1"), BigNumber.from("0"))).to.revertedWith("NalndaMarketplace: Book genre tag should be between 1 and 60!");
            await expect(marketplace.createNewBook(accounts[0].address, "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("1"), BigNumber.from("61"))).to.revertedWith("NalndaMarketplace: Book genre tag should be between 1 and 60!");
        })
        it("createNewBook(): should be able to create a new book, with covers prices at 100 NALNDA", async () => {
            try {
                await marketplace.connect(ankit).createNewBook(accounts[1].address, "test_uri", ethers.utils.parseEther("100"), BigNumber.from("92"), BigNumber.from("20"), BigNumber.from("20"));
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
        it("transferFrom(): Should revert of user tries to transfer before set transferAfterDays", async () => {
            await expect(nalnda_book.connect(daksh).transferFrom(daksh.address, ekta.address, BigNumber.from("2"))).to.revertedWith("NalndaBook: Transfer not allowed!");
        })
        let ownedAtBefore;
        it("transferFrom(): Should allow transfer after transferAfterDays and charge fees on the transfer", async () => {
            let befBal, befOwnBal, befMktBal;
            //increasing time
            const twentyOneDays = 21 * 24 * 60 * 60;
            await ethers.provider.send("evm_increaseTime", [twentyOneDays]);
            await ethers.provider.send("evm_mine");
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
        it("safeTransferFrom(): Should revert of user tries to transfer before set transferAfterDays", async () => {
            await expect(nalnda_book.connect(ekta)["safeTransferFrom(address,address,uint256)"](ekta.address, fateh.address, BigNumber.from("2"))).to.revertedWith("NalndaBook: Transfer not allowed!");
        })
        it("safeTransferFrom(): Should transfer and charge fees on every transfer", async () => {
            let befBal, befOwnBal, befMktBal;
            //increasing time
            const twentyOneDays = 21 * 24 * 60 * 60;
            await ethers.provider.send("evm_increaseTime", [twentyOneDays]);
            await ethers.provider.send("evm_mine");
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
    describe('Secondary sales tests: listCover(), unlistCover(), buyCover()', () => {
        it("listCover(): should revert if there are no covers minted yet", async () => {
            await deployContracts();
            try {
                await marketplace.connect(bhuvan).createNewBook(bhuvan.address, "test_uri", ethers.utils.parseEther("100"), BigNumber.from("92"), BigNumber.from("20"), BigNumber.from("20"));
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
        it("listCover(): should revert if listing of book is disabled by owner. (Secondary sales between 3 - 5 months)", async () => {
            await expect(marketplace.connect(lister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Listing for this book is disabled by the book owner!")
        })
        let newLister;
        it("listCover(): should revert if user tries to list book before 21 days of owning", async () => {
            //increasing time
            const days = 92 * 24 * 60 * 60;
            await ethers.provider.send("evm_increaseTime", [days]);
            await ethers.provider.send("evm_mine");
            newLister = gagan;
            await nalnda_erc20.connect(lister).approve(nalnda_book.address, ethers.utils.parseEther("100"));
            await nalnda_book.connect(lister).transferFrom(lister.address, newLister.address, BigNumber.from("1"));
            await expect(marketplace.connect(newLister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("100"))).to.revertedWith("NalndaMarketplace: Can't list the cover at this time!")
        })
        it("listCover(): should allow listing after 21 days of owning", async () => {
            const days = 21 * 24 * 60 * 60;
            await ethers.provider.send("evm_increaseTime", [days]);
            await ethers.provider.send("evm_mine");
            let oldLastId = await marketplace.lastOrderId();
            await marketplace.connect(newLister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("150"));
            // extraBal = await nalnda_erc20.balanceOf(newLister.address);
            order = await marketplace.ORDER(BigNumber.from("1"));
            let newLastId = await marketplace.lastOrderId();
            expect(newLastId).to.above(oldLastId);
            expect(newLastId).to.equal(BigNumber.from("1"));
            //checking if NFT is moved from user's account to marketplace contract
            expect(await nalnda_book.balanceOf(newLister.address)).to.equal(BigNumber.from("0"))
            expect(await nalnda_book.balanceOf(marketplace.address)).to.equal(BigNumber.from("1"))
            expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(marketplace.address)
        })
        it("listCover(): ORDER mapping should be populated correctly", async () => {
            expect(order.stage).to.equal(BigNumber.from("1"));//check stage
            expect(order.orderId).to.equal(BigNumber.from("1"));//check order id
            expect(order.seller).to.equal(newLister.address);//check seller
            expect(order.book).to.equal(newBook1);//check book address
            expect(order.tokenId).to.equal(BigNumber.from("1"));//check tokenId
            expect(order.price).to.equal(ethers.utils.parseEther("150"));//check price
        })
        it("listCover(): ownedAt mapping should be updated correctly", async () => {
            let ownedAtTime = await nalnda_book.ownedAt(BigNumber.from("1"));
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(ownedAtTime).to.equal(block.timestamp);
        })
        it("listCover(): Should revert if user tries to list NFT again", async () => {
            await expect(marketplace.connect(newLister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("150"))).to.revertedWith("NalndaMarketplace: Seller should own the NFT to list!")
        })
        it("unlistCover(): Should revert if invalid order id is provided", async () => {
            await expect(marketplace.connect(newLister).unlistCover(BigNumber.from("2"))).to.revertedWith("NalndaMarketplace: Invalid order id!")
        })
        it("unlistCover(): Should revert if someone other than seller tries to unlist", async () => {
            await expect(marketplace.connect(chitra).unlistCover(BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: Only seller can unlist!")
        })
        it("unlistCover(): Seller should be able to unlist its cover", async () => {
            try {
                await marketplace.connect(newLister).unlistCover(BigNumber.from("1"))
            } catch (err) {
                console.log(err);
            }
            order = await marketplace.ORDER(BigNumber.from("1"));
            //stage should be updated
            expect(order.stage).to.equal(BigNumber.from("0"));
            //checking if NFT is moved from marketplace to user's account
            expect(await nalnda_book.balanceOf(newLister.address)).to.equal(BigNumber.from("1"))
            expect(await nalnda_book.balanceOf(marketplace.address)).to.equal(BigNumber.from("0"))
            expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(newLister.address)
        })
        it("unlistCover(): Should revert if the NFT is already sold", async () => {
            await expect(marketplace.connect(newLister).unlistCover(BigNumber.from("1"))).to.revertedWith("NalndaMarketplace: NFT not yet listed / already sold!")
            order = await marketplace.ORDER(BigNumber.from("1"));
        })
        it("unlistCover(): Stage should be set to UNLISTED", async () => {
            expect(order.stage).to.equal(BigNumber.from("0"));
        })
        it("buyCover(): Should revert if invalid order id is provided", async () => {
            await expect(marketplace.connect(newLister).buyCover(BigNumber.from("2"))).to.revertedWith("NalndaMarketplace: Invalid order id!")
        })
        let balBeforeMarket, balBefore, balBefCreator;
        it("buyCover(): Buyer should be able to buy a listed cover", async () => {
            const days = 21 * 24 * 60 * 60;
            await ethers.provider.send("evm_increaseTime", [days]);
            await ethers.provider.send("evm_mine");
            let buyer = daksh;
            balBeforeMarket = await marketplace.getNALNDABalance();
            balBefore = await nalnda_erc20.balanceOf(order.seller);
            balBefCreator = await nalnda_erc20.balanceOf(bhuvan.address);
            try {
                await marketplace.connect(newLister).listCover(newBook1, BigNumber.from("1"), ethers.utils.parseEther("300"));
                await nalnda_erc20.connect(buyer).mint(ethers.utils.parseEther("300"));
                await nalnda_erc20.connect(buyer).approve(marketplace.address, ethers.utils.parseEther("300"));
                await marketplace.connect(buyer).buyCover(BigNumber.from("2"));
            } catch (err) {
                console.log(err);
            }
            order = await marketplace.ORDER(BigNumber.from("2"));
            //stage should be updated
            expect(order.stage).to.equal(BigNumber.from("2"));
            // checking if NFT is moved from marketplace to buyer's account
            expect(await nalnda_book.balanceOf(buyer.address)).to.equal(BigNumber.from("1"))
            expect(await nalnda_book.balanceOf(marketplace.address)).to.equal(BigNumber.from("0"))
            expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(buyer.address)
        })
        it("buyCover(): Should update the ownerAt mapping correctly", async () => {
            let ownedAtTime = await nalnda_book.ownedAt(BigNumber.from("1"));
            const blockNum = await ethers.provider.getBlockNumber();
            const block = await ethers.provider.getBlock(blockNum)
            expect(ownedAtTime).to.equal(block.timestamp);
        })
        it("buyCover(): Should update the lastSoldPrice mapping correctly", async () => {
            expect(await nalnda_book.lastSoldPrice(BigNumber.from("1"))).to.equal(ethers.utils.parseEther("300"));
        })
        it("buyCover(): Should revert if a cover is already sold", async () => {
            await expect(marketplace.connect(ekta).buyCover(BigNumber.from("2"))).to.revertedWith("NalndaMarketplace: NFT not yet listed / already sold!");
        })
        it("buyCover(): Should have sent correct amount of commissions to the seller, book owner and marketplace", async () => {
            let balAfterMarket = await marketplace.getNALNDABalance();
            let balAfter = await nalnda_erc20.balanceOf(order.seller)
            let balAftCreator = await nalnda_erc20.balanceOf(bhuvan.address);
            //fee collected test 2%
            expect(balAfterMarket.sub(balBeforeMarket)).to.equal(ethers.utils.parseEther("6")) //6 = 2% of 300
            //seller share test 88%
            expect(balAfter.sub(balBefore)).to.equal(ethers.utils.parseEther("264")) //264 = 88% of 300
            //book owner commission 10%
            expect(balAftCreator.sub(balBefCreator)).to.equal(ethers.utils.parseEther("30")); //30 = 10% of 300
        })
        it("withdrawRevenue(): should revery in case some other account than the owner calls it", async () => {
            await expect(marketplace.connect(bhuvan).withdrawRevenue()).to.revertedWith("Ownable: caller is not the owner")
        })
        it("withdrawRevenue(): owner should be able to withdraw its revenue", async () => {
            balBeforeMarket = await marketplace.getNALNDABalance()
            try {
                await marketplace.connect(owner).withdrawRevenue();
            } catch (err) {
                console.log(err);
            }
            let balAfterMarket = await marketplace.getNALNDABalance()
            expect(balAfterMarket).to.equal(BigNumber.from("0"));
            let balNow = await nalnda_erc20.balanceOf(owner.address);
            expect(balNow).to.equal(balBeforeMarket);
        })
        it("renounceOwnership() for a book: Should revert", async () => {
            await expect(nalnda_book.connect(bhuvan).renounceOwnership()).to.revertedWith("Ownership of a book cannot be renounced!")
        })
    })
})