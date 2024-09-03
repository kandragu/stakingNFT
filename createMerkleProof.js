import { StandardMerkleTree } from "@openzeppelin/merkle-tree";
import fs from "fs";

// (1)
const tree = StandardMerkleTree.load(JSON.parse(fs.readFileSync("tree.json")));

// console.log("Merkle", JSON.stringify(tree.toString()));
// (2)
for (const [i, v] of tree.entries()) {
  if (v[0] === "0x0000000000000000000000000000000000000009") {
    // (3)
    const proof = tree.getProof(i);
    console.log("Value:", v);
    console.log("Proof:", proof);
  }
}
