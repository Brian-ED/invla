# INCOMPLETE Invla, an invertible programming language
I've worked on ideas for this programming language for years but I've always delayed an actual implementation of it.
What I've decided to do is first work on a *very* simple IR with bijective primitive functions. That's what's in the repository for now.
The variables are linearly typed and the interpreter should eventually be stack based.
The IR is designed to hopefully allow for tail-call optimization, by having functions containing blocks that can `call`/`goto` eachother.

The Invla language will hopefully eventually be compiled. However, it will likely not be efficiently compiled ever, because of how high-level the language is. For example I doubt it'll ever surpass C, Zig, Rust, etc. This language has different goals though. It's a language guarenteed to be invertible.

I've proved some stuff related to the language like that the primitive functions and the stack machine are invertible [here](https://github.com/Brian-ED/inverses/).

TODO:
- When the interpreter is done I'll see if I can convert the IR into QBE IR and compile that.
