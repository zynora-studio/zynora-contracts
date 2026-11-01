// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {ZynoraSeal} from "../src/ZynoraSeal.sol";

contract ZynoraSealTest is Test {
    ZynoraSeal p;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    event Sealed(bytes32 indexed contentHash, address indexed creator, bytes32 indexed parentHash, uint8 kind, string uri);

    function setUp() public {
        p = new ZynoraSeal();
    }

    function test_recordStoresCreatorAndEmits() public {
        bytes32 h = keccak256("a shard");
        vm.warp(1_800_000_000);
        vm.expectEmit(true, true, true, true, address(p));
        emit Sealed(h, alice, bytes32(0), 1, "ipfs://meta");
        vm.prank(alice);
        p.record(h, bytes32(0), 1, "ipfs://meta");
        (address c, uint64 t, uint8 k, bytes32 par) = p.proofOf(h);
        assertEq(c, alice);
        assertEq(t, 1_800_000_000);
        assertEq(k, 1);
        assertEq(par, bytes32(0));
        assertEq(p.creatorOf(h), alice);
    }

    function test_duplicateIsRefusedEvenForAnotherSender() public {
        bytes32 h = keccak256("same");
        vm.prank(alice);
        p.record(h, bytes32(0), 0, "");
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.AlreadyRecorded.selector, h, alice));
        p.record(h, bytes32(0), 0, "");
        assertEq(p.creatorOf(h), alice, "the first creator stays");
    }

    function test_zeroHashRefused() public {
        vm.expectRevert(ZynoraSeal.ZeroHash.selector);
        p.record(bytes32(0), bytes32(0), 0, "");
    }

    function test_badKindRefused() public {
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.BadKind.selector, uint8(5)));
        p.record(keccak256("x"), bytes32(0), 5, "");
    }

    function test_remixNeedsARecordedParent() public {
        bytes32 parent = keccak256("original");
        bytes32 child = keccak256("remix");
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.UnknownParent.selector, parent));
        p.record(child, parent, 1, "");
        vm.prank(alice);
        p.record(parent, bytes32(0), 1, "");
        vm.prank(bob);
        p.record(child, parent, 1, "");
        (address c,,, bytes32 par) = p.proofOf(child);
        assertEq(c, bob);
        assertEq(par, parent);
    }

    function test_selfParentRefused() public {
        bytes32 h = keccak256("loop");
        vm.expectRevert(ZynoraSeal.SelfParent.selector);
        p.record(h, h, 1, "");
    }

    function test_holdsNoFunds() public {
        vm.deal(alice, 1 ether);
        vm.prank(alice);
        (bool ok,) = address(p).call{value: 1 wei}("");
        assertFalse(ok, "a plain transfer must be refused");
        assertEq(address(p).balance, 0);
    }

    /// fuzz: any nonzero hash and valid kind records exactly once, for exactly that sender
    function testFuzz_recordOnce(bytes32 h, uint8 kind, address who, string calldata uri) public {
        vm.assume(h != bytes32(0));
        vm.assume(who != address(0));
        kind = uint8(bound(kind, 0, 4));
        vm.prank(who);
        p.record(h, bytes32(0), kind, uri);
        assertEq(p.creatorOf(h), who);
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.AlreadyRecorded.selector, h, who));
        vm.prank(who);
        p.record(h, bytes32(0), kind, uri);
    }

    /// fuzz: a kind above the maximum never records
    function testFuzz_kindAboveMaxRefused(bytes32 h, uint8 kind) public {
        vm.assume(h != bytes32(0));
        kind = uint8(bound(kind, 5, 255));
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.BadKind.selector, kind));
        p.record(h, bytes32(0), kind, "");
        assertEq(p.creatorOf(h), address(0));
    }

    /// fuzz: an unrecorded parent is always refused
    function testFuzz_unknownParentRefused(bytes32 h, bytes32 parent) public {
        vm.assume(h != bytes32(0) && parent != bytes32(0) && parent != h);
        vm.expectRevert(abi.encodeWithSelector(ZynoraSeal.UnknownParent.selector, parent));
        p.record(h, parent, 1, "");
    }
}
