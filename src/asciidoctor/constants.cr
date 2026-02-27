module Asciidoctor
  # The newline character used for output
  LF = '\n'

  # The null character to use for splitting attribute values
  NULL = '\0'

  # Tab character
  TAB = '\t'

  # Maximum integer value for "boundless" operations
  MAX_INT = 9007199254740991_i64

  # The default document type
  DEFAULT_DOCTYPE = "article"

  # The backend determines the format of the converted output
  DEFAULT_BACKEND = "html5"

  DEFAULT_STYLESHEET_NAME = "asciidoctor.css"

  # Pointers to the preferred version for a given backend
  BACKEND_ALIASES = {
    "html"    => "html5",
    "docbook" => "docbook5",
  }

  # Default page widths for calculating absolute widths
  DEFAULT_PAGE_WIDTHS = {
    "docbook" => 425,
  }

  # Default extensions for the respective base backends
  DEFAULT_EXTENSIONS = {
    "html"    => ".html",
    "docbook" => ".xml",
    "pdf"     => ".pdf",
    "epub"    => ".epub",
    "manpage" => ".man",
    "asciidoc" => ".adoc",
  }

  # File extensions recognized as AsciiDoc documents
  ASCIIDOC_EXTENSIONS = Set{".adoc", ".asciidoc", ".asc", ".ad", ".txt"}

  SETEXT_SECTION_LEVELS = {
    '=' => 0,
    '-' => 1,
    '~' => 2,
    '^' => 3,
    '+' => 4,
  }

  ADMONITION_STYLES = Set{"NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION"}

  PARAGRAPH_STYLES = Set{
    "comment", "example", "literal", "listing", "normal", "open",
    "pass", "quote", "sidebar", "source", "verse", "abstract", "partintro",
  }

  VERBATIM_STYLES = Set{"literal", "listing", "source", "verse"}

  NESTABLE_LIST_CONTEXTS = [:ulist, :olist, :dlist]

  ORDERED_LIST_STYLES = [:arabic, :loweralpha, :lowerroman, :upperalpha, :upperroman]

  ORDERED_LIST_KEYWORDS = {
    "loweralpha" => "a",
    "lowerroman" => "i",
    "upperalpha" => "A",
    "upperroman" => "I",
  }

  # Caption attribute names for various block contexts
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

  INTRINSIC_ATTRIBUTES = {
    "startsb"        => "[",
    "endsb"          => "]",
    "vbar"           => "|",
    "caret"          => "^",
    "asterisk"       => "*",
    "tilde"          => "~",
    "plus"           => "&#43;",
    "backslash"      => "\\",
    "backtick"       => "`",
    "blank"          => "",
    "empty"          => "",
    "sp"             => " ",
    "two-colons"     => "::",
    "two-semicolons" => ";;",
    "nbsp"           => "&#160;",
    "deg"            => "&#176;",
    "zwsp"           => "&#8203;",
    "quot"           => "&#34;",
    "apos"           => "&#39;",
    "lsquo"          => "&#8216;",
    "rsquo"          => "&#8217;",
    "ldquo"          => "&#8220;",
    "rdquo"          => "&#8221;",
    "wj"             => "&#8288;",
    "brvbar"         => "&#166;",
    "pp"             => "&#43;&#43;",
    "cpp"            => "C&#43;&#43;",
    "cxx"            => "C&#43;&#43;",
    "amp"            => "&",
    "lt"             => "<",
    "gt"             => ">",
  }
end
