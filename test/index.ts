import { expect } from "chai";
import { ethers } from "hardhat";
import { NFTToken as NFTTokenType } from "../typechain/NFTToken";

describe("NFTToken", function () {
  let nftToken: NFTTokenType;
  this.beforeEach( async ()=> {
    const NFTToken = await ethers.getContractFactory("NFTToken");
    nftToken = await NFTToken.deploy("Friend collectibles", "FCB", "https://testUri.test/", 10);
    await nftToken.deployed();
  })

  it("should set name and symbol correctly", async () => {
    const name: string = await nftToken.name();
    const symbol: string = await nftToken.symbol();

    expect(name).to.equal("Friend collectibles");
    expect(symbol).to.equal("FCB");

  })

  it("Should set owner correctly", async () => {
    const [_] = await ethers.getSigners();
    const owner: String = await nftToken.owner();
    expect(owner).to.equal(_.address)
  });

  it("Should set maxSupply correctly", async () => {
    const maxSupply = await nftToken.maxSupply();
    expect(maxSupply).to.equal(10)
  });

  it("Should set baseURI correctly", async () => {
    const setBaseURITx = await nftToken.setBaseURI("https://anotherTestBaseUri.test/");
    await setBaseURITx.wait();
    // the only way to verify that the base uri has been changed is to fetch a tokenUri, and to do that, we need to mint one
    const [, signer1] = await ethers.getSigners();
    const mintTokenToTx = await nftToken.mintTokenTo(signer1.address);
    await mintTokenToTx.wait();
    const tokenUri: String = await nftToken.tokenURI(1);
    expect(tokenUri.startsWith("https://anotherTestBaseUri.test/"))
  });

  it("should revert when a non-owner account call the mintTokenTo function", async () => {
    const [,signer1, signer2] = await ethers.getSigners();
    expect(nftToken.connect(signer1).mintTokenTo(signer2.address)).to.be.revertedWith("Ownable: caller is not the owner")
  })

  it("owner should mint token without error", async () => {
    const [,signer1, signer2] = await ethers.getSigners();
    const mint1Tx = await nftToken.mintTokenTo(signer1.address);
    await mint1Tx.wait()
    const mint2Tx = await nftToken.mintTokenTo(signer2.address);
    await mint2Tx.wait()
    const mint3Tx = await nftToken.mintTokenTo(signer1.address);
    await mint3Tx.wait()
    expect(await nftToken.balanceOf(signer1.address)).to.equal(2)
    expect(await nftToken.balanceOf(signer2.address)).to.equal(1)
    expect(await nftToken.ownerOf(2)).to.equal(signer2.address);

  })

  it("should revert when mintToken function is called without sufficient minting fee", async () => {
    const [,signer1] = await ethers.getSigners();
    expect(nftToken.connect(signer1).mintToken()).to.be.revertedWith("a fee of at leaset 0.1 is required for minting a token");
  })

  it("should mint when mintToken function is called with sufficient minting fee", async () => {
    const [,signer1] = await ethers.getSigners();
    const mintTx = await nftToken.connect(signer1).mintToken({value: ethers.utils.parseEther("0.1")});
    await mintTx.wait()
    expect(await  nftToken.balanceOf(signer1.address)).to.equal(1);
  })

  it("should revert when an account try to mint the second time", async () => {
    const [,signer1] = await ethers.getSigners();
    const mintTx = await nftToken.connect(signer1).mintToken({value: ethers.utils.parseEther("0.1")});
    await mintTx.wait()
    expect(nftToken.connect(signer1).mintToken({value: ethers.utils.parseEther("0.1")})).to.be.revertedWith("You cannot mint more than once from this contract")
  })

  it("should not allow minting once max supply is reached", async () => {
    // in this test, the beforeEach block operation will be overriden so i can set a small max supply for the sake of the test

    const NFTToken = await ethers.getContractFactory("NFTToken");
    nftToken = await NFTToken.deploy("Friend collectibles", "FCB", "https://testUri.test/", 2);
    await nftToken.deployed();
    const [,signer1, signer2] = await ethers.getSigners();
    const mint1Tx = await nftToken.mintTokenTo(signer2.address);
    await mint1Tx.wait();
    const mint2Tx = await nftToken.connect(signer1).mintToken({value: ethers.utils.parseEther("0.1")});
    await mint2Tx.wait()
    // this shouuld fail
    expect(nftToken.connect(signer2).mintToken({value: ethers.utils.parseEther("0.1")})).to.be.revertedWith("NFTToken: no more token to be minted!")
  })
});
