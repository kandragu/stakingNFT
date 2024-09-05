// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

import {console} from "forge-std/Test.sol";

contract RealEstateNft is ERC721, ERC2981 {
    uint256 _tokenIdCounter;
    uint96 constant ROYALTY_FEE = 250; // 2.5% royalty
    uint96 constant MINT_DISCOUNT_AMT = 1000; // 10% discount
    uint96 constant MINT_DISCOUNT_DENOMINATOR = 10000; // 10% discount

    uint256 constant MAX_SUPPLY = 10000;
    bytes32 public immutable merkleRoot;
    BitMaps.BitMap private _discountList;

    // amount collected from the NFT mint
    uint256 private priceTokenReserve;

    // address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address immutable USDC;

    constructor(bytes32 _merkleRoot, address priceToken) ERC721("Real", "RE") {
        _setDefaultRoyalty(msg.sender, ROYALTY_FEE);
        merkleRoot = _merkleRoot;
        USDC = priceToken;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // @dev create NFT with discount for whitelisted addresses
    function mint(
        uint256 _price,
        address to,
        uint256 index,
        bytes32[] calldata proof
    ) external returns (uint256 tokenIdCounter) {
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");

        // check the input token paid
        uint256 amount = IERC20(USDC).balanceOf(address(this));
        uint256 balance = amount - priceTokenReserve;
        uint256 priceWithDiscount = _price -
            (_price * MINT_DISCOUNT_AMT) /
            MINT_DISCOUNT_DENOMINATOR;
        // console.log("price with discount", priceWithDiscount);
        // console.log("mint token balance", balance);
        require(priceWithDiscount <= balance, "not enough token paid");

        // check if already claimed
        require(!BitMaps.get(_discountList, index), "Already claimed");

        // verify proof
        _verifyProof(proof, index, msg.sender);

        // set airdrop as claimed
        BitMaps.setTo(_discountList, index, true);

        // mint tokens
        _updatePriceToken(amount);
        _tokenIdCounter++;
        tokenIdCounter = _tokenIdCounter;
        _safeMint(to, tokenIdCounter);
    }

    function mint(uint256 price, address to) external {
        require(_tokenIdCounter < MAX_SUPPLY, "Max supply reached");

        // check the input token paid
        uint256 amount = IERC20(USDC).balanceOf(address(this));
        uint256 balance = amount - priceTokenReserve;
        console.log("amount and priceTokenReserve", amount, priceTokenReserve);
        require(price <= balance, "Not enough token paid");
        console.log("mint token balance", balance);

        // mint tokens
        _updatePriceToken(amount);
        _tokenIdCounter++;
        _safeMint(to, _tokenIdCounter);
    }

    function _verifyProof(
        bytes32[] memory proof,
        uint256 index,
        address addr
    ) private view {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(addr, index)))
        );
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
    }

    function _updatePriceToken(uint256 balance) private {
        require(
            balance > priceTokenReserve,
            "Current balance cannot be lower than reserve"
        );

        priceTokenReserve = balance;
    }
}
