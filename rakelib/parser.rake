# frozen_string_literal: true

# Builds the native FHIRPath parser extension (see lib/fhirpath/parser/FHIRPath.g4) using the
# antlr4-native gem. Generated/vendored sources are gitignored; run `rake parser:setup compile`
# once (and again after editing the grammar) before running specs.
namespace :parser do
  root_dir = File.expand_path("..", __dir__)
  ext_dir = File.join(root_dir, "ext/fhir_path_parser")
  grammar_file = File.join(root_dir, "lib/fhirpath/parser/FHIRPath.g4")
  runtime_dir = File.join(ext_dir, "antlr4-upstream")
  interop_file = File.join(ext_dir, "fhir_path_parser.cpp")

  desc "Clone the ANTLR4 C++ runtime version matching antlr4-native's bundled ANTLR jar"
  task :vendor_runtime do
    require "antlr4-native"

    if Dir.exist?(runtime_dir)
      puts "#{runtime_dir} already present, skipping clone"
    else
      version = Antlr4Native::Generator::ANTLR_VERSION
      sh "git clone --depth 1 --branch #{version} " \
         "https://github.com/antlr/antlr4 #{runtime_dir}"
    end
  end

  desc "Generate the ANTLR4 parser sources from FHIRPath.g4"
  task generate: :vendor_runtime do
    require "antlr4-native"

    generator = Antlr4Native::Generator.new(
      grammar_files: [grammar_file],
      output_dir: File.join(root_dir, "ext"),
      parser_root_method: "expression"
    )
    generator.generate

    # generator.generate overwrites the interop file every run, so the patches below have to
    # be re-applied here rather than committed to the generated file.
    source = File.read(interop_file)

    # ContextProxy::wrapParseTree (generated) dispatches on antlrcpp::is<T>, i.e. dynamic_cast,
    # checking context types in the order they were first seen in the parser source. Since a
    # labeled alternative's context (e.g. AdditiveExpressionContext) is a C++ subclass of its
    # rule's base context (ExpressionContext), and the base class is emitted first, dynamic_cast
    # to the *base* type succeeds first and every labeled node gets wrapped as the generic base
    # proxy — the specific label is lost. RTTI on the raw ParseTree pointer gives us the real
    # most-derived type name regardless of which proxy class wrapped it, since getText()/
    # getChildren() live on the common ContextProxy base either way.
    source = source.sub(
      "#include <iostream>",
      "#include <iostream>\n#include <cxxabi.h>\n#include <cstdlib>"
    )

    source = source.sub(
      "  bool doubleEquals(Object other) {",
      "#{<<~CPP.chomp}\n\n  bool doubleEquals(Object other) {"
        std::string getTypeName() {
          if (orig == nullptr) return "";

          int status = 0;
          char *demangled = abi::__cxa_demangle(typeid(*orig).name(), nullptr, nullptr, &status);
          std::string result = (status == 0 && demangled != nullptr)
            ? std::string(demangled)
            : std::string(typeid(*orig).name());

          if (demangled != nullptr) {
            free(demangled);
          }

          return result;
        }
      CPP
    )

    source = source.sub(
      '.define_method("==", &ContextProxy::doubleEquals);',
      ".define_method(\"==\", &ContextProxy::doubleEquals)\n" \
      '    .define_method("type_name", &ContextProxy::getTypeName);'
    )

    error_listener_class = <<~CPP
      class CountingErrorListener : public BaseErrorListener {
      public:
        size_t *counter = nullptr;

        void syntaxError(Recognizer *recognizer, Token *offendingSymbol, size_t line,
                          size_t charPositionInLine, const std::string &msg,
                          std::exception_ptr e) override {
          if (counter != nullptr) {
            (*counter)++;
          }
        }
      };

    CPP
    source = source.sub("class ParserProxy {", "#{error_listener_class}class ParserProxy {")

    source = source.sub(
      "public:\n  static ParserProxy* parse(string code) {",
      "public:\n  size_t syntaxErrorCount() { return errorCount; }\n\n" \
      "  static ParserProxy* parse(string code) {"
    )

    source = source.sub(
      /(#{Regexp.escape("FHIRPathParser* parser;")})/,
      "\\1\n  CountingErrorListener errorListener;\n  size_t errorCount = 0;"
    )

    source = source.sub(
      "parser -> parser = new FHIRPathParser(parser -> tokens);",
      <<~CPP.chomp
        parser -> parser = new FHIRPathParser(parser -> tokens);

            parser -> errorListener.counter = &parser -> errorCount;
            parser -> lexer -> removeErrorListeners();
            parser -> lexer -> addErrorListener(&parser -> errorListener);
            parser -> parser -> removeErrorListeners();
            parser -> parser -> addErrorListener(&parser -> errorListener);
      CPP
    )

    source = source.sub(
      '.define_method("visit", &ParserProxy::visit);',
      ".define_method(\"visit\", &ParserProxy::visit)\n" \
      '    .define_method("syntax_error_count", &ParserProxy::syntaxErrorCount);'
    )

    File.write(interop_file, source)
  end

  desc "Vendor the ANTLR4 C++ runtime and generate the parser sources"
  task setup: :generate

  desc "Compile the native FHIRPath parser extension"
  task :compile do
    require "etc"

    Dir.chdir(ext_dir) do
      ruby "extconf.rb"
      sh "make -j #{Etc.nprocessors}"
    end
  end
end

desc "Compile native extensions (see rake parser:setup to (re)generate their sources first)"
task compile: "parser:compile"
