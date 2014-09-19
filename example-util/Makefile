# Modify this to where you compiled bap
export BAP_DIR = /home/argp/bap

export OCAML_COMPAT='c'

export OCAMLFIND_IGNORE_DUPS_IN = $(BAP_DIR)/ocaml
export USE_CAMLP4 = yes

export BAP_OCAMLDIR = $(BAP_DIR)/ocaml
export LIBASMIR = $(BAP_DIR)/libasmir
export BIGINT = $(BAP_DIR)/zarith
export BATT = $(BAP_DIR)/batteries/_build/src
export OUNIT = $(BAP_DIR)/ounit/_build/src
export PCRE = $(BAP_DIR)/pcre-ocaml/lib
export OCAMLGRAPH = $(BAP_DIR)/ocamlgraph
export LIBTRACE = $(BAP_DIR)/libtracewrap/libtrace/src/ocaml
export PIQIBUILDDIR = $(BAP_DIR)/libtracewrap/libtrace/piqi/piqi/build/lib/ocaml

include $(LIBASMIR)/makefile.inc

export SOLVER = $(BAP_DIR)/solvers
include $(SOLVER)/makefile.inc

export CLIBS += $(SOLVER_CLIBS)
export LDFLAGS = $(LIBASMIR_LDFLAGS) $(SOLVER_LDFLAGS)

export OCAMLMKLIB_FLAGS = $(LDFLAGS)

export OCAMLMAKEFILE = $(BAP_DIR)/ocaml/OCamlMakefile

export PACKS = camlidl bigarray str num unix camomile piqi.lib
export LIBS = zarith batteries oUnit graph pcre libtrace bap

export INCDIRS = $(BAP_OCAMLDIR) $(BAP_OCAMLDIR)/piqi $(BIGINT) $(BATT) \
	$(OUNIT) $(PCRE) $(OCAMLGRAPH) $(LIBTRACE)

export OCAMLPATH = $(PIQIBUILDDIR)

export OCAMLFLAGS = -thread -warn-error Aelz -annot
export LDFLAGS = -rdynamic
export SOURCE_DIRS_IN = $(BAP_OCAMLDIR)
export RESULTDEPS = $(BAP_OCAMLDIR)/bap.a $(LIBASMIR)/src/libasmir.a $(LIBTRACE)/libtrace.cmxa
export LIBDIRS = $(LIBASMIR)/src
export LIBDIRS += $(SOLVER_LIBDIRS) $(LIBTRACE)

export SUBPROJS = baptest

define PROJ_baptest
        RESULT = baptest
        SOURCES = baptest.ml
endef
export PROJ_baptest

export BCSUFFIX = .dbg

all: nc dc

%:
	make -j1 -f $(OCAMLMAKEFILE) subprojs SUBTARGET=$@

# EOF
