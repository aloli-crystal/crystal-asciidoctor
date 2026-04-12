require "crystal-rouge"

module Asciidoctor
  # Server-side syntax highlighter adapter using crystal-rouge.
  #
  # When the document attribute `source-highlighter` is set to `rouge`,
  # this adapter performs syntax highlighting during the convert phase
  # using the crystal-rouge tokenization engine.
  class RougeAdapter < SyntaxHighlighterBase
    register_for "rouge"

    def initialize(name : String = "rouge", backend : String = "html5")
      super(name, backend)
      @pre_class = "rouge"
    end

    # Indicates that this adapter performs server-side highlighting.
    def highlight? : Bool
      true
    end

    # Highlights the source code using crystal-rouge.
    def highlight(node : AbstractNode, source : String, lang : String, opts : Hash(Symbol, String) = {} of Symbol => String) : String
      lexer = Rouge::RegexLexer.find(lang)
      if lexer
        tokens = lexer.lex(source)
        Rouge::Formatters::HTML.new.format(tokens)
      else
        # Unknown language: return source escaped
        HTML.escape(source)
      end
    end

    # Formats the highlighted source for inclusion in an HTML document.
    def format(node : AbstractNode, lang : String | Nil, opts : Hash(Symbol, String) = {} of Symbol => String) : String
      class_attr_val = "#{@pre_class} highlight"
      source_text = if node.is_a?(Block)
                      node.source || ""
                    elsif node.is_a?(AbstractBlock)
                      node.content.to_s
                    else
                      ""
                    end
      highlighted = if lang && !source_text.empty?
                      highlight(node, source_text, lang)
                    else
                      HTML.escape(source_text)
                    end
      %(<pre class="#{class_attr_val}"><code#{lang ? %( data-lang="#{lang}") : ""}>#{highlighted}</code></pre>)
    end

    # Generates the CSS stylesheet for Rouge highlighting.
    def docinfo(location : Symbol, doc : Document, opts : Hash(Symbol, String) = {} of Symbol => String) : String
      if location == :head
        theme = doc.attr("rouge-theme") || "github"
        css = case theme
              when "github" then Rouge::Themes::Github.render(scope: "pre.rouge")
              else               Rouge::Themes::Github.render(scope: "pre.rouge")
              end
        %(<style>\n#{css}\n</style>)
      else
        ""
      end
    end

    def docinfo?(location : Symbol) : Bool
      location == :head
    end
  end
end
