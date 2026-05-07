require "./asciidoctor/callouts"
require "./asciidoctor/constants"
require "./asciidoctor/content_model"
require "./asciidoctor/helpers"
require "./asciidoctor/logging"
require "./asciidoctor/path_resolver"
require "./asciidoctor/rx"
require "./asciidoctor/safe_mode"
require "./asciidoctor/source_location"
require "./asciidoctor/substitution"
require "./asciidoctor/substitutors"
require "./asciidoctor/timings"
require "./asciidoctor/writer"
require "./asciidoctor/abstract_node"
require "./asciidoctor/abstract_block"
require "./asciidoctor/attribute_list"
require "./asciidoctor/block"
require "./asciidoctor/converter/base"
require "./asciidoctor/converter"
require "./asciidoctor/converter/composite"
require "./asciidoctor/converter/template"
require "./asciidoctor/syntax_highlighter"
require "./asciidoctor/syntax_highlighter/highlightjs"
require "./asciidoctor/syntax_highlighter/prettify"
require "./asciidoctor/syntax_highlighter/rouge"
require "./asciidoctor/stylesheets"
require "./asciidoctor/document"
require "./asciidoctor/extensions"
require "./asciidoctor/inline"
require "./asciidoctor/list"
require "./asciidoctor/parser"
require "./asciidoctor/reader"
require "./asciidoctor/section"
require "./asciidoctor/table"
require "./asciidoctor/converter/docbook5"
require "./asciidoctor/converter/html5"
require "./asciidoctor/converter/manpage"
require "./asciidoctor/api"
require "./asciidoctor/cli/options"
require "./asciidoctor/cli/invoker"

# Custom exception for security violations (does not exist in Crystal stdlib).
class SecurityError < Exception
end

module Asciidoctor
  # Lue au compile-time depuis `shard.yml` via le macro `read_file`.
  # Cf. note mémoire `feedback_shard_version_macro.md` (mémoire ALOLI).
  VERSION = {{
              (read_file("#{__DIR__}/../shard.yml")
                .lines
                .find(&.starts_with?("version:")) || "version: 0.0.0")
                .gsub(/^version:\s*/, "")
                .chomp
            }}

  # Version de la gem Ruby Asciidoctor utilisée comme base du portage.
  UPSTREAM_VERSION = "2.0.26"
end
