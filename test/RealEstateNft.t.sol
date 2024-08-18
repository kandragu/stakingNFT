// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {RealEstateNft} from "../src/RealEstateNft.sol";
import {MockUSDC} from "../mock/MockUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RealEstateNftTest is Test {
    address internal constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    bytes32 constant merkelTreeRoot =
        0x897d6714686d83f84e94501e5d6f0f38c94b75381b88d1de3878b4f3d2d5014a;

    RealEstateNft realEstateNft;
    MockUSDC mockUsdc;

    address bob;
    uint256 constant NFT_PRICE = 100 * 1E6;
    uint256 constant NFT_PRICE_WTIH_DISCOUNT = 90 * 1E6; // 10% discount

    function setUp() public {
        mockUsdc = new MockUSDC();
        realEstateNft = new RealEstateNft(merkelTreeRoot, address(mockUsdc));

        bob = address(0x01);

        //transfer some usdc to bob
        IERC20(mockUsdc).transfer(bob, 100 * 1e6); // 100 usdc
    }

    function testMintWithDiscount() public {
        bytes32[] memory proof = new bytes32[](3);
        proof[
            0
        ] = 0x50bca9edd621e0f97582fa25f616d475cabe2fd783c8117900e5fed83ec22a7c;
        proof[
            1
        ] = 0x8138140fea4d27ef447a72f4fcbc1ebb518cca612ea0d392b695ead7f8c99ae6;
        proof[
            2
        ] = 0x9005e06090901cdd6ef7853ac407a641787c28a78cb6327999fc51219ba3c880;

        // Bob with address 0x01 transfer 90 usdc with discount of 10% to the RealEstateNft for the NFT mint
        vm.startPrank(bob);
        IERC20(mockUsdc).transfer(
            address(realEstateNft),
            NFT_PRICE_WTIH_DISCOUNT
        );
        realEstateNft.mint(NFT_PRICE, bob, 0, proof);
        uint amount = realEstateNft.balanceOf(bob);
        address ownerOfToken1 = realEstateNft.ownerOf(1);

        vm.stopPrank();

        assertEq(amount, 1);
        assertEq(ownerOfToken1, address(bob));

        // console.log(amount, ownerOfToken1);
    }
}
