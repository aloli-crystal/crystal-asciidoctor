require "./abstract_block"

module Asciidoctor
  # Methods for managing sections of AsciiDoc content in a document.
  # The section responds as an Array of content blocks by delegating
  # block-related methods to its @blocks Array.
  class Section < AbstractBlock
    # The 0-based index order of this section within the parent block
    property index : Int32

    # The section name of this section
    property sectname : String?

    # Flag to indicate whether this is a special section or a child of one
    property special : Bool

    # Flag to indicate whether this section should be numbered
    property numbered : Bool

    # The parent block
    getter parent_block : AbstractBlock?

    # The document this section belongs to
    @document : Document

    def initialize(document : Document, parent : AbstractBlock? = nil, level : Int32? = nil, numbered : Bool = false, attributes : Hash(String, String) = {} of String => String)
      super(:section, attributes)
      @document = document
      @parent_block = parent
      if parent.is_a?(Section)
        @level = level || (parent.level + 1)
        @special = parent.special
      else
        @level = level || 1
        @special = false
      end
      @numbered = numbered
      @index = 0
      @sectname = nil
    end

    def document : Document
      @document
    end

    # The name of this section, an alias of the section title
    def name : String?
      title
    end

    # Check whether this Section has any child Section objects.
    def sections? : Bool
      next_section_index > 0
    end

    # Get the section number for the current Section.
    #
    # The section number is a dot-separated String that uniquely describes
    # the position of this Section in the document.
    def sectnum(delimiter : String = ".", append : String? = nil) : String
      actual_append = append || delimiter
      if @level > 1 && (p = @parent_block).is_a?(Section)
        "#{p.sectnum(delimiter, delimiter)}#{@numeral}#{actual_append}"
      else
        "#{@numeral}#{actual_append}"
      end
    end

    # Append a content block to this block's list of blocks.
    # If the child block is a Section, assign an index to it.
    def <<(block : AbstractBlock) : self
      if block.is_a?(Section)
        assign_numeral(block)
      end
      super(block)
    end

    def to_s(io : IO) : Nil
      if t = @title
        formal_title = @numbered ? "#{sectnum} #{t}" : t
        io << "#<" << self.class.name << " {level: " << @level << ", title: " << formal_title.inspect << ", blocks: " << @blocks.size << "}>"
      else
        io << "#<" << self.class.name << " {level: " << @level << ", blocks: " << @blocks.size << "}>"
      end
    end
  end
end
