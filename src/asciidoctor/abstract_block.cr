require "./abstract_node"
require "./content_model"
require "./source_location"

module Asciidoctor
  # An abstract base class that provides state and methods for managing a
  # block-level node of AsciiDoc content. Block-level nodes include Document,
  # Section, Block, List, ListItem, and Table.
  abstract class AbstractBlock < AbstractNode
    # The Array of child blocks for this block
    getter blocks : Array(AbstractBlock)

    # The caption for this block
    property caption : String?

    # Describes the type of content this block accepts
    property content_model : ContentModel

    # The Integer level of this Section or the Section to which this block belongs
    property level : Int32

    # The String numeral of this block (if section, relative to parent, otherwise absolute)
    property numeral : String?

    # The location in the AsciiDoc source where this block begins
    property source_location : SourceLocation?

    # The String style (block type qualifier) for this block
    property style : String?

    # Substitutions to be applied to content in this block
    getter subs : Substitution

    # The raw title for this block
    @title : String?

    # The converted title (memoized)
    @converted_title : String?

    # Section indexing
    @next_section_index : Int32
    @next_section_ordinal : Int32

    # Default substitutions
    @default_subs : Substitution?

    def initialize(@context : Symbol, @attributes : Hash(String, String) = {} of String => String)
      super(@context, @attributes)
      @content_model = ContentModel::Compound
      @blocks = [] of AbstractBlock
      @subs = Substitution::None
      @id = nil
      @title = nil
      @caption = nil
      @numeral = nil
      @style = nil
      @default_subs = nil
      @source_location = nil
      @converted_title = nil
      @next_section_index = 0
      @next_section_ordinal = 1
      @level = 0
    end

    def block? : Bool
      true
    end

    def inline? : Bool
      false
    end

    # Get the source file where this block started
    def file : String?
      @source_location.try(&.file)
    end

    # Get the source line number where this block started
    def lineno : Int32?
      @source_location.try(&.lineno)
    end

    # Update the context of this block.
    def context=(context : Symbol)
      @context = context
      @node_name = context.to_s
    end

    # Append a content block to this block's list of blocks.
    def <<(block : AbstractBlock) : self
      @blocks << block
      self
    end

    # Determine whether this Block contains block content
    def blocks? : Bool
      !@blocks.empty?
    end

    # Check whether this block has any child Section objects.
    def sections? : Bool
      false
    end

    # Get the Array of child Section objects
    def sections : Array(AbstractBlock)
      @blocks.select { |block| block.context == :section }
    end

    # Get the String title of this Block with title substitutions applied
    def title : String?
      @converted_title ||= @title
    end

    # A convenience method that checks whether the title is set.
    def title? : Bool
      !@title.nil?
    end

    # Set the String block title.
    def title=(val : String?)
      @converted_title = nil
      @title = val
    end

    # A convenience method that checks whether the specified
    # substitution is enabled for this block.
    def sub?(name : Substitution) : Bool
      @subs.includes?(name)
    end

    # Remove a substitution from this block
    def remove_sub(sub : Substitution) : Nil
      @subs &= ~sub
    end

    # Convenience method that returns the interpreted title of the Block
    # with the caption prepended.
    def captioned_title : String
      "#{@caption}#{title}"
    end

    # Retrieve the list marker keyword for the specified list type.
    def list_marker_keyword(list_type : String? = nil) : String?
      ORDERED_LIST_KEYWORDS[list_type || @style]?
    end

    # Get the next section index and advance the counter
    protected def next_section_index : Int32
      @next_section_index
    end

    protected def next_section_index=(val : Int32)
      @next_section_index = val
    end

    protected def next_section_ordinal : Int32
      @next_section_ordinal
    end

    protected def next_section_ordinal=(val : Int32)
      @next_section_ordinal = val
    end

    # Internal: Assign the next index and numeral to the section.
    def assign_numeral(section : Section) : Nil
      section.index = @next_section_index
      @next_section_index += 1
      if section.numbered
        if (sectname = section.sectname) == "appendix"
          # TODO: implement counter for appendix
          section.numeral = "A"
        elsif sectname == "chapter"
          # TODO: implement counter for chapter
          section.numeral = "1"
        else
          section.numeral = @next_section_ordinal.to_s
          @next_section_ordinal += 1
        end
      end
    end

    # Internal: Reassign the section indexes
    def reindex_sections : Nil
      @next_section_index = 0
      @next_section_ordinal = 1
      @blocks.each do |block|
        if block.context == :section && block.is_a?(Section)
          assign_numeral(block)
          block.reindex_sections
        end
      end
    end

    # Walk the document tree and find all block-level nodes that match the
    # specified selector.
    def find_by(context : Symbol? = nil, style : String? = nil, role : String? = nil, id : String? = nil) : Array(AbstractBlock)
      result = [] of AbstractBlock
      find_by_internal(context, style, role, id, result)
      result
    end

    protected def find_by_internal(context_selector : Symbol?, style_selector : String?, role_selector : String?, id_selector : String?, result : Array(AbstractBlock)) : Nil
      any_context = context_selector.nil?
      if (any_context || context_selector == @context) &&
         (style_selector.nil? || style_selector == @style) &&
         (role_selector.nil? || has_role?(role_selector)) &&
         (id_selector.nil? || id_selector == @id)
        result << self
        return if id_selector
      end

      @blocks.each do |b|
        next if context_selector == :section && b.context != :section
        b.find_by_internal(context_selector, style_selector, role_selector, id_selector, result)
      end
    end
  end
end
