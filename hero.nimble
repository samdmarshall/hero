# Package
version = "0.1"
author = "Samantha Marshall"
description = "dot file symlink creator"
license = "BSD 3-Clause"

srcDir = "src"

bin = @["hero"]

skipExt = @["nim"]

# Dependencies
requires "nim >= 0.16.0"
