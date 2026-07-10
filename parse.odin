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
    beginOfBodyIndex := funcLabelIndex+1
    endOfBodyIndex:uint = len(lines) if i+1 >= len(funcLabelIndecies) else funcLabelIndecies[i+1]

    // Parse body
    bodyLines := lines[beginOfBodyIndex:endOfBodyIndex]
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
        blockIndecies[blockIndexAcc] = beginOfBodyIndex+uint(i)
        blockIndexAcc += 1
      }
    }

    for blockBeginIndex, blockIndex in blockIndecies {
      // new block
      blockEndIndex:uint = len(lines) if blockIndex+1 >= len(blockIndecies) else blockIndecies[blockIndex+1]
      stmtLines := lines[blockBeginIndex+1:blockEndIndex]
      stmts := make([]astStmt, len(stmtLines))

      stmtIndent := "" if len(stmtLines) > 0 else getIndent(stmtLines[0])

      for stmtStr, i in stmtLines {
        assert(strings.has_prefix(stmtStr, stmtIndent))
        stmt := stmtStr[len(stmtIndent):]

        // statement
        outsStr, _, callStr := strings.partition(stmt, "=")
        fnStr, _, argsStr := strings.partition(callStr, "(")
        assert(argsStr[len(argsStr)-1] == ')')
        argsStr = argsStr[:len(argsStr)-1]
        args := strings.split(outsStr, ",")
        outs := strings.split(outsStr, ",")
        fnLoc, found := slice.linear_search(primitiveNames, fnStr)
        if !found {
          assert(false, "Not implemented") // TODO implement user-made function calling
        }
        stmts[i] = {
          uint(fnLoc),
          make([]uint, len(args)),
          make([]uint, len(outs)),
        }
      }

      blocks[blockIndex] = {
        []astType{}, // TODO line should contain type info too gotten from block header, which is just `line`
        stmts,
      }
    }

    funcName := lines[funcLabelIndex]
    out.funcs[funcName] = {0, blocks} // registerMaxUsage: uint // TODO
  }
  return
}
