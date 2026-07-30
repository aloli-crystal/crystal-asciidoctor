require "./asciicrystal/callouts"
require "./asciicrystal/constants"
require "./asciicrystal/content_model"
require "./asciicrystal/helpers"
require "./asciicrystal/logging"
require "./asciicrystal/path_resolver"
require "./asciicrystal/rx"
require "./asciicrystal/safe_mode"
require "./asciicrystal/source_location"
require "./asciicrystal/substitution"
require "./asciicrystal/substitutors"
require "./asciicrystal/timings"
require "./asciicrystal/writer"
require "./asciicrystal/abstract_node"
require "./asciicrystal/abstract_block"
require "./asciicrystal/attribute_list"
require "./asciicrystal/block"
require "./asciicrystal/converter/base"
require "./asciicrystal/converter"
require "./asciicrystal/converter/composite"
require "./asciicrystal/converter/template"
require "./asciicrystal/syntax_highlighter"
require "./asciicrystal/syntax_highlighter/highlightjs"
require "./asciicrystal/syntax_highlighter/prettify"
require "./asciicrystal/syntax_highlighter/rouge"
require "./asciicrystal/stylesheets"
require "./asciicrystal/document"
require "./asciicrystal/extensions"
require "./asciicrystal/inline"
require "./asciicrystal/list"
require "./asciicrystal/parser"
require "./asciicrystal/reader"
require "./asciicrystal/section"
require "./asciicrystal/table"
require "./asciicrystal/converter/docbook5"
require "./asciicrystal/converter/html5"
require "./asciicrystal/converter/manpage"
require "./asciicrystal/api"
require "./asciicrystal/cli/options"
require "./asciicrystal/cli/invoker"

# Custom exception for security violations (does not exist in Crystal stdlib).
class SecurityError < Exception
end

module Asciicrystal
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
