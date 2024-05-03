// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MultiplierVerifier} from "./generated/multiplier.sol";
import {SpendVerifier} from "./generated/spend.sol";
import {OutputVerifier} from "./generated/output.sol";
import "./EdOnBN254.sol";

import "hardhat/console.sol";

contract CircomExample {
    using EdOnBN254 for *;

    SpendVerifier public spendVerifier;
    OutputVerifier public outputVerifier;

    struct SpendProof {
        bytes proof;
        uint nullifier;
        uint[2] valueCommitment;
    }

    struct OutputProof {
        bytes proof;
        uint commitment;
        uint[2] valueCommitment;
    }

    constructor(address _spendVerifier, address _outputVerifier) payable {
        spendVerifier = SpendVerifier(_spendVerifier);
        outputVerifier = OutputVerifier(_outputVerifier);
    }

    function parseProof(
        bytes memory data
    )
        internal
        pure
        returns (uint[2] memory a, uint[2][2] memory b, uint[2] memory c)
    {
        (a[0], a[1], b[0][0], b[0][1], b[1][0], b[1][1], c[0], c[1]) = abi
            .decode(data, (uint, uint, uint, uint, uint, uint, uint, uint));
    }

    function spendVerify(
        bytes memory _proof,
        uint[1] memory _pubSignals
    ) public view {
        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c) = parseProof(
            _proof
        );
        require(
            spendVerifier.verifyProof(a, b, c, _pubSignals),
            "invalid proof"
        );
    }

    function outputVerify(
        bytes memory _proof,
        uint[1] memory _pubSignals
    ) public view {
        (uint[2] memory a, uint[2][2] memory b, uint[2] memory c) = parseProof(
            _proof
        );
        require(
            outputVerifier.verifyProof(a, b, c, _pubSignals),
            "invalid proof"
        );
    }

    function transact(
        SpendProof[] memory _spendProof,
        OutputProof[] memory _outputProofs,
        uint[2] memory _bpk
    ) public view {
        EdOnBN254.Affine memory total = EdOnBN254.zero();

        for (uint i = 0; i < _spendProof.length; i++) {
            SpendProof memory spendProof = _spendProof[i];
            total = total.add(
                EdOnBN254.Affine(
                    spendProof.valueCommitment[0],
                    spendProof.valueCommitment[1]
                )
            );
        }

        for (uint j = 0; j < _outputProofs.length; j++) {
            OutputProof memory outputProof = _outputProofs[j];
            total = total.add(
                EdOnBN254
                    .Affine(
                        outputProof.valueCommitment[0],
                        outputProof.valueCommitment[1]
                    )
                    .neg()
            );
        }

        require(
            total.add(EdOnBN254.zero().neg()).x == _bpk[0] &&
                total.add(EdOnBN254.zero().neg()).y == _bpk[1],
            "Sum of values is incorrect"
        );

        for (uint i = 0; i < _spendProof.length; i++) {
            SpendProof memory spendProof = _spendProof[i];
            spendVerify(spendProof.proof, [spendProof.nullifier]);
        }

        for (uint j = 0; j < _outputProofs.length; j++) {
            OutputProof memory outputProof = _outputProofs[j];
            outputVerify(outputProof.proof, [outputProof.commitment]);
        }
    }
}
