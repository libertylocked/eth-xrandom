const assert = require('chai').assert
const bignum = require('bignum')
const eutil = require('ethereumjs-util')
const XRandom = require('../xrandom-js')

describe('XRandom', () => {
  describe('constructor', () => {
    it('should set seed to zero if no inputs', () => {
      const rng = new XRandom()
      assert.notEqual(rng.next().toNumber(), 0)
      assert.equal(rng.seed.toNumber(), 0)
    })
    it('should set the seed as xor of all the input numbers', () => {
      const rng = new XRandom([42, 1337, 9001])
      assert.equal(rng.seed.toNumber(), 42 ^ 1337 ^ 9001)
    })
    it('should accept hex strings as input', () => {
      const rng = new XRandom(['0x2a', '0x0539', '0x2329'])
      assert.equal(rng.seed.toNumber(), 42 ^ 1337 ^ 9001)
    })
    it('should accept bignum as input', () => {
      const rng = new XRandom([bignum(42), bignum(1337), bignum(9001)])
      assert.equal(rng.seed.toNumber(), 42 ^ 1337 ^ 9001)
    })
    it('should accept bignumber as input', () => {
      const BN = eutil.BN
      const rng = new XRandom([new BN(42), new BN(1337), new BN(9001)])
      assert.equal(rng.seed.toNumber(), 42 ^ 1337 ^ 9001)
    })
  })
  describe('next', () => {
    it('should set the next number as keccak of the current number', () => {
      const rng = new XRandom([42, 1337, 9001])
      const nextNumHex = eutil.keccak256(eutil.setLengthLeft(42 ^ 1337 ^ 9001, 32)).toString('hex')
      assert.equal(rng.next().toString(16), nextNumHex)
    })
    it('should generate different numbers on next', () => {
      const rng = new XRandom([42, 1337, 9001])
      rng.next()
      assert.equal(rng.index, 1)
    })
    it('should get the next 2 numbers correctly as the hash of the hash', () => {
      const rng = new XRandom([42, 1337, 9001])
      rng.next()
      const nextNum2Hex = eutil.keccak256(eutil.keccak256(eutil.setLengthLeft(42 ^ 1337 ^ 9001, 32))).toString('hex')
      assert.equal(rng.next().toString(16), nextNum2Hex)
    })
    it('should allow exclusive upper bound in next', () => {
      const rng = new XRandom([42, 1337, 9001])
      const nextBounded = bignum.fromBuffer(eutil.keccak256(eutil.setLengthLeft(42 ^ 1337 ^ 9001, 32))).mod(20)
      assert.equal(rng.next(20).toString(16), nextBounded.toString(16))
    })
  })
  describe('update', () => {
    it('should update the seed to the xor of the inputs', () => {
      const rng = new XRandom([42, 1337])
      rng.update([9001])
      assert.equal(rng.seed.toNumber(), 42 ^ 1337 ^ 9001)
    })
    it('should reset current and index after update', () => {
      const rng = new XRandom([42, 1337])
      rng.next()
      rng.update([9001])
      assert.equal(rng.current.toNumber(), 42 ^ 1337 ^ 9001)
      assert.equal(rng.index, 0)
    })
  })
})
