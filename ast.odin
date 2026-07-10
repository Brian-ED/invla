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

astBlock :: struct {
  argTypes: []astType,
  stmts: []astStmt,
}

astFuncAnon :: struct {
  registerMaxUsage: uint,
  blocks: []astBlock, // Get function's argument types by looking inside the first block
}

astRoot :: struct {
  funcs: map[string]astFuncAnon,
}
