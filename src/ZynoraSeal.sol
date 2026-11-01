// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ZynoraSeal
/// @notice A public notebook of creations. Anyone can record the fingerprint
///         of a work they made; the record says who recorded it (msg.sender),
///         when, which earlier work it remixes, what kind it is and where its
///         metadata lives.
/// @dev    No owner, no admin function, holds no funds (no payable function,
///         no receive, no fallback), not upgradeable. A fingerprint can be
///         recorded once; a remix may only point at a fingerprint that is
///         already recorded, so every lineage on chain is complete.
contract ZynoraSeal {
    /// kinds: 0 chat, 1 image, 2 video, 3 app, 4 agent
    uint8 public constant MAX_KIND = 4;

    struct Proof {
        address creator;
        uint64 timestamp;
        uint8 kind;
        bytes32 parent;
    }

    mapping(bytes32 => Proof) private proofs;

    event Sealed(
        bytes32 indexed contentHash,
        address indexed creator,
        bytes32 indexed parentHash,
        uint8 kind,
        string uri
    );

    error ZeroHash();
    error AlreadyRecorded(bytes32 contentHash, address creator);
    error UnknownParent(bytes32 parentHash);
    error SelfParent();
    error BadKind(uint8 kind);

    function record(bytes32 contentHash, bytes32 parentHash, uint8 kind, string calldata uri) external {
        if (contentHash == bytes32(0)) revert ZeroHash();
        if (kind > MAX_KIND) revert BadKind(kind);
        address prior = proofs[contentHash].creator;
        if (prior != address(0)) revert AlreadyRecorded(contentHash, prior);
        if (parentHash != bytes32(0)) {
            if (parentHash == contentHash) revert SelfParent();
            if (proofs[parentHash].creator == address(0)) revert UnknownParent(parentHash);
        }
        proofs[contentHash] = Proof({creator: msg.sender, timestamp: uint64(block.timestamp), kind: kind, parent: parentHash});
        emit Sealed(contentHash, msg.sender, parentHash, kind, uri);
    }

    function proofOf(bytes32 contentHash) external view returns (address creator, uint64 timestamp, uint8 kind, bytes32 parent) {
        Proof memory p = proofs[contentHash];
        return (p.creator, p.timestamp, p.kind, p.parent);
    }

    function creatorOf(bytes32 contentHash) external view returns (address) {
        return proofs[contentHash].creator;
    }
}
