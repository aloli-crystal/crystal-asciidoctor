require "./abstract_block"
require "./safe_mode"
require "./callouts"

module Asciidoctor
  # The Document class represents a parsed AsciiDoc document.
  #
  # Document is the root node of a parsed AsciiDoc document. It provides an
  # abstract syntax tree (AST) that represents the structure of the AsciiDoc
  # document from which the Document object was parsed.
  class Document < AbstractBlock
    # A data object representing an image reference
    record ImageReference, target : String, imagesdir : String do
      def to_s(io : IO) : Nil
        io << @target
      end
    end

    # A data object representing a footnote
    record Footnote, index : Int32, id : String?, text : String?

    # A data object representing a document attribute entry
    class AttributeEntry
      getter name : String
      getter value : String?
      getter negate : Bool

      def initialize(@name : String, @value : String?, negate : Bool? = nil)
        @negate = negate.nil? ? @value.nil? : negate
      end
    end

    # Parsed and stores a partitioned title (i.e., title & subtitle).
    class Title
      getter main : String
      getter subtitle : String?
      getter combined : String
      getter? sanitized : Bool

      def initialize(val : String, separator : String = ":", sanitize : Bool = false)
        @sanitized = sanitize
        val = val.gsub(/<[^>]+>/, "").squeeze(' ').strip if sanitize && val.includes?('<')

        sep = "#{separator} "
        if separator.empty? || !val.includes?(sep)
          @main = val
          @subtitle = nil
        else
          idx = val.rindex(sep)
          if idx
            @main = val[0...idx]
            @subtitle = val[(idx + sep.size)..]
          else
            @main = val
            @subtitle = nil
          end
        end
        @combined = val
      end

      def subtitle? : Bool
        !@subtitle.nil?
      end

      def to_s(io : IO) : Nil
        io << @combined
      end
    end

    # The Author class represents information about an author
    record Author, name : String, firstname : String, middlename : String?, lastname : String, initials : String, email : String?

    # A read-only integer value indicating the level of security
    getter safe : Int32

    # The Boolean AsciiDoc compatibility mode
    getter? compat_mode : Bool

    # The cached value of the backend attribute
    getter backend : String

    # The cached value of the doctype attribute
    getter doctype : String

    # Whether source map information should be tracked by the parser
    property? sourcemap : Bool

    # The document catalog Hash
    getter catalog : Catalog

    # The Hash of document counters
    getter counters : Hash(String, Int32 | String)

    # The level-0 Section (i.e., doctitle)
    property header : Section?

    # The String base directory for converting this document
    getter base_dir : String

    # The Hash of resolved options
    getter options : Hash(String, String | Bool | Int32)

    # The outfilesuffix defined at the end of the header
    getter outfilesuffix : String

    # A reference to the parent Document of this nested document
    getter parent_document : Document?

    # The Converter associated with this document
    getter converter : Converter?

    # The SyntaxHighlighter associated with this document
    getter syntax_highlighter : SyntaxHighlighter?

    # The activated Extensions::Registry associated with this document
    getter extensions : Extensions?

    def initialize(@safe : Int32 = SafeMode::SECURE,
                   @backend : String = DEFAULT_BACKEND,
                   @doctype : String = DEFAULT_DOCTYPE,
                   @base_dir : String = ".",
                   @sourcemap : Bool = false,
                   @parent_document : Document? = nil,
                   @options : Hash(String, String | Bool | Int32) = {} of String => String | Bool | Int32)
      super(:document, {} of String => String)
      @compat_mode = false
      @counters = {} of String => Int32 | String
      @header = nil
      @outfilesuffix = DEFAULT_EXTENSIONS[@backend.gsub(/\d+$/, "")]? || ".html"
      @converter = nil
      @syntax_highlighter = nil
      @extensions = nil
      @catalog = Catalog.new
    end

    def document : Document
      self
    end

    # Check whether this document has a header
    def header? : Bool
      !@header.nil?
    end

    # Get the doctitle as a String
    def doctitle(opts : Hash(Symbol, Bool) = {} of Symbol => Bool) : String?
      if (hdr = @header)
        hdr.title
      elsif opts[:use_fallback]?
        @attributes["untitled-label"]? || "Untitled"
      else
        nil
      end
    end

    # Get the document title as a Title object
    def doctitle_as_title(separator : String = ":") : Title?
      if dt = doctitle
        Title.new(dt, separator)
      end
    end

    # Get the author
    def author : String?
      @attributes["author"]?
    end

    # Check whether this document has footnotes
    def footnotes? : Bool
      !@catalog.footnotes.empty?
    end

    # Get the footnotes
    def footnotes : Array(Footnote)
      @catalog.footnotes
    end

    # Get the callouts
    def callouts : Callouts
      @catalog.callouts
    end

    # Check if the document is nested (i.e., has a parent document)
    def nested? : Bool
      !@parent_document.nil?
    end

    # Check if the document is embedded
    def embedded? : Bool
      @attributes.has_key?("embedded")
    end

    # Register a reference in the document catalog
    def register(type : Symbol, value : String | Array(String) | Tuple(String, AbstractNode)) : Nil
      case type
      when :ids
        if value.is_a?(Tuple(String, AbstractNode))
          @catalog.refs[value[0]] ||= value[1]
        end
      when :footnotes
        # handled separately
      when :links
        @catalog.links << value.as(String) if value.is_a?(String)
      when :images
        @catalog.images << ImageReference.new(value.as(String), @attributes["imagesdir"]? || "") if value.is_a?(String)
      when :includes
        @catalog.includes[value.as(String)] = true if value.is_a?(String)
      end
    end

    # Increment and store a counter
    def increment_and_store_counter(counter_name : String, block : AbstractBlock? = nil) : String
      if (val = @counters[counter_name]?)
        case val
        when Int32
          @counters[counter_name] = val + 1
          (val + 1).to_s
        when String
          next_val = (val[0].ord + 1).chr.to_s
          @counters[counter_name] = next_val
          next_val
        else
          "1"
        end
      else
        @counters[counter_name] = 1
        "1"
      end
    end

    # Placeholder for playback_attributes
    def playback_attributes(attrs : Hash(String, String)) : Nil
      # TODO: implement attribute playback during conversion
    end
  end

  # The document catalog that stores references, footnotes, images, etc.
  class Catalog
    property refs : Hash(String, AbstractNode)
    property footnotes : Array(Document::Footnote)
    property links : Array(String)
    property images : Array(Document::ImageReference)
    property callouts : Callouts
    property includes : Hash(String, Bool)

    def initialize
      @refs = {} of String => AbstractNode
      @footnotes = [] of Document::Footnote
      @links = [] of String
      @images = [] of Document::ImageReference
      @callouts = Callouts.new
      @includes = {} of String => Bool
    end
  end

  # Placeholder types for future implementation
  class Converter
    def convert(node : AbstractNode) : String
      "" # placeholder
    end
  end

  class SyntaxHighlighter
  end

  class Extensions
  end
end
