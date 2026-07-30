require "../spec_helper"

describe Asciicrystal::ContentModel do
  it "defines Compound" do
    Asciicrystal::ContentModel::Compound.should_not be_nil
  end

  it "defines Simple" do
    Asciicrystal::ContentModel::Simple.should_not be_nil
  end

  it "defines Verbatim" do
    Asciicrystal::ContentModel::Verbatim.should_not be_nil
  end

  it "defines Raw" do
    Asciicrystal::ContentModel::Raw.should_not be_nil
  end

  it "defines Empty" do
    Asciicrystal::ContentModel::Empty.should_not be_nil
  end
end
