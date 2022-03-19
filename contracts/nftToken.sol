//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract NFTToken is ERC721, Ownable{

    uint256 private _tokenIDCounter;
    string private baseURI;
    uint256 public immutable maxSupply;
    mapping(address => bool) internal hasMinted;

    constructor(
        string memory name_, 
        string memory symbol_, 
        string memory baseURI_, 
        uint256 maxSupply_
    ) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        maxSupply = maxSupply_;
    }

    function mintTokenTo(address to_) external onlyOwner() returns(uint256) {
        require(_tokenIDCounter < maxSupply, "NFTToken: no more token token to be minted!");
        _tokenIDCounter++;
        uint256 newTokenID = _tokenIDCounter;
        _safeMint(to_, newTokenID);
        return newTokenID;
    }

    function mintToken() external payable returns(uint256) {
        require(_tokenIDCounter < maxSupply, "NFTToken: no more token to be minted!");
        require(msg.value >= 0.1 ether, "a fee of at leaset 0.1 is required for minting a token");
        // only allow one minting per account
        require(!hasMinted[msg.sender], "You cannot mint more than once from this contract");
        hasMinted[msg.sender] = true;
        _tokenIDCounter++;
        uint256 newTokenID = _tokenIDCounter;
        _safeMint(msg.sender, newTokenID);
        return newTokenID;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory newBaseURI_) external {
        baseURI = newBaseURI_;
    }
    
}
