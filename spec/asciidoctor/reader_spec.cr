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
  end

  describe "#advance" do
    it "advances the line number" do
      cursor = Asciidoctor::Cursor.new(nil)
      cursor.advance(5)
      cursor.lineno.should eq(6)
    end
  end

  describe "#line_info" do
    it "returns formatted line info" do
      cursor = Asciidoctor::Cursor.new("/tmp/test.adoc", lineno: 42)
      cursor.line_info.should eq("test.adoc: line 42")
    end
  end
end
