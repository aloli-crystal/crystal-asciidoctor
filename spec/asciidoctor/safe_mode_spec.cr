require "../spec_helper"

describe Asciicrystal::SafeMode do
  describe "constants" do
    it "defines UNSAFE as 0" do
      Asciicrystal::SafeMode::UNSAFE.should eq(0)
    end

    it "defines SAFE as 1" do
      Asciicrystal::SafeMode::SAFE.should eq(1)
    end

    it "defines SERVER as 10" do
      Asciicrystal::SafeMode::SERVER.should eq(10)
    end

    it "defines SECURE as 20" do
      Asciicrystal::SafeMode::SECURE.should eq(20)
    end
  end

  describe ".name_for_value" do
    it "returns 'unsafe' for UNSAFE value" do
      Asciicrystal::SafeMode.name_for_value(0).should eq("unsafe")
    end

    it "returns 'safe' for SAFE value" do
      Asciicrystal::SafeMode.name_for_value(1).should eq("safe")
    end

    it "returns 'server' for SERVER value" do
      Asciicrystal::SafeMode.name_for_value(10).should eq("server")
    end

    it "returns 'secure' for SECURE value" do
      Asciicrystal::SafeMode.name_for_value(20).should eq("secure")
    end

    it "returns nil for unknown value" do
      Asciicrystal::SafeMode.name_for_value(99).should be_nil
    end
  end

  describe ".value_for_name" do
    it "returns UNSAFE for 'UNSAFE'" do
      Asciicrystal::SafeMode.value_for_name("UNSAFE").should eq(0)
    end

    it "returns SAFE for 'safe' (case insensitive)" do
      Asciicrystal::SafeMode.value_for_name("safe").should eq(1)
    end

    it "returns nil for unknown name" do
      Asciicrystal::SafeMode.value_for_name("unknown").should be_nil
    end
  end

  describe ".names" do
    it "returns all safe mode names" do
      names = Asciicrystal::SafeMode.names
      names.should contain("unsafe")
      names.should contain("safe")
      names.should contain("server")
      names.should contain("secure")
    end
  end
end
