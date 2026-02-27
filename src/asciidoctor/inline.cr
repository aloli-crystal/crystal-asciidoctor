require "./abstract_node"

module Asciidoctor
  # Methods for managing inline elements in AsciiDoc block
  class Inline < AbstractNode
    # The text of this inline element
    property text : String?

    # The type (qualifier) of this inline element
    getter type : Symbol?

    # The target (e.g., uri) of this inline element
    property target : String?

    # The parent block
    getter parent_block : AbstractBlock

    # The document this inline belongs to
    @document : Document

    def initialize(@parent_block : AbstractBlock, @context : Symbol, @text : String? = nil,
                   id : String? = nil, type : Symbol? = nil, target : String? = nil,
                   attributes : Hash(String, String) = {} of String => String)
      super(@context, attributes)
      @document = @parent_block.document
      @node_name = "inline_#{@context}"
      @id = id
      @type = type
      @target = target
    end

    def document : Document
      @document
    end

    def block? : Bool
      false
    end

    def inline? : Bool
      true
    end

    def convert : String
      if c = document.converter
        c.convert(self)
      else
        ""
      end
    end

    # Get the converted result of this node's primary content (aka text).
    def content : String?
      @text
    end

    # Returns the converted alt text for this inline image.
    def alt : String
      attr("alt") || ""
    end

    # For a reference node (:ref or :bibref), the text is the reftext.
    def reftext? : Bool
      !@text.nil? && (@type == :ref || @type == :bibref)
    end

    # For a reference node, the text is the reftext.
    def reftext : String?
      @text
    end

    # Generate cross reference text (xreftext) that can be used to refer
    # to this inline node.
    def xreftext(xrefstyle : String? = nil) : String?
      reftext
    end
  end
end
