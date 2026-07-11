package invla

astType :: enum {
  ast_rat,
  ast_str,
}

astStmt :: struct {
  fnLoc: uint,
  inputs: []uint,
  outputs: []uint,
}

typedArg :: struct{
  loc: uint,
  type: astType,
}

astBlock :: struct {
  inputs, outputs: []typedArg,
  stmts: []astStmt,
}

astFuncAnon :: struct {
  registerMaxUsage: uint,
  blocks: []astBlock, // Get function's argument types by looking inside the first block
}

astRoot :: struct {
  funcs: map[string]astFuncAnon,
}
