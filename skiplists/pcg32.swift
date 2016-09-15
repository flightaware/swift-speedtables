//
//  pcg32.swift
//  skiplists
//
// *Really* minimal PCG32 code / (c) 2014 M.E. O'Neill / pcg-random.org
// Licensed under Apache License 2.0 (NO WARRANTY, etc. see website)
// Converted to Swift by Peter da Silva, backing out some C optimizations
// and hardcoding Knuth's LCG parameters
//

import Cocoa

class pcg32 {
    var state: UInt64;
    
    init(seed: UInt64 = 0)
    {
        state = seed
    }
    
    func next() -> UInt32
    {
        // Advance internal state, Knuth's mixed LCG
        state = state &* 6364136223846793005 &+ 1442695040888963407;
        
        // Calculate output function (XSH RR)
        let xorshifted = UInt32(truncatingBitPattern: ((state >> 18) ^ state) >> 27);
        let rot = UInt32(truncatingBitPattern: state >> 59);
        return (xorshifted >> rot) | (xorshifted << UInt32((-Int32(rot)) & 31));
    }
}
