require "../spec_helper"

describe Asciidoctor::List do
  describe "#initialize" do
    it "creates an unordered list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      list.context.should eq(:ulist)
      list.items.should be_empty
    end

    it "creates an ordered list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :olist)
      list.context.should eq(:olist)
    end
  end

  describe "#outline?" do
    it "returns true for unordered list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      list.outline?.should be_true
    end

    it "returns true for ordered list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :olist)
      list.outline?.should be_true
    end

    it "returns false for description list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :dlist)
      list.outline?.should be_false
    end
  end

  describe "#items?" do
    it "returns false when empty" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      list.items?.should be_false
    end
  end
end

describe Asciidoctor::ListItem do
  describe "#initialize" do
    it "creates a list item with text" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list, "Item text")
      item.text.should eq("Item text")
    end

    it "creates a list item without text" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list)
      item.text?.should be_false
    end
  end

  describe "#text?" do
    it "returns true when text is set" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list, "Hello")
      item.text?.should be_true
    end

    it "returns false when text is nil" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list)
      item.text?.should be_false
    end
  end

  describe "#simple?" do
    it "returns true when no child blocks" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list, "Simple item")
      item.simple?.should be_true
    end
  end

  describe "#list" do
    it "returns the parent list" do
      doc = Asciidoctor::Document.new
      list = Asciidoctor::List.new(doc, :ulist)
      item = Asciidoctor::ListItem.new(list, "Item")
      item.list.should eq(list)
    end
  end
end
