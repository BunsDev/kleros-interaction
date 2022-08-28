 /**
 *  @authors: [@shalzz, @unknownunknown1]
 *  @reviewers: [@jaybuidl*, @geaxed*]
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */

pragma solidity ^0.4.15;

import "./RNG.sol";

/**
 *  @title Random Number Generator using beacon chain random opcode
 */
contract BeaconRNGFallBack is RNG {

    RNG public beaconRNG;
    RNG public blockhashRNG;

    uint public constant LOOKAHEAD = 132; // Number of blocks that has to pass before obtaining the random number. 4 epochs + 4 slots, according to EIP-4399.

    /** @dev Constructor.
     * @param _beaconRNG The beacon chain RNG deployed contract address
     * @param _blockhashRNG The blockhash RNG deployed contract address
     */
    constructor(RNG _beaconRNG, RNG _blockhashRNG) public {
        beaconRNG = _beaconRNG;
        blockhashRNG = _blockhashRNG;
    }

    /**
     * @dev Since we don't really need to incentivize requesting the beacon chain randomness,
     * this is a stub implementation required for backwards compatibility with the
     * RNG interface.
     * @notice All the ETH sent here will be lost forever.
     * @param _block Block the random number is linked to.
     */
    function contribute(uint _block) public payable {}

    /**
     * @dev Request a random number.
     * @dev Since the beacon chain randomness is not related to a block
     * we can call ahead its getRN function to check if the PoS merge has happened or not.
     *  
     * @param _block Block linked to the request.
     */
    function requestRN(uint _block) public payable {
        uint RN = beaconRNG.getRN(_block);

        if (RN == 0) {
            blockhashRNG.contribute(_block);
        } else {
            beaconRNG.contribute(_block);
        }
    }

    /**
     * @dev Get the random number.
     * @param _block Block the random number is linked to.
     * @return RN Random Number. If the number is not ready or has not been required 0 instead.
     */
    function getRN(uint _block) public returns (uint RN) {
        RN = beaconRNG.getRN(_block);

        // if beacon chain randomness is zero
        // fallback to blockhash RNG
        if (RN == 0) {
            RN = blockhashRNG.getRN(_block);
        } else if (block.number < _block + LOOKAHEAD) {
            // Beacon chain returns the random number, but sufficient number of blocks hasn't been mined yet.
            // In this case signal to the court that RN isn't ready.
            RN = 0;
        }
    }
}
