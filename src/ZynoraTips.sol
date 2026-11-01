// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ZynoraSeal} from "./ZynoraSeal.sol";

/// @title ZynoraTips
/// @notice Tips a recorded work's creator, passing the ETH straight through in
///         the same transaction. For a remix, a fixed share goes to the
///         creator of the work it remixes.
/// @dev    No owner, no admin, no fee, never keeps a balance: every wei that
///         comes in leaves in the same call, or the whole call reverts. A
///         simple lock refuses re-entry while ETH is being forwarded.
contract ZynoraTips {
    ZynoraSeal public immutable proof;
    /// share of a remix tip for the original creator, in basis points
    uint16 public constant REMIX_SHARE_BPS = 2000;

    uint256 private locked = 1;

    event Tipped(bytes32 indexed contentHash, address indexed from, address indexed to, uint256 amount, address original, uint256 originalAmount);

    error NotRecorded(bytes32 contentHash);
    error NoValue();
    error Reentrant();
    error TransferFailed(address to);

    constructor(ZynoraSeal proof_) {
        proof = proof_;
    }

    modifier nonReentrant() {
        if (locked != 1) revert Reentrant();
        locked = 2;
        _;
        locked = 1;
    }

    function tip(bytes32 contentHash) external payable nonReentrant {
        if (msg.value == 0) revert NoValue();
        (address creator,,, bytes32 parent) = proof.proofOf(contentHash);
        if (creator == address(0)) revert NotRecorded(contentHash);

        address original = address(0);
        uint256 originalAmount = 0;
        if (parent != bytes32(0)) {
            original = proof.creatorOf(parent);
            /* a remix of one's own work pays all of it to that one creator */
            if (original != creator) originalAmount = (msg.value * REMIX_SHARE_BPS) / 10_000;
        }
        uint256 creatorAmount = msg.value - originalAmount;

        _send(creator, creatorAmount);
        if (originalAmount > 0) _send(original, originalAmount);
        emit Tipped(contentHash, msg.sender, creator, creatorAmount, original, originalAmount);
    }

    function _send(address to, uint256 amount) private {
        (bool ok,) = to.call{value: amount}("");
        if (!ok) revert TransferFailed(to);
    }
}
