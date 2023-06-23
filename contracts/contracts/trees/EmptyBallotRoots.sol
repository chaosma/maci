// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract EmptyBallotRoots {
    // emptyBallotRoots contains the roots of Ballot trees of five leaf
    // configurations.
    // Each tree has a depth of 10, which is the hardcoded state tree depth.
    // Each leaf is an empty ballot. A configuration refers to the depth of the
    // voice option tree for that ballot.

    // The leaf for the root at index 0 contains hash(0, root of a VO tree with
    // depth 1 and zero-value 0)

    // The leaf for the root at index 1 contains hash(0, root of a VO tree with
    // depth 2 and zero-value 0)

    // ... and so on.

    // The first parameter to the hash function is the nonce, which is 0.

    uint256[5] internal emptyBallotRoots;

    constructor() {
        emptyBallotRoots[0] = uint256(4904028317433377177773123885584230878115556059208431880161186712332781831975);
        emptyBallotRoots[1] = uint256(344732312350052944041104345325295111408747975338908491763817872057138864163);
        emptyBallotRoots[2] = uint256(19445814455012978799483892811950396383084183210860279923207176682490489907069);
        emptyBallotRoots[3] = uint256(10621810780690303482827422143389858049829670222244900617652404672125492013328);
        emptyBallotRoots[4] = uint256(17077690379337026179438044602068085690662043464643511544329656140997390498741);

    }
}

