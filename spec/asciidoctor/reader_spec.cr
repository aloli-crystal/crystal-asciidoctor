require "../spec_helper"

describe Asciidoctor::Reader do
  describe "#initialize" do
    it "creates a reader from an array of strings" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.has_more_lines?.should be_true
      reader.source_lines.size.should eq(3)
    end

    it "creates a reader from a string" do
      reader = Asciidoctor::Reader.new("line 1\nline 2\nline 3")
      reader.has_more_lines?.should be_true
      reader.source_lines.size.should eq(3)
    end

    it "creates a reader from nil" do
      reader = Asciidoctor::Reader.new(nil)
      reader.has_more_lines?.should be_false
      reader.source_lines.size.should eq(0)
    end

    it "creates a reader with a cursor" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc")
      reader = Asciidoctor::Reader.new(["line 1"], cursor)
      reader.file.should eq("/tmp/test.adoc")
      reader.dir.should eq("/tmp")
      reader.path.should eq("test.adoc")
    end

    it "creates a reader with a string cursor" do
      reader = Asciidoctor::Reader.new(["line 1"], "/tmp/test.adoc")
      reader.file.should eq("/tmp/test.adoc")
    end

    it "defaults to stdin when no cursor" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.path.should eq("<stdin>")
      reader.dir.should eq(".")
    end
  end

  describe "#advance" do
    it "advances to the next line" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.advance.should be_true
      reader.peek_line.should eq("line 2")
    end

    it "returns false when no more lines" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.advance.should be_true
      reader.advance.should be_false
    end
  end

  describe "#cursor" do
    it "returns a cursor at the current position" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      cursor = reader.cursor
      cursor.lineno.should eq(1)
      cursor.path.should eq("<stdin>")
    end

    it "tracks line number after reading" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_line
      reader.read_line
      cursor = reader.cursor
      cursor.lineno.should eq(3)
    end
  end

  describe "#cursor_at_line" do
    it "returns a cursor at the specified line" do
      reader = Asciidoctor::Reader.new(["line 1"])
      cursor = reader.cursor_at_line(42)
      cursor.lineno.should eq(42)
    end
  end

  describe "#cursor_at_mark" do
    it "returns cursor at marked position" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_line
      reader.mark
      reader.read_line
      cursor = reader.cursor_at_mark
      cursor.lineno.should eq(2)
    end

    it "returns current cursor when no mark" do
      reader = Asciidoctor::Reader.new(["line 1"])
      cursor = reader.cursor_at_mark
      cursor.lineno.should eq(1)
    end
  end

  describe "#cursor_at_prev_line" do
    it "returns cursor at previous line" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.read_line
      cursor = reader.cursor_at_prev_line
      cursor.lineno.should eq(1)
    end
  end

  describe "#empty?" do
    it "returns true when no lines remain" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.empty?.should be_true
    end

    it "returns false when lines remain" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.empty?.should be_false
    end
  end

  describe "#eof?" do
    it "is an alias for empty?" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.eof?.should be_true
    end
  end

  describe "#has_more_lines?" do
    it "returns true when lines remain" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.has_more_lines?.should be_true
    end

    it "returns false when no lines remain" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.has_more_lines?.should be_false
    end
  end

  describe "#line_info" do
    it "returns formatted line info" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.line_info.should eq("<stdin>: line 1")
    end
  end

  describe "#lines" do
    it "returns a copy of remaining lines" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_line
      reader.lines.should eq(["line 2", "line 3"])
    end
  end

  describe "#mark" do
    it "marks the current position" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.read_line
      reader.mark
      cursor = reader.cursor_at_mark
      cursor.lineno.should eq(2)
    end
  end

  describe "#next_line_empty?" do
    it "returns true when next line is empty" do
      reader = Asciidoctor::Reader.new(["", "line 2"])
      reader.next_line_empty?.should be_true
    end

    it "returns false when next line has content" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.next_line_empty?.should be_false
    end

    it "returns true when no more lines" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.next_line_empty?.should be_true
    end
  end

  describe "#peek_line" do
    it "returns the next line without consuming it" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.peek_line.should eq("line 1")
      reader.peek_line.should eq("line 1")
    end

    it "returns nil when no more lines" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.peek_line.should be_nil
    end
  end

  describe "#peek_lines" do
    it "returns multiple lines without consuming them" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      lines = reader.peek_lines(2)
      lines.should eq(["line 1", "line 2"])
      reader.peek_line.should eq("line 1")
    end

    it "returns all lines when num exceeds available" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      lines = reader.peek_lines(5)
      lines.should eq(["line 1", "line 2"])
    end
  end

  describe "#read" do
    it "returns all remaining lines as a string" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read.should eq("line 1\nline 2\nline 3")
    end
  end

  describe "#read_line" do
    it "reads and consumes the next line" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.read_line.should eq("line 1")
      reader.read_line.should eq("line 2")
      reader.read_line.should be_nil
    end
  end

  describe "#read_lines" do
    it "reads all remaining lines" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_lines.should eq(["line 1", "line 2", "line 3"])
      reader.has_more_lines?.should be_false
    end
  end

  describe "#read_lines_until" do
    it "reads lines until a terminator" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "----", "line 3"])
      lines = reader.read_lines_until(terminator: "----")
      lines.should eq(["line 1", "line 2"])
    end

    it "reads lines until blank line" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "", "line 3"])
      lines = reader.read_lines_until(break_on_blank_lines: true)
      lines.should eq(["line 1", "line 2"])
    end

    it "preserves last line when requested" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "", "line 3"])
      lines = reader.read_lines_until(break_on_blank_lines: true, preserve_last_line: true)
      lines.should eq(["line 1", "line 2"])
      reader.peek_line.should eq("")
    end

    it "skips first line when requested" do
      reader = Asciidoctor::Reader.new(["----", "line 1", "line 2", "----"])
      lines = reader.read_lines_until(terminator: "----", skip_first_line: true)
      lines.should eq(["line 1", "line 2"])
    end

    it "includes last line when read_last_line is true" do
      reader = Asciidoctor::Reader.new(["line 1", "----"])
      lines = reader.read_lines_until(terminator: "----", read_last_line: true)
      lines.should eq(["line 1", "----"])
    end

    it "skips line comments when requested" do
      reader = Asciidoctor::Reader.new(["line 1", "// comment", "line 2", "----"])
      lines = reader.read_lines_until(terminator: "----", skip_line_comments: true)
      lines.should eq(["line 1", "line 2"])
    end

    it "breaks on list continuation" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "+", "line 3"])
      lines = reader.read_lines_until(break_on_list_continuation: true)
      lines.should eq(["line 1", "line 2"])
    end
  end

  describe "#replace_next_line" do
    it "replaces the next line" do
      reader = Asciidoctor::Reader.new(["old line", "line 2"])
      reader.replace_next_line("new line")
      reader.peek_line.should eq("new line")
    end
  end

  describe "#save and #restore_save" do
    it "saves and restores reader state" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_line
      reader.save
      reader.read_line
      reader.read_line
      reader.has_more_lines?.should be_false
      reader.restore_save
      reader.peek_line.should eq("line 2")
    end
  end

  describe "#skip_blank_lines" do
    it "skips blank lines and returns count" do
      reader = Asciidoctor::Reader.new(["", "", "line 1"])
      count = reader.skip_blank_lines
      count.should eq(2)
      reader.peek_line.should eq("line 1")
    end

    it "returns 0 when no blank lines" do
      reader = Asciidoctor::Reader.new(["line 1"])
      reader.skip_blank_lines.should eq(0)
    end

    it "returns nil when reader is empty" do
      reader = Asciidoctor::Reader.new([] of String)
      reader.skip_blank_lines.should be_nil
    end
  end

  describe "#skip_comment_lines" do
    it "skips single-line comments" do
      reader = Asciidoctor::Reader.new(["// comment 1", "// comment 2", "line 1"])
      reader.skip_comment_lines
      reader.peek_line.should eq("line 1")
    end
  end

  describe "#source" do
    it "returns the original source as a string" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2"])
      reader.read_line
      reader.source.should eq("line 1\nline 2")
    end
  end

  describe "#string" do
    it "returns remaining lines as a string" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.read_line
      reader.string.should eq("line 2\nline 3")
    end
  end

  describe "#terminate" do
    it "consumes all remaining lines" do
      reader = Asciidoctor::Reader.new(["line 1", "line 2", "line 3"])
      reader.terminate
      reader.has_more_lines?.should be_false
    end
  end

  describe "#unshift_line" do
    it "pushes a line back onto the reader" do
      reader = Asciidoctor::Reader.new(["line 2"])
      reader.unshift_line("line 1")
      reader.peek_line.should eq("line 1")
    end
  end

  describe "#unshift_lines" do
    it "pushes multiple lines back onto the reader" do
      reader = Asciidoctor::Reader.new(["line 3"])
      reader.unshift_lines(["line 1", "line 2"])
      reader.read_line.should eq("line 1")
      reader.read_line.should eq("line 2")
      reader.read_line.should eq("line 3")
    end
  end
end

describe Asciidoctor::PreprocessorReader do
  describe "#initialize" do
    it "creates a preprocessor reader with a document" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1", "line 2"])
      reader.has_more_lines?.should be_true
    end

    it "creates a preprocessor reader with nil data" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, nil)
      reader.has_more_lines?.should be_false
    end
  end

  describe "#include_depth" do
    it "returns 0 when no includes are active" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.include_depth.should eq(0)
    end
  end

  describe "#include_processors?" do
    it "returns false by default" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.include_processors?.should be_false
    end
  end

  describe "#push_include and #pop_include" do
    it "pushes and pops an include" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      reader = Asciidoctor::PreprocessorReader.new(doc, ["original line"])
      reader.read_line # consume original line

      reader.push_include(["included line 1", "included line 2"], "/tmp/inc.adoc", "inc.adoc", 1)
      reader.has_more_lines?.should be_true
      reader.include_depth.should eq(1)
      reader.path.should eq("inc.adoc")

      reader.read_line.should eq("included line 1")
      reader.read_line.should eq("included line 2")

      reader.pop_include
      reader.include_depth.should eq(0)
    end

    it "pushes include from string data" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      reader = Asciidoctor::PreprocessorReader.new(doc, ["original"])
      reader.read_line

      reader.push_include("line A\nline B", "/tmp/inc.adoc", "inc.adoc", 1)
      reader.read_line.should eq("line A")
      reader.read_line.should eq("line B")
    end

    it "supports nested includes" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      reader = Asciidoctor::PreprocessorReader.new(doc, ["root"])
      reader.read_line

      reader.push_include(["level 1"], "/tmp/l1.adoc", "l1.adoc", 1)
      reader.include_depth.should eq(1)

      reader.push_include(["level 2"], "/tmp/l2.adoc", "l2.adoc", 1)
      reader.include_depth.should eq(2)

      reader.pop_include
      reader.include_depth.should eq(1)

      reader.pop_include
      reader.include_depth.should eq(0)
    end
  end

  describe "#create_include_cursor" do
    it "creates a cursor for an include" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      cursor = reader.create_include_cursor("/tmp/inc.adoc", "inc.adoc", 5)
      cursor.file.should eq("/tmp/inc.adoc")
      cursor.path.should eq("inc.adoc")
      cursor.lineno.should eq(5)
    end
  end

  describe "#exceeds_max_depth?" do
    it "returns nil when max depth is not exceeded" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.exceeds_max_depth?.should be_nil
    end
  end

  describe "#resolve_expr_val" do
    it "resolves a string value" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.resolve_expr_val("'hello'").should eq("hello")
    end

    it "resolves an integer value" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.resolve_expr_val("42").should eq(42)
    end

    it "resolves a float value" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.resolve_expr_val("3.14").should eq(3.14)
    end

    it "resolves an attribute reference" do
      doc = Asciidoctor::Document.new
      doc.attributes["myattr"] = "myvalue"
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.resolve_expr_val("{myattr}").should eq("myvalue")
    end

    it "resolves unresolved attribute reference as string" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      # When attribute is not defined, the reference is left as-is
      result = reader.resolve_expr_val("{nonexistent}")
      result.should eq("{nonexistent}")
    end

    it "resolves a bare word as a string" do
      doc = Asciidoctor::Document.new
      doc.attributes["backend"] = "html5"
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      # Bare words without {} are treated as literal strings, not attribute lookups
      reader.resolve_expr_val("backend").should eq("backend")
    end
  end

  describe "#skip_front_matter!" do
    it "skips YAML front matter" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      data = ["---", "title: My Doc", "author: John", "---", "= Document Title", "", "Content"]
      front_matter = reader.skip_front_matter!(data)
      front_matter.should_not be_nil
      front_matter.not_nil!.should eq(["title: My Doc", "author: John"])
      data.first.should eq("= Document Title")
    end

    it "returns nil when no front matter" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      data = ["= Document Title", "", "Content"]
      front_matter = reader.skip_front_matter!(data)
      front_matter.should be_nil
    end

    it "returns nil when front matter is not terminated" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      data = ["---", "title: My Doc", "author: John"]
      front_matter = reader.skip_front_matter!(data)
      front_matter.should be_nil
    end
  end

  describe "#preprocess_conditional_directive" do
    it "processes ifdef with defined attribute" do
      doc = Asciidoctor::Document.new
      doc.attributes["backend"] = "html5"
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::backend[]",
        "Backend is defined",
        "endif::[]",
        "After endif",
      ])
      lines = reader.read_lines
      lines.should contain("Backend is defined")
      lines.should contain("After endif")
    end

    it "processes ifdef with undefined attribute" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::nonexistent[]",
        "Should not appear",
        "endif::[]",
        "After endif",
      ])
      lines = reader.read_lines
      lines.should_not contain("Should not appear")
      lines.should contain("After endif")
    end

    it "processes ifndef with undefined attribute" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifndef::nonexistent[]",
        "Should appear",
        "endif::[]",
        "After endif",
      ])
      lines = reader.read_lines
      lines.should contain("Should appear")
      lines.should contain("After endif")
    end

    it "processes ifndef with defined attribute" do
      doc = Asciidoctor::Document.new
      doc.attributes["backend"] = "html5"
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifndef::backend[]",
        "Should not appear",
        "endif::[]",
        "After endif",
      ])
      lines = reader.read_lines
      lines.should_not contain("Should not appear")
      lines.should contain("After endif")
    end

    it "processes ifdef with inline content" do
      doc = Asciidoctor::Document.new
      doc.attributes["backend"] = "html5"
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::backend[Backend is defined]",
        "Next line",
      ])
      lines = reader.read_lines
      lines[0].should eq("Backend is defined")
      lines.should contain("Next line")
    end

    it "processes ifdef with multiple attributes using any (comma)" do
      doc = Asciidoctor::Document.new
      doc.attributes["html"] = ""
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::html,docbook[]",
        "One of them is defined",
        "endif::[]",
      ])
      lines = reader.read_lines
      lines.should contain("One of them is defined")
    end

    it "processes ifdef with multiple attributes using all (plus)" do
      doc = Asciidoctor::Document.new
      doc.attributes["html"] = ""
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::html+docbook[]",
        "Both should be defined",
        "endif::[]",
      ])
      lines = reader.read_lines
      lines.should_not contain("Both should be defined")
    end

    it "processes nested ifdefs" do
      doc = Asciidoctor::Document.new
      doc.attributes["outer"] = ""
      doc.attributes["inner"] = ""
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "ifdef::outer[]",
        "Outer content",
        "ifdef::inner[]",
        "Inner content",
        "endif::[]",
        "After inner endif",
        "endif::[]",
        "After outer endif",
      ])
      lines = reader.read_lines
      lines.should contain("Outer content")
      lines.should contain("Inner content")
      lines.should contain("After inner endif")
      lines.should contain("After outer endif")
    end
  end

  describe "process_line with preprocessor directives" do
    it "passes through single-line comments (handled by parser)" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "line 1",
        "// this is a comment",
        "line 2",
      ])
      lines = reader.read_lines
      # Comments are not stripped by the preprocessor reader;
      # they are handled by the parser during block processing
      lines.should contain("line 1")
      lines.should contain("line 2")
      lines.size.should eq(3)
    end

    it "passes through block comment delimiters (handled by parser)" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, [
        "line 1",
        "////",
        "block comment line 1",
        "block comment line 2",
        "////",
        "line 2",
      ])
      lines = reader.read_lines
      # Block comments are not stripped by the preprocessor reader;
      # they are handled by the parser during block processing
      lines.should contain("line 1")
      lines.should contain("line 2")
      lines.size.should eq(6)
    end
  end

  describe "empty? and eof? for PreprocessorReader" do
    it "returns true when no lines remain" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, [] of String)
      reader.empty?.should be_true
      reader.eof?.should be_true
    end

    it "returns false when lines remain" do
      doc = Asciidoctor::Document.new
      reader = Asciidoctor::PreprocessorReader.new(doc, ["line 1"])
      reader.empty?.should be_false
      reader.eof?.should be_false
    end

    it "returns true after include stack is exhausted" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      reader = Asciidoctor::PreprocessorReader.new(doc, ["root"])
      reader.read_line
      reader.push_include(["included"], "/tmp/inc.adoc", "inc.adoc", 1)
      reader.read_line
      reader.pop_include
      reader.empty?.should be_true
    end
  end

  describe "has_more_lines? for PreprocessorReader" do
    it "returns true when lines remain in current or include stack" do
      doc = Asciidoctor::Document.new(safe: Asciidoctor::SafeMode::UNSAFE)
      reader = Asciidoctor::PreprocessorReader.new(doc, ["root"])
      reader.has_more_lines?.should be_true
    end
  end
end

describe Asciidoctor::Cursor do
  describe "#initialize" do
    it "creates a cursor with file info" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc")
      cursor.file.should eq("/tmp/test.adoc")
      cursor.dir.should eq("/tmp")
      cursor.path.should eq("test.adoc")
      cursor.lineno.should eq(1)
    end

    it "creates a cursor without file" do
      cursor = Asciidoctor::Cursor.new(nil)
      cursor.file.should be_nil
      cursor.dir.should eq(".")
      cursor.path.should eq("<stdin>")
    end

    it "creates a cursor with custom lineno" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", lineno: 10)
      cursor.lineno.should eq(10)
    end

    it "creates a cursor with custom dir and path" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", dir: "/custom", path: "custom.adoc")
      cursor.dir.should eq("/custom")
      cursor.path.should eq("custom.adoc")
    end
  end

  describe "#advance" do
    it "advances the line number" do
      cursor = Asciidoctor::Cursor.new(nil)
      cursor.advance(5)
      cursor.lineno.should eq(6)
    end

    it "advances by 1" do
      cursor = Asciidoctor::Cursor.new(nil)
      cursor.advance(1)
      cursor.lineno.should eq(2)
    end
  end

  describe "#line_info" do
    it "returns formatted line info" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", lineno: 42)
      cursor.line_info.should eq("test.adoc: line 42")
    end

    it "returns stdin line info when no file" do
      cursor = Asciidoctor::Cursor.new(nil)
      cursor.line_info.should eq("<stdin>: line 1")
    end
  end

  describe "#to_source_location" do
    it "converts to a SourceLocation" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", lineno: 5)
      loc = cursor.to_source_location
      loc.should be_a(Asciidoctor::SourceLocation)
      loc.lineno.should eq(5)
    end
  end

  describe "#to_s" do
    it "returns the line_info string" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", lineno: 3)
      cursor.to_s.should eq("test.adoc: line 3")
    end
  end
end
