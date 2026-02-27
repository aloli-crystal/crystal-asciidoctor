# crystal-asciidoctor

A Crystal port of the [Asciidoctor](https://github.com/asciidoctor/asciidoctor) document processor.

This shard provides an Abstract Syntax Tree (AST) model for AsciiDoc documents, faithfully ported from the Ruby implementation. It is the foundation for a full AsciiDoc processing pipeline in Crystal.

## Status

**Work in progress** — This shard currently implements the AST data model only. The parser and converters will be added in future iterations.

### Implemented

| Component | Crystal module | Ruby source |
|---|---|---|
| Abstract node (base class) | `Asciidoctor::AbstractNode` | `abstract_node.rb` |
| Abstract block | `Asciidoctor::AbstractBlock` | `abstract_block.rb` |
| Document | `Asciidoctor::Document` | `document.rb` |
| Block | `Asciidoctor::Block` | `block.rb` |
| Section | `Asciidoctor::Section` | `section.rb` |
| Inline | `Asciidoctor::Inline` | `inline.rb` |
| List / ListItem | `Asciidoctor::List`, `Asciidoctor::ListItem` | `list.rb` |
| Table / Column / Cell | `Asciidoctor::Table`, `Table::Column`, `Table::Cell` | `table.rb` |
| Callouts | `Asciidoctor::Callouts` | `callouts.rb` |
| Document catalog | `Asciidoctor::Catalog` | (part of `document.rb`) |
| Content model (enum) | `Asciidoctor::ContentModel` | (symbols in Ruby) |
| Substitution (flags enum) | `Asciidoctor::Substitution` | `substitutors.rb` |
| Safe mode | `Asciidoctor::SafeMode` | (constants in `asciidoctor.rb`) |
| Source location | `Asciidoctor::SourceLocation` | (part of `abstract_block.rb`) |
| Constants | `Asciidoctor::*` | `asciidoctor.rb` |

### Not yet implemented

- Lexer / Parser
- Converters (HTML5, DocBook, Manpage)
- Extensions API
- Syntax highlighting integration
- CLI

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  crystal-asciidoctor:
    github: papilip/crystal-asciidoctor
```

Run `shards install`.

## Usage

```crystal
require "crystal-asciidoctor"

# Create a document
doc = Asciidoctor::Document.new

# Create a section
section = Asciidoctor::Section.new(doc, level: 1, numbered: true)
section.title = "Introduction"
doc << section

# Create a paragraph block
para = Asciidoctor::Block.new(section, :paragraph, source: "Hello, AsciiDoc!")
section << para

# Create an inline node
inline = Asciidoctor::Inline.new(para, :anchor, "click here", type: :xref, target: "#intro")

# Traverse the tree
doc.find_by(context: :paragraph).each do |block|
  puts block.as(Asciidoctor::Block).source
end
```

## Development

```sh
# Run all tests
crystal spec

# Type-check without codegen
crystal build --no-codegen src/crystal-asciidoctor.cr
```

## Contributing

1. Fork it (<https://github.com/papilip/crystal-asciidoctor/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgements

This project is a Crystal port of [Asciidoctor](https://github.com/asciidoctor/asciidoctor), originally written in Ruby by Dan Allen, Sarah White, and the Asciidoctor community. The AST model follows the same architecture and naming conventions as the original.
