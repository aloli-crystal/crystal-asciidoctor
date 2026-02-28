module Asciidoctor
  ADMONITION_STYLES = Set{"CAUTION", "IMPORTANT", "NOTE", "TIP", "WARNING"}

  ASCIIDOC_EXTENSIONS = Set{".ad", ".adoc", ".asc", ".asciidoc", ".txt"}

  BACKEND_ALIASES = {
    "docbook" => "docbook5",
    "html"    => "html5",
  }

  CAPTION_ATTRIBUTE_NAMES = {
    :example => "example-caption",
    :figure  => "figure-caption",
    :listing => "listing-caption",
    :table   => "table-caption",
  }

  DEFAULT_ATTRIBUTES = {
    "appendix-caption"  => "Appendix",
    "appendix-refsig"   => "Appendix",
    "caution-caption"   => "Caution",
    "chapter-refsig"    => "Chapter",
    "example-caption"   => "Example",
    "figure-caption"    => "Figure",
    "important-caption" => "Important",
    "last-update-label" => "Last updated",
    "note-caption"      => "Note",
    "part-refsig"       => "Part",
    "prewrap"           => "",
    "sectids"           => "",
    "section-refsig"    => "Section",
    "table-caption"     => "Table",
    "tip-caption"       => "Tip",
    "toc-placement"     => "auto",
    "toc-title"         => "Table of Contents",
    "untitled-label"    => "Untitled",
    "version-label"     => "Version",
    "warning-caption"   => "Warning",
  }

  DEFAULT_BACKEND = "html5"

  DEFAULT_DOCTYPE = "article"

  DEFAULT_EXTENSIONS = {
    "asciidoc" => ".adoc",
    "docbook"  => ".xml",
    "epub"     => ".epub",
    "html"     => ".html",
    "manpage"  => ".man",
    "pdf"      => ".pdf",
  }

  DEFAULT_PAGE_WIDTHS = {
    "docbook" => 425,
  }

  DEFAULT_STYLESHEET_NAME = "asciidoctor.css"

  INTRINSIC_ATTRIBUTES = {
    "amp"            => "&",
    "apos"           => "&#39;",
    "asterisk"       => "*",
    "backslash"      => "\\",
    "backtick"       => "`",
    "blank"          => "",
    "brvbar"         => "&#166;",
    "caret"          => "^",
    "cpp"            => "C&#43;&#43;",
    "cxx"            => "C&#43;&#43;",
    "deg"            => "&#176;",
    "empty"          => "",
    "endsb"          => "]",
    "gt"             => ">",
    "ldquo"          => "&#8220;",
    "lsquo"          => "&#8216;",
    "lt"             => "<",
    "nbsp"           => "&#160;",
    "plus"           => "&#43;",
    "pp"             => "&#43;&#43;",
    "quot"           => "&#34;",
    "rdquo"          => "&#8221;",
    "rsquo"          => "&#8217;",
    "sp"             => " ",
    "startsb"        => "[",
    "tilde"          => "~",
    "two-colons"     => "::",
    "two-semicolons" => ";;",
    "vbar"           => "|",
    "wj"             => "&#8288;",
    "zwsp"           => "&#8203;",
  }

  # The newline character used for output.
  LF = '\n'

  # Maximum integer value for "boundless" operations.
  MAX_INT = 9007199254740991_i64

  NESTABLE_LIST_CONTEXTS = [:dlist, :olist, :ulist]

  # The null character to use for splitting attribute values.
  NULL = '\0'

  ORDERED_LIST_KEYWORDS = {
    "loweralpha" => "a",
    "lowerroman" => "i",
    "upperalpha" => "A",
    "upperroman" => "I",
  }

  ORDERED_LIST_STYLES = [:arabic, :loweralpha, :lowerroman, :upperalpha, :upperroman]

  PARAGRAPH_STYLES = Set{
    "abstract", "comment", "example", "listing", "literal", "normal", "open",
    "partintro", "pass", "quote", "sidebar", "source", "verse",
  }

  SETEXT_SECTION_LEVELS = {
    '=' => 0,
    '-' => 1,
    '~' => 2,
    '^' => 3,
    '+' => 4,
  }

  # Tab character.
  TAB = '\t'

  VERBATIM_STYLES = Set{"listing", "literal", "source", "verse"}
end
