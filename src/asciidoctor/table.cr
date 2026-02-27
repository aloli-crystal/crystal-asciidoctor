require "./abstract_block"
require "./abstract_node"

module Asciidoctor
  # Methods and constants for managing AsciiDoc table content in a document.
  class Table < AbstractBlock
    # Precision of column widths
    DEFAULT_PRECISION = 4

    # A data object that encapsulates the collection of rows (head, foot, body) for a table
    class Rows
      property head : Array(Array(Cell))
      property foot : Array(Array(Cell))
      property body : Array(Array(Cell))

      def initialize(@head = [] of Array(Cell), @foot = [] of Array(Cell), @body = [] of Array(Cell))
      end

      # Retrieve the rows grouped by section as a nested Array.
      def by_section : Array(Tuple(Symbol, Array(Array(Cell))))
        [{:head, @head}, {:body, @body}, {:foot, @foot}]
      end

      # Retrieve the rows as a Hash.
      def to_h : Hash(Symbol, Array(Array(Cell)))
        {:head => @head, :body => @body, :foot => @foot}
      end
    end

    # The columns for this table
    property columns : Array(Column)

    # The Rows struct for this table
    property rows : Rows

    # Boolean specifying whether this table has a header row
    property has_header_option : Bool

    # The parent block
    getter parent_block : AbstractBlock

    # The document this table belongs to
    @document : Document

    def initialize(@parent_block : AbstractBlock,
                   attributes : Hash(String, String) = {} of String => String)
      super(:table, attributes)
      @document = @parent_block.document
      @rows = Rows.new
      @columns = [] of Column
      @has_header_option = false

      # Resolve table width
      pcwidth = attributes["width"]?
      pcwidth_intval = if pcwidth
                         v = pcwidth.to_i? || 100
                         (v > 100 || v < 1) ? 100 : v
                       else
                         100
                       end
      @attributes["tablepcwidth"] = pcwidth_intval.to_s
    end

    def document : Document
      @document
    end

    # Returns the current state of the header option if the row being processed
    # is the header row, otherwise false.
    def header_row? : Bool
      @has_header_option && @rows.body.empty?
    end

    # Creates the Column objects from the column spec
    def create_columns(colspecs : Array(Hash(String, String | Int32))) : Nil
      cols = [] of Column
      colspecs.each_with_index do |colspec, idx|
        cols << Column.new(self, idx, colspec)
      end
      @columns = cols
      @attributes["colcount"] = cols.size.to_s if cols.size > 0
    end

    # Internal: Partition the rows into header, footer and body
    def partition_header_footer(attrs : Hash(String, String)) : Nil
      body = @rows.body
      num_body_rows = body.size
      @attributes["rowcount"] = num_body_rows.to_s

      if num_body_rows > 0 && @has_header_option
        @rows.head = [body.shift]
        num_body_rows -= 1
      end

      if num_body_rows > 0 && attrs.has_key?("footer-option")
        @rows.foot = [body.pop]
      end
    end
  end

  # Methods to manage the columns of an AsciiDoc table.
  class Table::Column < AbstractNode
    # The style for this column
    property style : String?

    # The parent table
    getter table : Table

    # The document this column belongs to
    @document : Document

    def initialize(@table : Table, index : Int32, attributes : Hash(String, String | Int32) = {} of String => String | Int32)
      super(:table_column, {} of String => String)
      @document = @table.document
      @style = attributes["style"]?.try(&.as(String))
      @attributes["colnumber"] = (index + 1).to_s
      @attributes["width"] = (attributes["width"]? || 1).to_s
      @attributes["halign"] = (attributes["halign"]?.try(&.as(String))) || "left"
      @attributes["valign"] = (attributes["valign"]?.try(&.as(String))) || "top"
    end

    def document : Document
      @document
    end

    def block? : Bool
      false
    end

    def inline? : Bool
      false
    end

    # Calculate and assign the widths for this column
    def assign_width(col_pcwidth : Float64?, width_base : Float64?, precision : Int32) : Float64
      if width_base
        w = @attributes["width"]?.try(&.to_f) || 1.0
        result = (w * 100.0 / width_base).round(precision)
      elsif col_pcwidth
        result = col_pcwidth
      else
        result = 0.0
      end
      @attributes["colpcwidth"] = result.to_s
      result
    end
  end

  # Methods for managing a cell in an AsciiDoc table.
  class Table::Cell < AbstractBlock
    # The number of columns this cell will span
    property colspan : Int32?

    # The number of rows this cell will span
    property rowspan : Int32?

    # The text content of this cell
    @text : String

    # The style of this cell
    property cell_style : Symbol?

    # The nested Document in an AsciiDoc table cell (only set when style is :asciidoc)
    getter inner_document : Document?

    # The parent column
    getter column : Table::Column

    # The document this cell belongs to
    @document : Document

    def initialize(@column : Table::Column, cell_text : String = "",
                   attributes : Hash(String, String) = {} of String => String,
                   colspan : Int32? = nil, rowspan : Int32? = nil,
                   style : Symbol? = nil)
      super(:table_cell, attributes)
      @document = @column.document
      @text = cell_text
      @colspan = colspan
      @rowspan = rowspan
      @cell_style = style || @column.style.try { |s| s.empty? ? nil : s.to_sym }
      @inner_document = nil
      @content_model = ContentModel::Simple
      @subs = NORMAL_SUBS
    end

    def document : Document
      @document
    end

    # Get the String text of this cell with substitutions applied.
    def text : String
      # TODO: apply_subs(@text, @subs)
      @text
    end

    # Set the String text for this cell.
    def text=(val : String)
      @text = val
    end

    # Handles the body data (tbody, tfoot), applying styles and partitioning into paragraphs
    def content : String | Array(String)
      if @cell_style == :asciidoc && (inner = @inner_document)
        inner.to_s
      elsif @text.includes?("\n\n")
        @text.split(/\n{2,}/)
      else
        [@text]
      end
    end

    def lines : Array(String)
      @text.split('\n')
    end

    def source : String
      @text
    end

    def to_s(io : IO) : Nil
      io << "#<" << self.class.name << " {text: " << @text.inspect << ", colspan: " << (@colspan || 1) << ", rowspan: " << (@rowspan || 1) << "}>"
    end
  end
end

# Helper to convert a String to a Symbol-like value
class String
  def to_sym : Symbol
    # Crystal doesn't have runtime symbol creation from strings,
    # but we can use this for known values
    raise "Cannot convert arbitrary string to symbol at runtime in Crystal"
  end
end
