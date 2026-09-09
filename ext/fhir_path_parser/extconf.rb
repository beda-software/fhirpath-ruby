require "mkmf-rice"

extension_name = "fhir_path_parser"
dir_config(extension_name)

have_library("stdc++")

$CFLAGS << " -std=c++14"

# The antlr4 runtime sources below are compiled directly into this extension, never built as
# a separate DLL, so ANTLR4CPP_PUBLIC must never expand to __declspec(dllimport) (its default
# on Windows) — that would reject definitions like static data members as belonging to an
# imported class. Define it unconditionally rather than gating on --enable-static.
$defs.push("-DANTLR4CPP_STATIC") unless $defs.include?("-DANTLR4CPP_STATIC")

include_paths = [
  ".",
  "antlrgen",
  "antlr4-upstream/runtime/Cpp/runtime/src",
  "antlr4-upstream/runtime/Cpp/runtime/src/atn",
  "antlr4-upstream/runtime/Cpp/runtime/src/dfa",
  "antlr4-upstream/runtime/Cpp/runtime/src/misc",
  "antlr4-upstream/runtime/Cpp/runtime/src/support",
  "antlr4-upstream/runtime/Cpp/runtime/src/tree",
  "antlr4-upstream/runtime/Cpp/runtime/src/tree/pattern",
  "antlr4-upstream/runtime/Cpp/runtime/src/tree/xpath"
]

$srcs = []

include_paths.each do |include_path|
  $INCFLAGS << " -I#{include_path}"
  $VPATH << include_path

  Dir.glob("#{include_path}/*.cpp").each do |path|
    $srcs << path
  end
end

create_makefile(extension_name)
