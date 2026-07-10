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

parseRoot :: proc(s: string)->astRoot {
  strs := strings.split_lines(s)

  for str, i in strs {
    endIndex := strings.index_byte(str, '#')
    if endIndex == -1 {endIndex = len(str)}
    strs[i] = strings.trim_right_space(
      str[:endIndex]
    )
  }

  strs = slice.filter(strs, proc(x: string)->bool{return x!=""})

  funcMapOutput := runtime.make_map(map[string]astFuncAnon)

  funcCount := 0
  for str in strs {
    if strings.trim_left_space(str) == str {
      funcCount += 1
    }
  }
  funcNameIndecies := make([]uint, funcCount)

  funcIndex := 0
  for str, strIndex in strs {
    if strings.trim_left_space(str) == str {
      funcNameIndecies[funcIndex] = uint(strIndex)
      funcIndex+=1
    }
  }

  for i in 0..<funcCount {
    registerMaxUsage: uint

    currentIndex := funcNameIndecies[i]
    nextIndex: uint
    if i+1 >= funcCount {
      nextIndex = len(strs)
    } else {
      nextIndex = funcNameIndecies[i+1]
    }

    // Parse body
    bodyStrs := strs[currentIndex+1:nextIndex]
    assert(len(bodyStrs) > 0)
    bodyIndent := bodyStrs[0][0:len(bodyStrs[0]) - len(strings.trim_left_space(bodyStrs[0]))]
    assert(bodyIndent != "")

    blockCount: uint

    for line, i in bodyStrs {
      assert(strings.has_prefix(line, bodyIndent))
      lineTrimmed := line[len(bodyIndent):]
      bodyStrs[i] = lineTrimmed
      if strings.trim_left_space(lineTrimmed) == lineTrimmed {
        blockCount += 1
      }
    }

    blockNames := make([]string, blockCount)
    blockIndecies := make([]uint, blockCount)
    blocks := make([]astBlock, blockCount)

    // Just to generate the indecies so I can do a look-ahead
    blockIndex := 0
    for line, i in bodyStrs {
      if strings.trim_left_space(line) == line {
        blockNames[blockIndex] = line // TODO line should contain type info too, rn it's assumed to just be name of block
        blockIndecies[blockIndex] = currentIndex+1+uint(i)
        blockIndex += 1
      }
    }

    for blockBeginIndex, blockIndex in blockIndecies {
      // new block
      blockEndIndex: uint
      if blockIndex+1 >= len(blockIndecies) {
        blockEndIndex = len(strs)
      } else {
        blockEndIndex = blockIndecies[blockIndex+1]
      }
      fmt.println(strs[blockBeginIndex])
      stmtStrs := strs[blockBeginIndex+1:blockEndIndex]
      fmt.println(stmtStrs)
      stmts := make([]astStmt, len(stmtStrs))

      stmtIndent := ""
      if len(stmtStrs) > 0 {
        stmtIndent = stmtStrs[0][: len(stmtStrs[0]) - len(strings.trim_left_space(stmtStrs[0])) ]
      }

      for stmtStr, i in stmtStrs {
        fmt.println(stmtStr)
        fmt.println(stmtIndent == "")
        fmt.println("next")
        assert(strings.has_prefix(stmtStr, stmtIndent))
        stmt := stmtStr[len(stmtIndent):]

        // statement
        outsStr, _, callStr := strings.partition(stmt, "=")
        fnStr, _, argsStr := strings.partition(callStr, "(")
        assert(argsStr[len(argsStr)-1] == ')')
        argsStr = argsStr[:len(argsStr)-1]
        fmt.println(outsStr)
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

    funcName := strs[currentIndex]
    funcMapOutput[funcName] = {registerMaxUsage, blocks}
  }

  return {funcMapOutput}
}
