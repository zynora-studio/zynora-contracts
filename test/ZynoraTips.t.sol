// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ZynoraSeal} from "../src/ZynoraSeal.sol";
import {ZynoraTips} from "../src/ZynoraTips.sol";

contract Refuser {
    receive() external payable { revert("no"); }
}

/// tries to re-enter tip() while receiving a tip
contract Reenterer {
    ZynoraTips t; bytes32 h; bool tried; bool public reentryRefused;
    constructor(ZynoraTips t_) { t = t_; }
    function set(bytes32 h_) external { h = h_; }
    receive() external payable {
        if (!tried) {
            tried = true;
            try t.tip{value: 1}(h) { reentryRefused = false; } catch { reentryRefused = true; }
        }
    }
}

contract ZynoraTipsTest is Test {
    ZynoraSeal p;
    ZynoraTips t;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    bytes32 original = keccak256("original");
    bytes32 remix = keccak256("remix");

    function setUp() public {
        p = new ZynoraSeal();
        t = new ZynoraTips(p);
        vm.prank(alice); p.record(original, bytes32(0), 1, "");
        vm.prank(bob); p.record(remix, original, 1, "");
        vm.deal(carol, 100 ether);
    }

    function test_tipGoesStraightToTheCreator() public {
        vm.prank(carol); t.tip{value: 1 ether}(original);
        assertEq(alice.balance, 1 ether);
        assertEq(address(t).balance, 0, "never keeps a balance");
    }

    function test_remixTipSplitsToTheOriginalCreator() public {
        vm.prank(carol); t.tip{value: 1 ether}(remix);
        assertEq(bob.balance, 0.8 ether);
        assertEq(alice.balance, 0.2 ether);
        assertEq(address(t).balance, 0);
    }

    function test_remixOfOwnWorkPaysAllToThatCreator() public {
        bytes32 self = keccak256("self remix");
        vm.prank(alice); p.record(self, original, 1, "");
        vm.prank(carol); t.tip{value: 1 ether}(self);
        assertEq(alice.balance, 1 ether);
    }

    function test_unrecordedRefused() public {
        bytes32 nope = keccak256("nope");
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(ZynoraTips.NotRecorded.selector, nope));
        t.tip{value: 1}(nope);
    }

    function test_zeroValueRefused() public {
        vm.expectRevert(ZynoraTips.NoValue.selector);
        t.tip(original);
    }

    function test_aRefusingRecipientRevertsTheWholeTip() public {
        Refuser r = new Refuser();
        bytes32 h = keccak256("refuser's");
        vm.prank(address(r)); p.record(h, bytes32(0), 1, "");
        uint256 before = carol.balance;
        vm.prank(carol);
        vm.expectRevert(abi.encodeWithSelector(ZynoraTips.TransferFailed.selector, address(r)));
        t.tip{value: 1 ether}(h);
        assertEq(carol.balance, before, "nothing left the tipper");
        assertEq(address(t).balance, 0);
    }

    function test_reentryIsRefused() public {
        Reenterer r = new Reenterer(t);
        bytes32 h = keccak256("reenterer's");
        r.set(h);
        vm.prank(address(r)); p.record(h, bytes32(0), 1, "");
        vm.deal(address(r), 1 ether);
        vm.prank(carol); t.tip{value: 1 ether}(h);
        assertTrue(r.reentryRefused(), "the nested tip was refused");
        assertEq(address(t).balance, 0);
    }

    function test_holdsNoFundsAndRefusesPlainTransfers() public {
        vm.prank(carol);
        (bool ok,) = address(t).call{value: 1 wei}("");
        assertFalse(ok);
    }

    /// fuzz: every wei of a remix tip leaves, split 80/20
    function testFuzz_remixSplitConserves(uint96 amount) public {
        vm.assume(amount > 0);
        vm.deal(carol, amount);
        vm.prank(carol); t.tip{value: amount}(remix);
        assertEq(alice.balance + bob.balance, amount);
        assertEq(alice.balance, (uint256(amount) * 2000) / 10_000);
        assertEq(address(t).balance, 0);
    }
}
