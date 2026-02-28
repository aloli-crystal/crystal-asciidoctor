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
    # A data object representing an image reference.
    record ImageReference, target : String, imagesdir : String do
      def to_s(io : IO) : Nil
        io << @target
      end
    end

    # A data object representing a footnote.
    record Footnote, index : Int32, id : String?, text : String?

    # A data object representing a document attribute entry.
    class AttributeEntry
      getter name : String
      getter negate : Bool
      getter value : String?

      def initialize(@name : String, @value : String?, negate : Bool? = nil)
        @negate = negate.nil? ? @value.nil? : negate
      end
    end

    # Parsed and stores a partitioned title (i.e., title & subtitle).
    class Title
      getter combined : String
      getter main : String
      getter? sanitized : Bool
      getter subtitle : String?

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

    # The Author class represents information about an author.
    record Author, name : String, firstname : String, middlename : String?, lastname : String, initials : String, email : String?

    # The cached value of the backend attribute.
    getter backend : String

    # The String base directory for converting this document.
    getter base_dir : String

    # The document catalog Hash.
    getter catalog : Catalog

    # The Boolean AsciiDoc compatibility mode.
    getter? compat_mode : Bool

    # The Converter associated with this document.
    getter converter : Converter?

    # The Hash of document counters.
    getter counters : Hash(String, Int32 | String)

    # The cached value of the doctype attribute.
    getter doctype : String

    # The activated Extensions::Registry associated with this document.
    getter extensions : Extensions?

    # The level-0 Section (i.e., doctitle).
    property header : Section?

    # The Hash of resolved options.
    getter options : Hash(String, String | Bool | Int32)

    # The outfilesuffix defined at the end of the header.
    getter outfilesuffix : String

    # A reference to the parent Document of this nested document.
    getter parent_document : Document?

    # A read-only integer value indicating the level of security.
    getter safe : Int32

    # Whether source map information should be tracked by the parser.
    property? sourcemap : Bool

    # The SyntaxHighlighter associated with this document.
    getter syntax_highlighter : SyntaxHighlighter?

    def initialize(@safe : Int32 = SafeMode::SECURE,
                   @backend : String = DEFAULT_BACKEND,
                   @doctype : String = DEFAULT_DOCTYPE,
                   @base_dir : String = ".",
                   @sourcemap : Bool = false,
                   @parent_document : Document? = nil,
                   @options : Hash(String, String | Bool | Int32) = {} of String => String | Bool | Int32)
      super(:document, {} of String => String)
      @catalog = Catalog.new
      @compat_mode = false
      @converter = nil
      @counters = {} of String => Int32 | String
      @extensions = nil
      @header = nil
      @outfilesuffix = DEFAULT_EXTENSIONS[@backend.gsub(/\d+$/, "")]? || ".html"
      @syntax_highlighter = nil
    end

    # Append a content block to this block's list of blocks.
    # If the child block is a Section, assign an index to it.
    def <<(block : AbstractBlock) : self
      if block.is_a?(Section)
        assign_numeral(block)
      end
      super(block)
    end

    # Get the author.
    def author : String?
      @attributes["author"]?
    end

    # Get the Array of authors.
    def authors : Array(String)
      result = [] of String
      if (a = @attributes["author"]?)
        result << a
      end
      (2..10).each do |i|
        if (a = @attributes["author_#{i}"]?)
          result << a
        else
          break
        end
      end
      result
    end

    # Check whether the current backend matches the base backend.
    def basebackend?(base : String) : Bool
      @backend.starts_with?(base)
    end

    # Get the callouts.
    def callouts : Callouts
      @catalog.callouts
    end

    def document : Document
      self
    end

    # Get the doctitle as a String.
    def doctitle(opts : Hash(Symbol, Bool) = {} of Symbol => Bool) : String?
      if (hdr = @header)
        hdr.title
      elsif opts[:use_fallback]?
        @attributes["untitled-label"]? || "Untitled"
      else
        nil
      end
    end

    # Get the document title as a Title object.
    def doctitle_as_title(separator : String = ":") : Title?
      if dt = doctitle
        Title.new(dt, separator)
      end
    end

    # Check if the document is embedded.
    def embedded? : Bool
      @attributes.has_key?("embedded")
    end

    # Check if the document has extensions.
    def extensions? : Bool
      !@extensions.nil?
    end

    # Get the first section of the document.
    def first_section : Section?
      @blocks.each do |block|
        return block.as(Section) if block.is_a?(Section)
      end
      nil
    end

    # Get the footnotes.
    def footnotes : Array(Footnote)
      @catalog.footnotes
    end

    # Check whether this document has footnotes.
    def footnotes? : Bool
      !@catalog.footnotes.empty?
    end

    # Check whether this document has a header.
    def header? : Bool
      !@header.nil?
    end

    # Increment and store a counter.
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

    # Check if this is a multipart (book) document.
    def multipart? : Bool
      @doctype == "book" && @blocks.any? { |b| b.context == :section && b.level == 0 }
    end

    # Check if the document is nested (i.e., has a parent document).
    def nested? : Bool
      !@parent_document.nil?
    end

    # Check if the document should not render a footer.
    def nofooter : Bool
      @attributes.has_key?("nofooter")
    end

    # Check if the document should not render a header.
    def noheader : Bool
      @attributes.has_key?("noheader")
    end

    # Check if the document should not render a title.
    def notitle : Bool
      @attributes.has_key?("notitle")
    end

    # Placeholder for playback_attributes.
    def playback_attributes(attrs : Hash(String, String)) : Nil
      # TODO: implement attribute playback during conversion
    end

    # Register a reference in the document catalog.
    def register(type : Symbol, value : String | Array(String) | Tuple(String, AbstractNode)) : Nil
      case type
      when :ids
        if value.is_a?(Tuple(String, AbstractNode))
          @catalog.refs[value[0]] ||= value[1]
        end
      when :footnotes
        # handled separately
      when :images
        @catalog.images << ImageReference.new(value.as(String), @attributes["imagesdir"]? || "") if value.is_a?(String)
      when :includes
        @catalog.includes[value.as(String)] = true if value.is_a?(String)
      when :links
        @catalog.links << value.as(String) if value.is_a?(String)
      end
    end

    # Resolve a string to an id.
    def resolve_id(text : String) : String?
      @catalog.refs.each do |id, node|
        if node.is_a?(AbstractBlock)
          return id if node.title == text
        end
      end
      nil
    end

    # Placeholder for restore_attributes.
    def restore_attributes : Nil
      # TODO: implement attribute restoration during conversion
    end

    # Get the revision date.
    def revdate : String?
      @attributes["revdate"]?
    end

    # Check whether this Document has any child Section objects.
    def sections? : Bool
      next_section_index > 0
    end

    # Get the source lines of the document.
    def source_lines : Array(String)
      @attributes["source_lines"]?.try(&.split('\n')) || [] of String
    end

    # Generate cross reference text for this document.
    def xreftext(xrefstyle : String? = nil) : String?
      doctitle
    end
  end

  # The document catalog that stores references, footnotes, images, etc.
  class Catalog
    property callouts : Callouts
    property footnotes : Array(Document::Footnote)
    property images : Array(Document::ImageReference)
    property includes : Hash(String, Bool)
    property links : Array(String)
    property refs : Hash(String, AbstractNode)

    def initialize
      @callouts = Callouts.new
      @footnotes = [] of Document::Footnote
      @images = [] of Document::ImageReference
      @includes = {} of String => Bool
      @links = [] of String
      @refs = {} of String => AbstractNode
    end
  end

  # Placeholder types for future implementation.
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
