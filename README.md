# Zynora contracts

Zynora is an AI studio on Robinhood Chain. You write, picture, film or build something with AI, then seal it with
your own wallet: the work's fingerprint (keccak256 of its exact bytes) is recorded on chain by its creator, so anyone
can check who made it and when. Site: [zynora.studio](https://zynora.studio) · X: [x.com/Zynora_Studio](https://x.com/Zynora_Studio)

This repository holds the two contracts the site uses, their tests and the Foundry config. No keys, no settings.

## Deployed on Robinhood Chain (chain id 4663)

| Contract | Address | Source |
|---|---|---|
| ZynoraSeal | [`0xff6836605db832a4ad04bd614e4b9a5b69856b0a`](https://robin.etherscan.io/address/0xff6836605db832a4ad04bd614e4b9a5b69856b0a) | [Sourcify exact_match](https://repo.sourcify.dev/4663/0xff6836605db832a4ad04bd614e4b9a5b69856b0a) |
| ZynoraTips | [`0x6d7faa0ffadde299ae9692509eb5af84fdbbc296`](https://robin.etherscan.io/address/0x6d7faa0ffadde299ae9692509eb5af84fdbbc296) | [Sourcify exact_match](https://repo.sourcify.dev/4663/0x6d7faa0ffadde299ae9692509eb5af84fdbbc296) |

- **ZynoraSeal** records a work's fingerprint, its parent (for a remix), its kind and a URI, with `msg.sender` as the
  creator. It has no owner, holds no funds and cannot be upgraded.
- **ZynoraTips** sends tips straight to a sealed work's creator; it reads the creator from ZynoraSeal.

## On chain

- **$ZYNR** (on Robinhood Chain): `0xb391face52d941b581e5d599068bd3e39fe003fb`
  ([Pons](https://ponsfamily.com/launchpad/0xb391face52d941b581e5d599068bd3e39fe003fb) ·
  [explorer](https://robin.etherscan.io/token/0xb391face52d941b581e5d599068bd3e39fe003fb))
- **First seal:** [`0x11dcba4e154a3f251a472871cdff675d27f52b30a0c4c314b5bd4ea7d7ba7dae`](https://robin.etherscan.io/tx/0x11dcba4e154a3f251a472871cdff675d27f52b30a0c4c314b5bd4ea7d7ba7dae)
- **Dev supply burned:** [`0xa40813682a1daf303277e59e1cf2fe9568d706a81bb5a24d5a3c3c5e6215e3f8`](https://robin.etherscan.io/tx/0xa40813682a1daf303277e59e1cf2fe9568d706a81bb5a24d5a3c3c5e6215e3f8)

Nothing here is a promise of profit or of a price.

## Build and test

```
forge install foundry-rs/forge-std --no-git
forge build
forge test
```

Solidity 0.8.26, optimizer 20,000 runs, EVM cancun (`foundry.toml`), the settings the deployed bytecode was verified with.

## License

MIT
