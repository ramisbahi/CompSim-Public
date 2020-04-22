//
//  IndexMapping.swift
//  CompSim
//
//  Created by Rami Sbahi on 4/3/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
// GOOD.

import Foundation
class IndexMapping {
    // permutation
    
    static func permutationToIndex(permutation: [Int8]) -> Int{
        var index = 0
        for i in 0..<(permutation.count - 1)
        {
            index *= permutation.count - i
            for j in (i + 1)..<permutation.count
            {
                if (permutation[i] > permutation[j]) {
                    index += 1
                }
            }
        }

        return index
    }
     

    static func indexToPermutation(index: Int, length: Int) -> [Int8] {
        var indexCopy = index
        var permutation: [Int8] = [Int8](repeating: 0, count: length)
        permutation[length - 1] = 0
        for i in stride(from: length - 2, to: 0, by: -1)
        {
            permutation[i] = Int8(index % (length - i))
            indexCopy /= length - i
            for j in (i + 1)..<length
            {
                if (permutation[j] >= permutation[i]) {
                    permutation[j] += 1
                }
            }
        }

        return permutation
    }
 
 /*

    // even permutation
    public static int evenPermutationToIndex(byte[] permutation) {
        int index = 0;
        for (int i = 0; i < permutation.length - 2; i++) {
            index *= permutation.length - i;
            for (int j = i + 1; j < permutation.length; j++) {
                if (permutation[i] > permutation[j]) {
                    index++;
                }
            }
        }

        return index;
    }

    public static byte[] indexToEvenPermutation(int index, int length) {
        int sum = 0;
        byte[] permutation = new byte[length];

        permutation[length - 1] = 1;
        permutation[length - 2] = 0;
        for (int i = length - 3; i >= 0; i--) {
            permutation[i] = (byte) (index % (length - i));
            sum += permutation[i];
            index /= length - i;
            for (int j = i + 1; j < length; j++) {
                if (permutation[j] >= permutation[i]) {
                    permutation[j]++;
                }
            }
        }

        if (sum % 2 != 0) {
            byte temp = permutation[permutation.length - 1];
            permutation[permutation.length - 1] = permutation[permutation.length - 2];
            permutation[permutation.length - 2] = temp;
        }

        return permutation;
    }*/

    // orientation
    static func orientationToIndex(orientation: [Int8], nValues: Int) -> Int {
        var index = 0
        for i in 0..<orientation.count
        {
            index = nValues * index + Int(orientation[i])
        }
        return index
    }
    
    /*

    public static byte[] indexToOrientation(int index, int nValues, int length) {
        byte[] orientation = new byte[length];
        for (int i = length - 1; i >= 0; i--) {
            orientation[i] = (byte) (index % nValues);
            index /= nValues;
        }

        return orientation;
    }

    // zero sum orientation
    public static int zeroSumOrientationToIndex(byte[] orientation, int nValues) {
        int index = 0;
        for (int i = 0; i < orientation.length - 1; i++) {
            index = nValues * index + orientation[i];
        }

        return index;
    }

    public static byte[] indexToZeroSumOrientation(int index, int nValues, int length) {
        byte[] orientation = new byte[length];
        orientation[length - 1] = 0;
        for (int i = length - 2; i >= 0; i--) {
            orientation[i] = (byte) (index % nValues);
            index /= nValues;

            orientation[length - 1] += orientation[i];
        }
        orientation[length - 1] = (byte) ((nValues - orientation[length - 1] % nValues) % nValues);

        return orientation;
    }
*/
    // combinations
    private static func nChooseK(n: Int, k: Int) -> Int
    {
        var value = 1

        for i in 0..<k
        {
            value *= n - i
        }

        for i in 0..<k
        {
            value /= k - i
        }

        return value
    }

    static func combinationToIndex(combination: [Bool], k: Int) -> Int
    {
        var kCopy = k
        var index = 0
        var i = combination.count - 1
        while i >= 0 && kCopy > 0
        {
            if (combination[i])
            {
                index += IndexMapping.nChooseK(n: i, k: kCopy)
                kCopy -= 1
            }
            i -= 1
        }
        return index
    }

    static func indexToCombination(index: Int, k: Int, length: Int) -> [Bool]
    {
        var kCopy = k
        var indexCopy = index
        var combination: [Bool] = []
        
        for _ in 0..<length
        {
            combination.append(false)
        }
        var i = length - 1
        
        while i >= 0 && kCopy >= 0
        {
            if indexCopy >= nChooseK(n: i, k: kCopy)
            {
                combination[i] = true
                indexCopy -= IndexMapping.nChooseK(n: i, k: kCopy)
                kCopy-=1
            }
            i -= 1
        }

        return combination
    }
     
}
