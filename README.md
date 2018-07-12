XRandom
---
XOR-keccak256 random number generator implementation in Javascript and Solidity. `XRandom` is designed to be used for smart contracts where randomness is needed.

# Design
The seed of `XRandom` is computed as the XOR of all the inputs. The inputs are 32 bytes (a `uint256` in Solidity).

The next random number is generated as the keccak-256 hash of the previous number. The generated randoms are all 32 bytes.

# Implementations
## Javascript
```javascript
var XRandom = require('eth-xrandom')
// number, hex string, bignumber are all supported
var xrng = new XRandom([42, 1337, '0x2329'])
// the random numbers generated are `bignum` objects
var r1 = xrng.next() // get a random number anywhere between 0 and 2^256
var r2 = xrng.next('0xbeef') // get a random number with exclusive upper bound
```

## Solidity
The contract written in Solidity is at `contracts/XRandom.sol`. It uses commit-reveal pattern.

- XRandom.commit
- XRandom.reveal
- XRandom.next
- XRandom.reset
