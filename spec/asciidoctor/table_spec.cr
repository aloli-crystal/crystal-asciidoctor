require "../spec_helper"

describe Asciidoctor::Table do
  describe "#initialize" do
    it "creates a table" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      table.context.should eq(:table)
      table.columns.should be_empty
      table.rows.head.should be_empty
      table.rows.body.should be_empty
      table.rows.foot.should be_empty
    end

    it "sets default table width to 100" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      table.attributes["tablepcwidth"].should eq("100")
    end
  end

  describe "#header_row?" do
    it "returns false when has_header_option is false" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      table.header_row?.should be_false
    end

    it "returns true when has_header_option is true and body is empty" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      table.has_header_option = true
      table.header_row?.should be_true
    end
  end

  describe "Asciidoctor::Table::Rows" do
    it "provides rows by section" do
      rows = Asciidoctor::Table::Rows.new
      sections = rows.by_section
      sections.size.should eq(3)
      sections[0][0].should eq(:head)
      sections[1][0].should eq(:body)
      sections[2][0].should eq(:foot)
    end

    it "converts to hash" do
      rows = Asciidoctor::Table::Rows.new
      h = rows.to_h
      h.has_key?(:head).should be_true
      h.has_key?(:body).should be_true
      h.has_key?(:foot).should be_true
    end
  end
end

describe Asciidoctor::Table::Column do
  describe "#initialize" do
    it "creates a column with default attributes" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      col.attributes["colnumber"].should eq("1")
      col.attributes["width"].should eq("1")
      col.attributes["halign"].should eq("left")
      col.attributes["valign"].should eq("top")
    end
  end
end

describe Asciidoctor::Table::Cell do
  describe "#initialize" do
    it "creates a cell with text" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      cell = Asciidoctor::Table::Cell.new(col, "Cell content")
      cell.text.should eq("Cell content")
    end

    it "creates a cell with colspan and rowspan" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      cell = Asciidoctor::Table::Cell.new(col, "Cell", colspan: 2, rowspan: 3)
      cell.colspan.should eq(2)
      cell.rowspan.should eq(3)
    end
  end

  describe "#text" do
    it "returns the cell text" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      cell = Asciidoctor::Table::Cell.new(col, "Hello")
      cell.text.should eq("Hello")
    end
  end

  describe "#content" do
    it "returns array with single paragraph" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      cell = Asciidoctor::Table::Cell.new(col, "Single paragraph")
      cell.content.should eq(["Single paragraph"])
    end

    it "splits content on blank lines" do
      doc = Asciidoctor::Document.new
      table = Asciidoctor::Table.new(doc)
      col = Asciidoctor::Table::Column.new(table, 0)
      cell = Asciidoctor::Table::Cell.new(col, "Para 1\n\nPara 2")
      cell.content.should eq(["Para 1", "Para 2"])
    end
  end
end
