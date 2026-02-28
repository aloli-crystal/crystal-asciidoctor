require "../spec_helper"

describe Asciidoctor::PathResolver do
  describe "Web Paths" do
    it "target with absolute path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("/images").should eq("/images")
      resolver.web_path("/images", "").should eq("/images")
      resolver.web_path("/images", nil).should eq("/images")
    end

    it "target with relative path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("images").should eq("images")
      resolver.web_path("images", "").should eq("images")
      resolver.web_path("images", nil).should eq("images")
    end

    it "target with hidden relative path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path(".images").should eq(".images")
      resolver.web_path(".images", "").should eq(".images")
      resolver.web_path(".images", nil).should eq(".images")
    end

    it "target with path relative to current directory" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("./images").should eq("./images")
      resolver.web_path("./images", "").should eq("./images")
      resolver.web_path("./images", nil).should eq("./images")
    end

    it "target with absolute path ignores start path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("/images", "foo").should eq("/images")
      resolver.web_path("/images", "/foo").should eq("/images")
      resolver.web_path("/images", "./foo").should eq("/images")
    end

    it "target with relative path appended to start path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("images", "assets").should eq("assets/images")
      resolver.web_path("images", "/assets").should eq("/assets/images")
      resolver.web_path("images", "./assets").should eq("./assets/images")
      resolver.web_path("theme.css", "/").should eq("/theme.css")
      resolver.web_path("theme.css", "/css/").should eq("/css/theme.css")
    end

    it "target with path relative to current directory appended to start path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("./images", "assets").should eq("assets/images")
      resolver.web_path("./images", "/assets").should eq("/assets/images")
      resolver.web_path("./images", "./assets").should eq("./assets/images")
    end

    it "target with relative path appended to url start path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("images", "http://www.example.com/assets").should eq("http://www.example.com/assets/images")
    end

    it "normalize target" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("../images/../images").should eq("../images")
    end

    it "append target to start path and normalize" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("../images/../images", "../images").should eq("../images")
      resolver.web_path("../images", "..").should eq("../../images")
    end

    it "normalize parent directory that follows root" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("/../tiger.png").should eq("/tiger.png")
      resolver.web_path("/../../tiger.png").should eq("/tiger.png")
    end

    it "uses start when target is empty" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("", "assets/images").should eq("assets/images")
      resolver.web_path(nil, "assets/images").should eq("assets/images")
    end

    it "posixifies windows paths" do
      resolver = Asciidoctor::PathResolver.new(file_separator: "\\")
      resolver.web_path("\\images").should eq("/images")
      resolver.web_path("..\\images").should eq("../images")
      resolver.web_path("\\..\\images").should eq("/images")
      resolver.web_path("assets\\images").should eq("assets/images")
      resolver.web_path("assets\\images", "..\\images\\..").should eq("../assets/images")
    end

    it "URL encode spaces in path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_path("lots of images", "assets and stuff").should eq("assets%20and%20stuff/lots%20of%20images")
    end
  end

  describe "System Paths" do
    jail = "/home/doctor/docs"

    it "raises security error if jail is not an absolute path" do
      resolver = Asciidoctor::PathResolver.new
      expect_raises(SecurityError) do
        resolver.system_path("images/tiger.png", "/etc", "foo")
      end
    end

    it "prevents access to paths outside of jail" do
      resolver = Asciidoctor::PathResolver.new
      result = resolver.system_path("../../../../../css", "#{jail}/assets/stylesheets", jail)
      result.should eq("#{jail}/css")
    end

    it "throws exception for illegal path access if recover is false" do
      resolver = Asciidoctor::PathResolver.new
      expect_raises(SecurityError) do
        resolver.system_path("../../../../../css", "#{jail}/assets/stylesheets", jail, {:recover => false})
      end
    end

    it "resolves start path if target is empty" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("", "#{jail}/assets/stylesheets", jail).should eq("#{jail}/assets/stylesheets")
      resolver.system_path(nil, "#{jail}/assets/stylesheets", jail).should eq("#{jail}/assets/stylesheets")
    end

    it "expands parent references in start path if target is empty" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("", "#{jail}/assets/../stylesheets", jail).should eq("#{jail}/stylesheets")
    end

    it "expands parent references in start path if target is not empty" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("site.css", "#{jail}/assets/../stylesheets", jail).should eq("#{jail}/stylesheets/site.css")
    end

    it "resolves start path if target is dot" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path(".", "#{jail}/assets/stylesheets", jail).should eq("#{jail}/assets/stylesheets")
      resolver.system_path("./", "#{jail}/assets/stylesheets", jail).should eq("#{jail}/assets/stylesheets")
    end

    it "treats absolute target outside of jail as relative when jail is specified" do
      resolver = Asciidoctor::PathResolver.new
      result = resolver.system_path("/", "#{jail}/assets/stylesheets", jail)
      result.should eq(jail)

      result = resolver.system_path("/foo", "#{jail}/assets/stylesheets", jail)
      result.should eq("#{jail}/foo")

      result = resolver.system_path("/../foo", "#{jail}/assets/stylesheets", jail)
      result.should eq("#{jail}/foo")
    end

    it "allows use of absolute target or start if resolved path is sub-path of jail" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("#{jail}/my/path", "", jail).should eq("#{jail}/my/path")
      resolver.system_path("#{jail}/my/path", nil, jail).should eq("#{jail}/my/path")
      resolver.system_path("", "#{jail}/my/path", jail).should eq("#{jail}/my/path")
      resolver.system_path(nil, "#{jail}/my/path", jail).should eq("#{jail}/my/path")
      resolver.system_path("path", "#{jail}/my", jail).should eq("#{jail}/my/path")
      resolver.system_path("/foo/bar/baz.adoc", nil, "/").should eq("/foo/bar/baz.adoc")
      resolver.system_path("baz.adoc", "/foo/bar", "/").should eq("/foo/bar/baz.adoc")
      resolver.system_path("baz.adoc", "foo/bar", "/").should eq("/foo/bar/baz.adoc")
    end

    it "uses jail path if start path is empty" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("images/tiger.png", "", jail).should eq("#{jail}/images/tiger.png")
      resolver.system_path("images/tiger.png", nil, jail).should eq("#{jail}/images/tiger.png")
    end

    it "warns if start is not contained within jail" do
      resolver = Asciidoctor::PathResolver.new
      result = resolver.system_path("images/tiger.png", "/etc", jail)
      result.should eq("#{jail}/images/tiger.png")

      result = resolver.system_path(".", "/etc", jail)
      result.should eq(jail)
    end

    it "expands parent references in absolute path if jail is not specified" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("/usr/share/../../etc/stylesheet.css").should eq("/etc/stylesheet.css")
    end

    it "resolves absolute path if start is absolute and target is relative" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("assets/stylesheet.css", "/usr/share").should eq("/usr/share/assets/stylesheet.css")
    end

    it "resolves UNC path if start is absolute and target is relative" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("assets/stylesheet.css", "//QA/c$/users/asciidoctor").should eq("//QA/c$/users/asciidoctor/assets/stylesheet.css")
    end

    it "resolves UNC path if target is posix-style UNC path" do
      resolver = Asciidoctor::PathResolver.new
      resolver.system_path("//server/docs/output.html").should eq("//server/docs/output.html")
    end

    it "resolves relative target relative to current directory if start is empty" do
      resolver = Asciidoctor::PathResolver.new
      pwd = Dir.current
      resolver.system_path("images/tiger.png", "").should eq("#{pwd}/images/tiger.png")
      resolver.system_path("images/tiger.png", nil).should eq("#{pwd}/images/tiger.png")
      resolver.system_path("images/tiger.png").should eq("#{pwd}/images/tiger.png")
    end

    it "posixifies windows paths" do
      resolver = Asciidoctor::PathResolver.new(file_separator: "\\")
      resolver.system_path("..\\css", "assets\\stylesheets", jail).should eq("#{jail}/assets/css")
    end

    it "resolves windows paths when file separator is backslash" do
      resolver = Asciidoctor::PathResolver.new(file_separator: "\\")
      resolver.system_path("..", "C:\\data\\docs\\assets", "C:\\data\\docs").should eq("C:/data/docs")
    end

    it "should calculate relative path" do
      resolver = Asciidoctor::PathResolver.new
      filename = resolver.system_path("part1/chapter1/section1.adoc", nil, jail)
      filename.should eq("#{jail}/part1/chapter1/section1.adoc")
      resolver.relative_path(filename, jail).should eq("part1/chapter1/section1.adoc")
    end
  end

  describe "Helpers" do
    it "posixify converts backslashes to forward slashes" do
      resolver = Asciidoctor::PathResolver.new(file_separator: "\\")
      resolver.posixify("foo\\bar\\baz").should eq("foo/bar/baz")
    end

    it "posixify returns empty string for nil" do
      resolver = Asciidoctor::PathResolver.new
      resolver.posixify(nil).should eq("")
    end

    it "root? detects absolute paths" do
      resolver = Asciidoctor::PathResolver.new
      resolver.root?("/foo").should be_true
      resolver.root?("foo").should be_false
    end

    it "web_root? detects absolute web paths" do
      resolver = Asciidoctor::PathResolver.new
      resolver.web_root?("/foo").should be_true
      resolver.web_root?("foo").should be_false
    end

    it "unc? detects UNC paths" do
      resolver = Asciidoctor::PathResolver.new
      resolver.unc?("//server/share").should be_true
      resolver.unc?("/foo").should be_false
    end

    it "expand_path resolves parent references" do
      resolver = Asciidoctor::PathResolver.new
      resolver.expand_path("/foo/bar/../baz").should eq("/foo/baz")
      resolver.expand_path("foo/./bar").should eq("foo/bar")
    end

    it "join_path joins segments with root" do
      resolver = Asciidoctor::PathResolver.new
      resolver.join_path(["foo", "bar"], "/").should eq("/foo/bar")
      resolver.join_path(["foo", "bar"]).should eq("foo/bar")
    end
  end
end
