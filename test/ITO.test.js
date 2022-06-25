const { expect } = require("chai");
const { BigNumber } = require("ethers");
const { ethers } = require("hardhat");
var crypto = require('crypto');

describe("ITO tests", function () {
    const ZERO_ADDR = "0x0000000000000000000000000000000000000000";
    const MAX_UINT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";
    async function deployContracts() {
        console.log("Deploying new contracts and initializing...");
        //deploy mock token for testing
        const Nalnda = await ethers.getContractFactory("Nalnda");
        nalnda_erc20 = await Nalnda.deploy();
        await nalnda_erc20.deployed();
        const NalndaMaster = await ethers.getContractFactory("NalndaMaster");
        master = await NalndaMaster.deploy(nalnda_erc20.address);
        const NalndaMarketplaceITO = await ethers.getContractFactory("NalndaMarketplaceITO");
        marketplace = await NalndaMarketplaceITO.attach(await master.ITOMarketplace());
        await marketplace.deployed();
        console.log("done...");
    }
    before(async () => {
        accounts = await ethers.getSigners();
        [
            owner,
            ankit, bhuvan, chitra, daksh, ekta, fateh, gagan, hari, isha,
            jatin, kritika, lohit, mahesh,
            A, B, C, D, E, USDAO_whale] = accounts;
        await deployContracts();
    })
    let newBook;
    describe('Creating new book and ITO stage checks:', () => {
        it("createNewITOBook(): should revert if address of the author passed is null", async function () {
            await expect(master.createNewITOBook(ZERO_ADDR, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("91"), BigNumber.from("1"), ['1', '3'])).to.revertedWith("NalndaMaster: Author address can't be null!");
        });
        it("createNewITOBook(): should revert if total ito owners is not between 500 and 1000", async function () {
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("200"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("91"), BigNumber.from("1"), ['1', '3'])).to.revertedWith("NalndaITOBook: Total distributed owners should be between 500 and 1000!");
        });
        it("createNewITOBook(): should revert if cover uri passed is empty", async () => {
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "", ethers.utils.parseEther("1"), BigNumber.from("91"), BigNumber.from("1"), ['1', '3'])).to.revertedWith("NalndaMaster: Empty string passed as cover URI!");
        })
        it("createNewITOBook(): should revert if _daysForSecondarySales is out of range", async () => {
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("89"), BigNumber.from("1"), ['1', '3'])).to.revertedWith("NalndaMaster: Days to secondary sales should be between 90 and 150!");
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("151"), BigNumber.from("1"), ['1', '3'])).to.revertedWith("NalndaMaster: Days to secondary sales should be between 90 and 150!");
        })
        it("createNewITOBook(): should revert if _lang is out of range", async () => {
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("0"), ['1', '3'])).to.revertedWith("NalndaMaster: Book language tag should be between 1 and 100!");
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("101"), ['1', '3'])).to.revertedWith("NalndaMaster: Book language tag should be between 1 and 100!");
        })
        it("createNewITOBook(): should revert if _genre is out of range", async () => {
            await expect(master.createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("1"), BigNumber.from("92"), BigNumber.from("1"), ['0', '61'])).to.revertedWith("NalndaMaster: Book genre tag should be between 1 and 60!");
        })
        it("createNewITOBook(): should be able to create a new book, with covers prices at 100 NALNDA", async () => {
            try {
                await master.connect(ankit).createNewITOBook(ankit.address, BigNumber.from("500"), "test_uri", ethers.utils.parseEther("100"), BigNumber.from("92"), BigNumber.from("20"), ['1', '3']);
            } catch (err) {
                console.log(err);
            }
            expect(await master.totalBooksCreated()).to.equal(BigNumber.from("1"));
            newBook = await master.authorToBooks(ankit.address, BigNumber.from("0"));
        })
        it("bookOwner(): Should return the address of the author", async () => {
            expect(await master.bookOwner(newBook)).to.equal(ankit.address);
        })
        it("safeMintITO(): Should revert if ITO not started yet", async () => {
            const NalndaITOBook = await ethers.getContractFactory("NalndaITOBook");
            nalnda_book = await NalndaITOBook.attach(newBook);
            await expect(nalnda_book.connect(bhuvan).safeMintITO()).to.revertedWith("NalndaITOBook: ITO not started/already ended!");
        })
        it("startSalesTransfersManuallyITO(): Should revert if ito stage not started yet", async () => {
            await expect(master.connect(owner).startSalesTransfersManuallyITO(nalnda_book.address)).to.revertedWith("NalndaITOBook: ITO not started/already ended!");
        })
        it("approveBookStartITO(): Approve a book and start the ITO", async () => {
            let approvedAddresses1 = [];
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("0")); //ITO not started
            //will add 2500 addresses to approvedAddresses
            //generate 450 approvedAddresses - because of gas limit issue we have to do multiple transactions
            for (let i = 5; i < 455; i++) {
                approvedAddresses1.push(accounts[i].address);
            }
            try {
                await master.connect(owner).approveBookStartITO(newBook, approvedAddresses1);
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("1")); //ITO started
            let approvedAddresses2 = [];
            // have to add 450 more addresses using addMoreApprovedAddresses
            for (let i = approvedAddresses1.length; i < approvedAddresses1.length + 450; i++) {
                approvedAddresses2.push(accounts[i].address);
            }
            let approvedAddresses3 = [];
            for (let i = approvedAddresses2.length; i < approvedAddresses2.length + 450; i++) {
                approvedAddresses3.push(accounts[i].address);
            }
            let approvedAddresses4 = [];
            for (let i = approvedAddresses3.length; i < approvedAddresses3.length + 450; i++) {
                approvedAddresses4.push(accounts[i].address);
            }
            let approvedAddresses5 = [];
            for (let i = approvedAddresses4.length; i < approvedAddresses4.length + 450; i++) {
                approvedAddresses5.push(accounts[i].address);
            }
            let approvedAddresses6 = [];
            for (let i = approvedAddresses5.length; i < approvedAddresses5.length + 250; i++) {
                approvedAddresses6.push(accounts[i].address);
            }
            try {
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, approvedAddresses2);
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, approvedAddresses3);
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, approvedAddresses4);
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, approvedAddresses5);
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, approvedAddresses6);
                let ownAddresses = [];
                ownAddresses.push(bhuvan.address);
                ownAddresses.push(chitra.address);
                ownAddresses.push(daksh.address);
                await master.connect(owner).addMoreApprovedAddressesITO(newBook, ownAddresses);
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("1")); //checking ITO stage again
        })
        it("startSalesTransfersManuallyITO(): Should revert if no one has claimed during ITO", async () => {
            await expect(master.connect(owner).startSalesTransfersManuallyITO(nalnda_book.address)).to.revertedWith("NalndaITOBook: Can't start sales and transfers in case of 0 DOs!");
        })
        it("safeMintITO(): Should revert if some non approved address tries to mint during ITO", async () => {
            await expect(nalnda_book.connect(accounts[2999]).safeMintITO()).to.revertedWith("NalndaITOBook: You are not approved for ITO mint!");
        })
        it("safeMintITO(): Should allow minting during ITO for approved addresses", async () => {
            try {
                await nalnda_erc20.connect(bhuvan).mint(ethers.utils.parseEther("100"));
                await nalnda_erc20.connect(bhuvan).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                await nalnda_book.connect(bhuvan).safeMintITO();
            } catch (err) {
                console.log(err);
            }
            try {
                await nalnda_erc20.connect(chitra).mint(ethers.utils.parseEther("100"));
                await nalnda_erc20.connect(chitra).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                await nalnda_book.connect(chitra).safeMintITO();
            } catch (err) {
                console.log(err);
            }
            expect(await nalnda_book.DistributedOwners(BigNumber.from("0"))).to.equal(bhuvan.address);
            expect(await nalnda_book.isDO(bhuvan.address)).to.equal(true);
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("1")); //checking ITO stage again
            expect(await nalnda_book.startNormalSalesTransfers()).to.equal(false);
            expect(await nalnda_book.secondarySalesTimestamp()).to.equal(MAX_UINT);
            expect(await nalnda_book.DistributedOwners(BigNumber.from("1"))).to.equal(chitra.address);
            expect(await nalnda_book.isDO(chitra.address)).to.equal(true);
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("1")); //checking ITO stage again
            expect(await nalnda_book.startNormalSalesTransfers()).to.equal(false);
            expect(await nalnda_book.secondarySalesTimestamp()).to.equal(MAX_UINT);
        })
        it("safeMintITO(): Should revert if already claimed address tries to mint again", async () => {
            await expect(nalnda_book.connect(bhuvan).safeMintITO()).to.revertedWith("NalndaITOBook: You can only mint one time during ITO!");
        })
        it("pause() and unpause(): Should revert if ITO stage is going on", async () => {
            await expect(nalnda_book.connect(ankit).pause()).to.revertedWith("NalndaITOBook: Sales and transfers not started yet/already stopped!");
            await expect(nalnda_book.connect(ankit).unpause()).to.revertedWith("NalndaITOBook: Sales and transfers not started yet/already stopped!");
        })
        it("Commission distribution should be done correctly", async () => {
            //20% to the protocol
            expect(await nalnda_erc20.balanceOf(master.address)).to.equal(ethers.utils.parseEther("40")); // 20% of 200 NALNDA (2 book sales)
            //80% to the book owner
            expect(await nalnda_erc20.balanceOf(ankit.address)).to.equal(ethers.utils.parseEther("160")); // 80% of 200 NALNDA (2 book sales)
        })
        it("Sales should start automatically after all 500 are done minting", async () => {
            //2 have already minting so need 498 mints to end ITO
            console.log("498 approved addresses minting: This will take some time please hold on ...");
            for (let i = 5; i < 503; i++) { //503-5 = 498
                try {
                    await nalnda_erc20.connect(accounts[i]).mint(ethers.utils.parseEther("100"));
                    await nalnda_erc20.connect(accounts[i]).approve(nalnda_book.address, ethers.utils.parseEther("100"));
                    await nalnda_book.connect(accounts[i]).safeMintITO();
                } catch (err) {
                    console.log(err);
                }
            }
            expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("2")); //ITO should be ended
            expect(await nalnda_book.startNormalSalesTransfers()).to.equal(true);
            expect(await nalnda_book.secondarySalesTimestamp()).to.not.equal(MAX_UINT);
        })
        it("startSalesTransfersManuallyITO(): Should revert if someone other than master owner tries to startSalesTransfersManuallyITO", async () => {
            await expect(master.connect(ankit).startSalesTransfersManuallyITO(nalnda_book.address)).to.revertedWith("Ownable: caller is not the owner");
        })
        // it("startSalesTransfersManuallyITO(): Master owner should be able to start sales transfers manually", async () => {
        //     try {
        //         await master.connect(owner).startSalesTransfersManuallyITO(nalnda_book.address);
        //     } catch (err) {
        //         console.log(err);
        //     }
        //     expect(await nalnda_book.currentITOStage()).to.equal(BigNumber.from("2")); //ITO should be ended
        //     expect(await nalnda_book.startNormalSalesTransfers()).to.equal(true);
        //     expect(await nalnda_book.secondarySalesTimestamp()).to.not.equal(MAX_UINT);
        // })
    })
    // let nalnda_book;
    // describe('Primary sale/lazy mint, transfer fees and burn tests:', () => {
    // it("ownerMint(): should revert if owner tried to call before normal minting is started", async () => {
    //     const NalndaITOBook = await ethers.getContractFactory("NalndaITOBook");
    //     nalnda_book = await NalndaITOBook.attach(newBook);
    //     await expect(nalnda_book.connect(ankit).ownerMint(ankit.address)).to.revertedWith("NalndaITOBook: Sales and transfers not started yet/already stopped!");
    // })
    // it("ownerMint(): should revert if someone other than the owner tries to mint", async () => {
    //     const NalndaITOBook = await ethers.getContractFactory("NalndaITOBook");
    //     nalnda_book = await NalndaITOBook.attach(newBook);
    //     await expect(nalnda_book.connect(chitra).ownerMint(ankit.address)).to.revertedWith("Ownable: caller is not the owner");
    // })
    // let bef;
    // it("ownerMint(): Owner should be able to mint its own book cover for free", async () => {
    //     bef = await nalnda_book.ownedAt(BigNumber.from("1"));
    //     expect(bef).to.equal(BigNumber.from("0"));
    //     try {
    //         await nalnda_book.connect(ankit).ownerMint(ankit.address);
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     expect(await nalnda_book.balanceOf(ankit.address)).to.equal(BigNumber.from("1"));
    //     expect(await nalnda_book.ownerOf(BigNumber.from("1"))).to.equal(ankit.address);
    // })
    // it("ownerMint(): Mint should have updated the ownedAt mapping timestamp", async () => {
    //     let aft = await nalnda_book.ownedAt(BigNumber.from("1"));
    //     expect(aft).to.above(bef);
    //     const blockNum = await ethers.provider.getBlockNumber();
    //     const block = await ethers.provider.getBlock(blockNum)
    //     expect(aft).to.equal(block.timestamp);
    // })
    // it("safeMint(): Anyone should be able to buy a cover by paying NALNDA", async () => {
    //     try {
    //         await nalnda_erc20.connect(daksh).mint(ethers.utils.parseEther("100"));
    //         await nalnda_erc20.connect(daksh).approve(newBook, ethers.utils.parseEther("100"));
    //         await nalnda_book.connect(daksh).safeMint(daksh.address);
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     expect(await nalnda_book.ownerOf(BigNumber.from("2"))).to.equal(daksh.address);
    //     expect(await nalnda_erc20.balanceOf(daksh.address)).to.equal(BigNumber.from("0"));
    // })
    // it("safeMint(): Should have sent the protocol fee to the marketplace contract and the rest amount to the book owner", async () => {
    //     // expect(await nalnda_erc20.balanceOf(nalnda_book.address))
    //     let sellerCollected = await nalnda_erc20.balanceOf(ankit.address);
    //     expect(sellerCollected).to.equal(ethers.utils.parseEther("90"))//90%
    //     let feeCollected = await nalnda_erc20.balanceOf(marketplace.address);
    //     expect(feeCollected).to.equal(ethers.utils.parseEther("10"))//10%
    //     expect(sellerCollected.add(feeCollected)).to.equal(ethers.utils.parseEther("100"));
    // })
    // it("safeMint(): Mint should have updated the ownedAt mapping timestamp", async () => {
    //     let ownedAt = await nalnda_book.ownedAt(BigNumber.from("2"));
    //     const blockNum = await ethers.provider.getBlockNumber();
    //     const block = await ethers.provider.getBlock(blockNum)
    //     expect(ownedAt).to.equal(block.timestamp);
    // })
    // it("safeMint(): Mint should have updated the lastSoldPrice mapping correctly", async () => {
    //     expect(await nalnda_book.lastSoldPrice(BigNumber.from("2"))).to.equal(ethers.utils.parseEther("100"));
    // })
    // it("transferFrom(): Should revert of user tries to transfer before set transferAfterDays", async () => {
    //     await expect(nalnda_book.connect(daksh).transferFrom(daksh.address, ekta.address, BigNumber.from("2"))).to.revertedWith("NalndaBook: Transfer not allowed!");
    // })
    // let ownedAtBefore;
    // it("transferFrom(): Should allow transfer after transferAfterDays and charge fees on the transfer", async () => {
    //     let befBal, befOwnBal, befMktBal;
    //     //increasing time
    //     const twentyOneDays = 21 * 24 * 60 * 60;
    //     await ethers.provider.send("evm_increaseTime", [twentyOneDays]);
    //     await ethers.provider.send("evm_mine");
    //     try {
    //         //minting some NALNDA for transfer fee
    //         await nalnda_erc20.connect(daksh).mint(ethers.utils.parseEther("100"));
    //         await nalnda_erc20.connect(daksh).approve(nalnda_book.address, ethers.utils.parseEther("100"));
    //         befBal = await nalnda_erc20.balanceOf(daksh.address);
    //         befOwnBal = await nalnda_erc20.balanceOf(ankit.address);
    //         befMktBal = await nalnda_erc20.balanceOf(marketplace.address);
    //         ownedAtBefore = await nalnda_book.ownedAt(BigNumber.from("2"));
    //         // transfer the cover
    //         await nalnda_book.connect(daksh).transferFrom(daksh.address, ekta.address, BigNumber.from("2"));
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     let aftBal = await nalnda_erc20.balanceOf(daksh.address);
    //     expect(aftBal).to.below(befBal);
    //     //10% to the book owner
    //     let aftOwnBal = await nalnda_erc20.balanceOf(ankit.address);
    //     expect(aftOwnBal).to.above(befOwnBal);
    //     expect(aftOwnBal.sub(befOwnBal)).to.equal(ethers.utils.parseEther("10"))
    //     //2% to the marketplace contract as a protocol fee
    //     let aftMktBal = await nalnda_erc20.balanceOf(marketplace.address);
    //     expect(aftMktBal.sub(befMktBal)).to.equal(ethers.utils.parseEther("2"))
    // })
    // it("transferFrom(): should have updated the ownedAt mapping", async () => {
    //     let ownedAtLater = await nalnda_book.ownedAt(BigNumber.from("2"));
    //     expect(ownedAtLater).to.above(ownedAtBefore);
    //     const blockNum = await ethers.provider.getBlockNumber();
    //     const block = await ethers.provider.getBlock(blockNum)
    //     expect(ownedAtLater).to.equal(block.timestamp);
    // })
    // it("safeTransferFrom(): Should revert of user tries to transfer before set transferAfterDays", async () => {
    //     await expect(nalnda_book.connect(ekta)["safeTransferFrom(address,address,uint256)"](ekta.address, fateh.address, BigNumber.from("2"))).to.revertedWith("NalndaBook: Transfer not allowed!");
    // })
    // it("safeTransferFrom(): Should transfer and charge fees on every transfer", async () => {
    //     let befBal, befOwnBal, befMktBal;
    //     //increasing time
    //     const twentyOneDays = 21 * 24 * 60 * 60;
    //     await ethers.provider.send("evm_increaseTime", [twentyOneDays]);
    //     await ethers.provider.send("evm_mine");
    //     try {
    //         //minting some NALNDA for transfer fee
    //         await nalnda_erc20.connect(ekta).mint(ethers.utils.parseEther("100"));
    //         await nalnda_erc20.connect(ekta).approve(nalnda_book.address, ethers.utils.parseEther("100"));
    //         befBal = await nalnda_erc20.balanceOf(ekta.address);
    //         befOwnBal = await nalnda_erc20.balanceOf(ankit.address);
    //         befMktBal = await nalnda_erc20.balanceOf(marketplace.address);
    //         ownedAtBefore = await nalnda_book.ownedAt(BigNumber.from("2"));
    //         // transfer the cover
    //         await nalnda_book.connect(ekta)["safeTransferFrom(address,address,uint256)"](ekta.address, fateh.address, BigNumber.from("2"));
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     let aftBal = await nalnda_erc20.balanceOf(ekta.address);
    //     expect(aftBal).to.below(befBal);
    //     //10% to the book owner
    //     let aftOwnBal = await nalnda_erc20.balanceOf(ankit.address);
    //     expect(aftOwnBal).to.above(befOwnBal);
    //     expect(aftOwnBal.sub(befOwnBal)).to.equal(ethers.utils.parseEther("10"))
    //     //2% to the marketplace contract as a protocol fee
    //     let aftMktBal = await nalnda_erc20.balanceOf(marketplace.address);
    //     expect(aftMktBal.sub(befMktBal)).to.equal(ethers.utils.parseEther("2"))
    // })
    // it("transferFrom(): should have updated the ownedAt mapping", async () => {
    //     let ownedAtLater = await nalnda_book.ownedAt(BigNumber.from("2"));
    //     expect(ownedAtLater).to.above(ownedAtBefore);
    //     const blockNum = await ethers.provider.getBlockNumber();
    //     const block = await ethers.provider.getBlock(blockNum)
    //     expect(ownedAtLater).to.equal(block.timestamp);
    // })
    // it("burn(): Owner should be able to burn its NFT", async () => {
    //     try {
    //         await nalnda_book.connect(ankit).burn(BigNumber.from("1"));
    //     } catch (err) {
    //         console.log(err);
    //     }
    //     expect(await nalnda_book.balanceOf(ankit.address)).to.equal(BigNumber.from("0"));
    //     await expect(nalnda_book.ownerOf(BigNumber.from("1"))).to.revertedWith("ERC721: owner query for nonexistent token");
    // })
    // it("burn(): Should have set the ownedAt timestamp to 0", async () => {
    //     expect(await nalnda_book.ownedAt(BigNumber.from("1"))).to.equal(BigNumber.from("0"));
    // })
    // })

})