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

  isLineAFuncTitle := proc(line: string)->bool{return strings.trim_left_space(line) == line}

  funcLabelIndecies := make([]uint, slice.count_proc(lines, isLineAFuncTitle))

  funcIndexAcc := 0
  for line, i in lines {
    if isLineAFuncTitle(line) {
      funcLabelIndecies[funcIndexAcc] = uint(i)
      funcIndexAcc+=1
    }
  }

  for funcLabelIndex, i in funcLabelIndecies {
    nextIndex:uint = len(lines) if i+1 >= len(funcLabelIndecies) else funcLabelIndecies[i+1]

    // Parse body
    bodyLines := lines[funcLabelIndex+1:nextIndex]
    assert(len(bodyLines) > 0, "Functions require a minimum of one block, which wasn't found")
    bodyIndent := bodyLines[0][0:len(bodyLines[0]) - len(strings.trim_left_space(bodyLines[0]))]
    assert(bodyIndent != "", "INTERNAL: body indent was somehow empty which should be impossible")

    for bodyLine, i in bodyLines {
      assert(strings.has_prefix(bodyLine, bodyIndent))
      lineTrimmed := bodyLine[len(bodyIndent):]
      bodyLines[i] = lineTrimmed
    }

    isBlockTitle := proc(bodyLine: string)->bool{return strings.trim_left_space(bodyLine) == bodyLine}
    blockCount := slice.count_proc(bodyLines, isBlockTitle)

    blockNames := make([]string, blockCount)
    blockIndecies := make([]uint, blockCount)
    blocks := make([]astBlock, blockCount)

    // Just to generate the indecies so I can do a look-ahead
    blockIndexAcc := 0
    for bodyLine, i in bodyLines {
      if isBlockTitle(bodyLine) {
        blockNames[blockIndexAcc] = bodyLine // TODO line should contain type info too, rn it's assumed to just be name of block
        blockIndecies[blockIndexAcc] = funcLabelIndex+1+uint(i)
        blockIndexAcc += 1
      }
    }

    for blockBeginIndex, blockIndex in blockIndecies {
      // new block
      blockEndIndex: uint
      if blockIndex+1 >= len(blockIndecies) {
        blockEndIndex = len(lines)
      } else {
        blockEndIndex = blockIndecies[blockIndex+1]
      }
      stmtLines := lines[blockBeginIndex+1:blockEndIndex]
      stmts := make([]astStmt, len(stmtLines))

      stmtIndent := ""
      if len(stmtLines) > 0 {
        stmtIndent = stmtLines[0][:len(stmtLines[0]) - len(strings.trim_left_space(stmtLines[0])) ]
      }

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
