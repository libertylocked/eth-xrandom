pragma solidity ^0.4.24;

import "./Ownable.sol";


// Random number generator using commit-reveal.
// Numbers are computed from XOR-keccak256 from the seed
// This contract should be deployed by a controller. The controller
//  who is the owner serves as a relay to call commit/reveal
contract XRandom is Ownable {
    address public relayer;
    mapping(address => bool) public players;
    address[] public playersArray;
    mapping(address => bytes32) public commits;
    uint public commitCount;
    mapping(address => uint) public reveals;
    uint public revealCount;
    State public state;
    // RNG related stuff
    uint public seed;
    uint public index;

    enum State {
        Commit,
        Reveal,
        Ready
    }

    event LogCommitted(address player, bytes32 commit);
    event LogRevealed(address player, uint number);
    event LogStateChanged(State state);
    event LogRandomGenerated(uint index, uint number);

    modifier onlyPlayer(address sender) {
        require(players[sender]);
        _;
    }

    modifier onlyRelayer {
        require(msg.sender == relayer);
        _;
    }

    modifier onlyNotCommitted(address sender) {
        require(commits[sender] == 0);
        _;
    }

    modifier onlyNotRevealed(address sender) {
        require(reveals[sender] == 0);
        _;
    }

    modifier onlyDuring(State _state) {
        require(state == _state);
        _;
    }

    constructor(address[] _players, address _relayer) public {
        for (uint i = 0; i < _players.length; i++) {
            players[_players[i]] = true;
        }
        playersArray = _players;
        relayer = _relayer;
        state = State.Commit;
    }

    function commit(address sender, bytes32 _hash)
        onlyRelayer
        onlyDuring(State.Commit)
        external
        returns (bool)
    {
        return _commit(sender, _hash);
    }

    function commitByPlayer(bytes32 _hash)
        onlyPlayer(msg.sender)
        onlyDuring(State.Commit)
        external
        returns (bool)
    {
        return _commit(msg.sender, _hash);
    }

    function reveal(address sender, uint _num)
        onlyRelayer
        onlyDuring(State.Reveal)
        external
        returns (bool)
    {
        return _reveal(sender, _num);
    }

    function revealByPlayer(uint _num)
        onlyPlayer(msg.sender)
        onlyDuring(State.Reveal)
        external
        returns (bool)
    {
        return _reveal(msg.sender, _num);
    }

    function next()
        onlyOwner
        onlyDuring(State.Ready)
        external
        returns (uint)
    {
        seed = uint(keccak256(abi.encodePacked(seed)));
        index++;
        emit LogRandomGenerated(index, seed);
        return seed;
    }

    function reset()
        onlyOwner
        onlyDuring(State.Ready)
        external
        returns (bool)
    {
        state = State.Commit;
        for (uint i = 0; i < playersArray.length; i++) {
            commits[playersArray[i]] = bytes32(0);
            reveals[playersArray[i]] = uint(0);
        }
        commitCount = 0;
        revealCount = 0;
        seed = 0;
        index = 0;
        return true;
    }

    /* Constant functions */

    function current()
        onlyDuring(State.Ready)
        external view
        returns (uint)
    {
        return seed;
    }

    function ready()
        external view
        returns (bool)
    {
        return state == State.Ready;
    }

    function playerCount()
        external view
        returns (uint)
    {
        return playersArray.length;
    }

    /* Private functions */

    function _commit(address sender, bytes32 _hash)
        onlyPlayer(sender)
        onlyNotCommitted(sender)
        onlyDuring(State.Commit)
        private
        returns (bool)
    {
        // the commit can't be zero or hashed zero
        require(_hash != 0);
        require(_hash != keccak256(abi.encodePacked(uint(0))));
        commits[sender] = _hash;
        commitCount++;
        emit LogCommitted(sender, _hash);
        if (commitCount == playersArray.length) {
            state = State.Reveal;
            emit LogStateChanged(State.Reveal);
        }
        return true;
    }

    function _reveal(address sender, uint _num)
        onlyPlayer(sender)
        onlyNotRevealed(sender)
        onlyDuring(State.Reveal)
        private
        returns (bool)
    {
        // check commit
        require(keccak256(abi.encodePacked(_num)) == commits[sender]);
        reveals[sender] = _num;
        revealCount++;
        emit LogRevealed(sender, _num);
        seed ^= _num;
        if (revealCount == playersArray.length) {
            state = State.Ready;
            emit LogStateChanged(State.Ready);
        }
        return true;
    }

}
