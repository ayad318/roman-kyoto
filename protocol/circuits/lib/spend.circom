
pragma circom 2.0.0;

include "./keypair.circom";
include "./merkleproof.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";

template Spend(levels) {
  signal input root;
  signal input privateKey;
  signal input amount;
  signal input blinding;
  signal input asset;
  signal input pathIndex;
  signal input nullifier;
  signal input pathElements[levels];
  signal output commitment;

  component keypair = Keypair();
  keypair.privateKey <== privateKey;
  //publicKey <== keypair.publicKey;

  component commitmentHasher = Poseidon(4);
  commitmentHasher.inputs[0] <== amount;
  commitmentHasher.inputs[1] <== keypair.publicKey;
  commitmentHasher.inputs[2] <== blinding;
  commitmentHasher.inputs[3] <== asset;
  commitment <== commitmentHasher.out;

  component sig = Signature();
  sig.privateKey <== privateKey;
  sig.commitment <== commitment;
  sig.merklePath <== pathIndex;

  component nullifierHash = Poseidon(3);
  nullifierHash.inputs[0] <== commitment;
  nullifierHash.inputs[1] <== pathIndex;
  nullifierHash.inputs[2] <== sig.out;
  nullifierHash.out === nullifier;

  component merkle = MerkleProof(levels);
  merkle.leaf <== commitmentHasher.out;
  merkle.index <== pathIndex;
  for (var i = 0; i < levels; i++) {
      merkle.pathElements[i] <== pathElements[i];
  }

  // check merkle proof only if amount is non-zero
  component checkRoot = ForceEqualIfEnabled();
  checkRoot.in[0] <== root;
  checkRoot.in[1] <== merkle.root;
  checkRoot.enabled <== amount;
}
