// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {HINVToken} from "../../src/tokens/HINVToken.sol";

contract HINVTokenTest is Test {
    HINVToken public token;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");

    uint256 public constant TOTAL_SUPPLY = 100_000_000e18;

    function setUp() public {
        vm.prank(owner);
        token = new HINVToken(owner);
    }

    /*//////////////////////////////////////////////////////////////
                            DEPLOYMENT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_InitialSupply() public view {
        assertEq(token.totalSupply(), TOTAL_SUPPLY);
    }

    function test_OwnerReceivesSupply() public view {
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY);
    }

    function test_NameAndSymbol() public view {
        assertEq(token.name(), "HomeInv");
        assertEq(token.symbol(), "HINV");
    }

    function test_Decimals() public view {
        assertEq(token.decimals(), 18);
    }

    /*//////////////////////////////////////////////////////////////
                            TRANSFER TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Transfer() public {
        vm.prank(owner);
        token.transfer(alice, 1000e18);
        assertEq(token.balanceOf(alice), 1000e18);
        assertEq(token.balanceOf(owner), TOTAL_SUPPLY - 1000e18);
    }

    function test_TransferFrom() public {
        vm.prank(owner);
        token.approve(alice, 1000e18);

        vm.prank(alice);
        token.transferFrom(owner, bob, 1000e18);

        assertEq(token.balanceOf(bob), 1000e18);
    }

    function test_Revert_TransferExceedsBalance() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1000e18);
    }

    /*//////////////////////////////////////////////////////////////
                            VOTING TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Delegate() public {
        vm.prank(owner);
        token.delegate(owner);
        assertEq(token.getVotes(owner), TOTAL_SUPPLY);
    }

    function test_DelegateTransfersVotingPower() public {
        vm.prank(owner);
        token.transfer(alice, 1000e18);

        vm.prank(alice);
        token.delegate(alice);

        assertEq(token.getVotes(alice), 1000e18);
    }

    function test_VotingPowerUpdatesOnTransfer() public {
        vm.prank(owner);
        token.delegate(owner);

        vm.prank(owner);
        token.transfer(alice, 1000e18);

        assertEq(token.getVotes(owner), TOTAL_SUPPLY - 1000e18);
    }

    /*//////////////////////////////////////////////////////////////
                            PERMIT TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Permit() public {
        uint256 privateKey = 0xA11CE;
        address signer = vm.addr(privateKey);

        vm.prank(owner);
        token.transfer(signer, 1000e18);

        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                token.DOMAIN_SEPARATOR(),
                keccak256(abi.encode(
                    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                    signer,
                    bob,
                    1000e18,
                    token.nonces(signer),
                    deadline
                ))
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        token.permit(signer, bob, 1000e18, deadline, v, r, s);

        assertEq(token.allowance(signer, bob), 1000e18);
    }
}