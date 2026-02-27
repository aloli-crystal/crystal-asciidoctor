require "../spec_helper"

# We test AbstractNode through Block since AbstractNode is abstract
describe "AbstractNode (via Block)" do
  describe "#attr" do
    it "returns the attribute value" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.attr("role").should eq("lead")
    end

    it "returns default value when attribute is not set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.attr("missing", "default").should eq("default")
    end

    it "returns nil when attribute is not set and no default" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.attr("missing").should be_nil
    end
  end

  describe "#attr?" do
    it "returns true when attribute is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.attr?("role").should be_true
    end

    it "returns false when attribute is not set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.attr?("missing").should be_false
    end

    it "returns true when attribute matches expected value" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.attr?("role", "lead").should be_true
    end

    it "returns false when attribute does not match expected value" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.attr?("role", "other").should be_false
    end
  end

  describe "#set_attr" do
    it "sets a new attribute" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.set_attr("role", "lead").should be_true
      block.attr("role").should eq("lead")
    end

    it "overwrites existing attribute by default" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "old"})
      block.set_attr("role", "new").should be_true
      block.attr("role").should eq("new")
    end

    it "does not overwrite when overwrite is false" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "old"})
      block.set_attr("role", "new", false).should be_false
      block.attr("role").should eq("old")
    end
  end

  describe "#remove_attr" do
    it "removes an existing attribute" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.remove_attr("role").should eq("lead")
      block.attr?("role").should be_false
    end
  end

  describe "#option?" do
    it "returns true when option is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"interactive-option" => ""})
      block.option?("interactive").should be_true
    end

    it "returns false when option is not set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.option?("interactive").should be_false
    end
  end

  describe "#set_option" do
    it "sets an option" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.set_option("interactive")
      block.option?("interactive").should be_true
    end
  end

  describe "#enabled_options" do
    it "returns the set of enabled options" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"interactive-option" => "", "autoplay-option" => ""})
      opts = block.enabled_options
      opts.should contain("interactive")
      opts.should contain("autoplay")
    end
  end

  describe "#role" do
    it "returns the role attribute" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.role.should eq("lead")
    end

    it "returns nil when no role is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.role.should be_nil
    end
  end

  describe "#roles" do
    it "returns roles as array" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead center"})
      block.roles.should eq(["lead", "center"])
    end

    it "returns empty array when no role" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.roles.should be_empty
    end
  end

  describe "#has_role?" do
    it "returns true when role is present" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead center"})
      block.has_role?("lead").should be_true
    end

    it "returns false when role is not present" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.has_role?("center").should be_false
    end
  end

  describe "#add_role" do
    it "adds a new role" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.add_role("center").should be_true
      block.roles.should eq(["lead", "center"])
    end

    it "does not add a duplicate role" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.add_role("lead").should be_false
    end

    it "sets role when none exists" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.add_role("lead").should be_true
      block.role.should eq("lead")
    end
  end

  describe "#remove_role" do
    it "removes an existing role" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead center"})
      block.remove_role("lead").should be_true
      block.role.should eq("center")
    end

    it "removes the last role and deletes the attribute" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.remove_role("lead").should be_true
      block.role.should be_nil
    end

    it "returns false when role is not present" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"role" => "lead"})
      block.remove_role("center").should be_false
    end
  end

  describe "#reftext" do
    it "returns the reftext attribute" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"reftext" => "My Reference"})
      block.reftext.should eq("My Reference")
    end

    it "returns nil when no reftext" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.reftext.should be_nil
    end
  end

  describe "#reftext?" do
    it "returns true when reftext is set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph, attributes: {"reftext" => "My Reference"})
      block.reftext?.should be_true
    end

    it "returns false when reftext is not set" do
      doc = Asciidoctor::Document.new
      block = Asciidoctor::Block.new(doc, :paragraph)
      block.reftext?.should be_false
    end
  end
end
