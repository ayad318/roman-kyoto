import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import SpendVerifier from "./generated/uspendVerifier";
import OutputVerifier from "./generated/uoutputVerifier";

export default buildModule("CircomExample", (m) => {
  const { verifier: spendVerifier } = m.useModule(SpendVerifier);
  const { verifier: outputVerifier } = m.useModule(OutputVerifier);

  const EdOnBN254 = m.library("EdOnBN254");

  const verifier = m.contract(
    "CircomExample",
    [spendVerifier, outputVerifier],
    {
      libraries: {
        EdOnBN254,
      },
    }
  );

  return { verifier };
});
