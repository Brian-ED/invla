package invla

import "core:strings"
import "base:runtime"
import "core:slice"
import "core:fmt"

parseMode :: enum {
  normal,
  makingFn,
  makingBlock,
}

getIndent :: proc(referenceLine: string)->string {
  return referenceLine[:len(referenceLine) - len(strings.trim_left_space(referenceLine))]
}

hasWhitespacePrefix :: proc(bodyLine: string)->bool {
  return strings.trim_left_space(bodyLine) == bodyLine
}

parseStmt :: proc(stmt: string, seenNamesInFn: ^[dynamic]string)->astStmt {
  outsStr, _, callStr := strings.partition(stmt, "=")
  fnStr, _, argsStr := strings.partition(callStr, "(")
  assert(argsStr[len(argsStr)-1] == ')')
  argsStr = argsStr[:len(argsStr)-1]
  args := strings.split(outsStr, ",")
  outs := strings.split(outsStr, ",")
  fnLoc, found := slice.linear_search(primitiveNames, fnStr)
  if !found {
    assert(false, "INTERNAL: Not implemented") // TODO implement user-made function calling
  }
  inputs := make([]uint, len(args))
  outputs := make([]uint, len(outs))

  // Potential optimization here is instead of linear search for every arg you could *atleast*
  // insert the strings such that it's ordered and finding is O(log(n))... But also
  // you can use hashes or some set-based impl

  for arg, i in args {
    seen := false
    nameIndex: uint
    for name, i in seenNamesInFn {
      if (name == arg) {
        seen := true
        nameIndex := i
        break
      }
    }
    if !seen {
      nameIndex = len(seenNamesInFn)
      append(&seenNamesInFn^, arg)
    }
    inputs[i] = nameIndex
  }

  for out, i in outs {
    seen := false
    nameIndex: uint
    for name, i in seenNamesInFn {
      if (name == out) {
        seen := true
        nameIndex := i
        break
      }
    }
    if !seen {
      nameIndex = len(seenNamesInFn)
      append(&seenNamesInFn^, out)
    }
    outputs[i] = nameIndex
  }
  return {
    uint(fnLoc),
    inputs,
    outputs,
  }
}

parseBlock :: proc(blockLines: []string, seenNamesInFn: ^[dynamic]string)->(blockName: string, block: astBlock) {
  blockName = blockLines[0]

  stmtLines := blockLines[1:]
  stmts := make([]astStmt, len(stmtLines))

  stmtIndent := "" if len(stmtLines) == 0 else getIndent(stmtLines[0])

  for stmtStr, i in stmtLines {
    assert(strings.has_prefix(stmtStr, stmtIndent))
    stmts[i] = parseStmt(stmtStr[len(stmtIndent):], &seenNamesInFn^)
  }

  block = {
    []astType{}, // TODO line should contain type info too gotten from block header, which is just `line`
    stmts,
  }
  return
}

// Parsing a function involves getting the header/title,
// and the body which is a series of blocks
parseFunc :: proc(funcLines: []string)->(funcName: string, funcAnon: astFuncAnon) {
  funcName = funcLines[0]
  bodyLines := funcLines[1:]

  assert(len(bodyLines) > 0, "Functions require a minimum of one block, which wasn't found")
  bodyIndent := getIndent(bodyLines[0])
  assert(bodyIndent != "", "INTERNAL: body indent was somehow empty which should be impossible")

  // Trim indent from body lines
  for bodyLine, i in bodyLines {
    assert(strings.has_prefix(bodyLine, bodyIndent))
    bodyLines[i] = bodyLine[len(bodyIndent):]
  }

  blockCount := slice.count_proc(bodyLines, hasWhitespacePrefix)

  blockNames := make([]string, blockCount)
  blockIndecies := make([]uint, blockCount)
  blocks := make([]astBlock, blockCount)

  // Just to generate the indecies so I can do a look-ahead
  blockIndexAcc := 0
  for bodyLine, i in bodyLines {
    if hasWhitespacePrefix(bodyLine) {
      blockNames[blockIndexAcc] = bodyLine // TODO line should contain type info too, rn it's assumed to just be name of block
      blockIndecies[blockIndexAcc] = uint(i)
      blockIndexAcc += 1
    }
  }

  seenNamesInFn: [dynamic]string = {}
  defer delete(seenNamesInFn)

  for blockBeginIndex, blockIndex in blockIndecies {
    // new block
    blockEndIndex:uint = len(bodyLines) if blockIndex+1 == len(blockIndecies) else blockIndecies[blockIndex+1]
    blockName, block := parseBlock(bodyLines[blockBeginIndex:blockEndIndex], &seenNamesInFn)
    blocks[blockIndex] = block
  }

  funcAnon = {0, blocks}

  return
}

parseRoot :: proc(s: string)->(out: astRoot) {
  lines := strings.split_lines(s)

  for line, i in lines {
    endIndex := strings.index_byte(line, '#')
    if endIndex == -1 {endIndex = len(line)}
    lines[i] = strings.trim_right_space(
      line[:endIndex]
    )
  }

  lines = slice.filter(lines, proc(x: string)->bool{return x!=""})

  funcLabelIndecies := make([]uint, slice.count_proc(lines, hasWhitespacePrefix))

  funcIndexAcc := 0
  for line, i in lines {
    if hasWhitespacePrefix(line) {
      funcLabelIndecies[funcIndexAcc] = uint(i)
      funcIndexAcc+=1
    }
  }

  for funcLabelIndex, i in funcLabelIndecies {
    endOfFuncIndex:uint = len(lines) if i+1 >= len(funcLabelIndecies) else funcLabelIndecies[i+1]

    funcName, func := parseFunc(lines[funcLabelIndex:endOfFuncIndex])

    out.funcs[funcName] = func // registerMaxUsage: uint // TODO
  }
  return
}
