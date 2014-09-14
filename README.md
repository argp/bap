BAP: Binary Analysis Platform
=============================

This is a fork from the BAP version 0.8 release that appeared at:

https://github.com/0day1day/bap/

I am trying to keep this fork updated with patches, fixes, etc.
Feel free to fork and submit pull requests.

For more information see the official project webpage at:

http://bap.ece.cmu.edu/

For the original README of BAP see the README.orig file.

Obviously, I don't claim any credit for BAP; see the AUTHORS file
for a list of the developers.

I have tested this fork only with the following configurations:
* Ubuntu 14.04.1 (i686)
..* gcc (Ubuntu 4.8.2-19ubuntu1) 4.8.2
..* pin-2.14-67254-gcc.4.4.7-linux
..* OPAM 1.1.1
..* OCaml 4.01.0
..* All BAP's OCaml package dependencies from OPAM

* OS X 10.9.4 (no Pintool yet)
..* Apple LLVM version 5.1 (clang-503.0.40) (based on LLVM 3.4svn)
..* OPAM 1.1.1
..* OCaml 4.01.0
..* All BAP's OCaml package dependencies from OPAM
..* MacPorts 2.3.1 (see the INSTALL file)
..* libiberty from binutils 2.24 needs to be manually installed

Building on Linux
-----------------

Install all dependencies of BAP with OPAM (also see the INSTALL file).
Then download Pin version 2.14-67254-gcc.4.4.7-linux and place it at
./bap/pin. Finally do,

    ./autogen.sh
    ./configure
    make

Add the ./bap/utils directory to your path. The Pintool is at
./bap/pintraces/obj-ia32/gentrace.so.

Building on OS X
----------------

No Pintool yet.

