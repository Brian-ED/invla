package invla

import "core:fmt"

interpretRoot :: proc(root: astRoot, args: []string) {
  // TODO handle args when you add an array-like type
  currentFn := root.funcs["main"];
  currentBlock := currentFn.blocks[0];
  currentRegisters := make_slice([]value, currentFn.registerMaxUsage);
  for stmt in currentBlock.stmts {
    if stmt.fnLoc < len(primitives) {
      // Handle primitive function call
      inputsForCall := make([]value, len(stmt.inputs))
      for i, inp in stmt.inputs {
        inputsForCall[i] = currentRegisters[inp]
      }
      outs := make([]value, len(stmt.outputs))
      primitives[stmt.fnLoc](inputsForCall, outs) // TODO replace []value{}
      for i, outReg in stmt.outputs {
        currentRegisters[outReg] = outs[i]
      }
    } else {
      // TODO Handle non-primitive function call
    }
  }
}
