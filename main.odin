#+feature dynamic-literals
package invla

import "core:fmt"
import "core:os"
import "core:strings"

value :: union {
  int,
  string,
}

primitivePrint :: proc(args, rets: []value) {
  assert(len(args) == 1 && len(rets) == 0)
  fmt.println(args[0])
}
primitiveMakeTestString :: proc(args, rets: []value) {
  assert(len(args) == 0 && len(rets) == 1)
  rets[0] = "Hello world!"
}

primitives := []proc(args, rets: []value) {
  primitivePrint,
  primitiveMakeTestString,
};
primitiveNames: []string = {"print", "makeHello"}

main :: proc() {
  test: astRoot = {
    map[string]astFuncAnon{
      "main" = {
        registerMaxUsage = 1,
        blocks = {
          astBlock{
            {}, {},
            []astStmt{
              astStmt{
                1,
                []uint{},
                []uint{0},
              },
              astStmt{
                0,
                []uint{0},
                []uint{},
              },
            },
          },
        },
      },
    },
  };

  testInvlaCode, err := os.read_entire_file_from_path("test.txt", context.allocator)
  assert(err == nil, "File wasn't read successfully")

  fmt.println(parseRoot(strings.clone_from_bytes(testInvlaCode)));
  interpretRoot(test, []string{})
}
