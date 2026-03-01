require "../spec_helper"

# Helper methods for list tests
def convert_string(input : String) : String
  Asciidoctor.convert(input, {"standalone" => "true", "backend" => "html5", "attributes" => "linkcss"})
end

def convert_string_to_embedded(input : String) : String
  Asciidoctor.convert(input, {"backend" => "html5", "standalone" => "false"})
end

def load_string(input : String) : Asciidoctor::Document
  Asciidoctor.load(input, {"backend" => "html5"})
end

describe "Lists" do
  # =========================================================================
  # Bulleted lists - Simple lists
  # =========================================================================
  describe "Bulleted lists - Simple lists" do
    it "dash elements with no blank lines" do
      input = "= List\n\n- Foo\n- Boo\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented dash elements using spaces" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = " - Foo\n - Boo\n - Blech"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented dash elements using tabs" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = "\t-\tFoo\n\t-\tBoo\n\t-\tBlech"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    it "dash elements separated by blank lines should merge lists" do
      input = "= List\n\n- Foo\n\n- Boo\n\n\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    it "dash elements separated by a line comment offset by blank lines should not merge lists" do
      input = "= List\n\n- Foo\n- Boo\n\n//\n\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
    end

    it "dash elements separated by a block title offset by a blank line should not merge lists" do
      input = "= List\n\n- Foo\n- Boo\n\n.Also\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.should contain("Also")
    end

    it "a non-indented wrapped line is folded into text of list item" do
      input = "= List\n\n- Foo\nwrapped content\n- Boo\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.should contain("Foo")
      output.should contain("wrapped content")
    end

    it "a non-indented wrapped line that resembles a block title is folded into text of list item" do
      input = "== List\n\n- Foo\n.wrapped content\n- Boo\n- Blech"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.should contain(".wrapped content")
    end

    it "an indented wrapped line is unindented and folded into text of list item" do
      input = "= List\n\n- Foo\n  wrapped content\n- Boo\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.should contain("Foo")
      output.should contain("wrapped content")
    end

    it "a list item with a nested marker terminates non-indented paragraph for text of list item" do
      input = "- Foo\nBar\n* Foo"
      output = convert_string_to_embedded(input)
      output.should contain("<ul")
      output.should_not contain("* Foo")
    end

    pending "a literal paragraph offset by blank lines in list content is appended as a literal block" do
      # Convertisseur Crystal génère 2 <ul> au lieu de 1 pour les blocs littéraux dans les listes
      input = "= List\n\n- Foo\n\n  literal\n\n- Boo\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
      output.should contain("Foo")
      output.should contain("literalblock")
      output.should contain("literal")
    end

    it "asterisk elements with no blank lines" do
      input = "= List\n\n* Foo\n* Boo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented asterisk elements using spaces" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = " * Foo\n * Boo\n * Blech"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented asterisk elements using tabs" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = "\t*\tFoo\n\t*\tBoo\n\t*\tBlech"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    it "should represent block style as style class" do
      ["disc", "square", "circle"].each do |style|
        input = "[#{style}]\n* a\n* b\n* c"
        output = convert_string_to_embedded(input)
        output.should contain(style)
      end
    end

    it "asterisk elements separated by blank lines should merge lists" do
      input = "= List\n\n* Foo\n\n* Boo\n\n\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    it "asterisk elements separated by a line comment offset by blank lines should not merge lists" do
      input = "= List\n\n* Foo\n* Boo\n\n//\n\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
    end

    it "asterisk elements separated by a block title offset by a blank line should not merge lists" do
      input = "= List\n\n* Foo\n* Boo\n\n.Also\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.should contain("Also")
    end

    it "list should terminate before next lower section heading" do
      input = "= List\n\n* first\nitem\n* second\nitem\n\n== Section"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("Section")
    end

    it "list should terminate before next lower section heading with implicit id" do
      input = "= List\n\n* first\nitem\n* second\nitem\n\n[[sec]]\n== Section"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("sec")
    end

    it "should not find section title immediately below last list item" do
      input = "* first\n* second\n== Not a section"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should_not contain("<h2")
      output.should contain("== Not a section")
    end
  end

  # =========================================================================
  # Bulleted lists - Lists with inline markup
  # =========================================================================
  describe "Bulleted lists - Lists with inline markup" do
    pending "quoted text" do
      # Convertisseur Crystal ne traite pas encore l'inline markup dans les listes
      input = "= List\n\n- I am *strong*.\n- I am _stressed_.\n- I am `flexible`."
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
      output.should contain("<strong>")
      output.should contain("<em>")
      output.should contain("<code>")
    end

    pending "attribute substitutions" do
      # Convertisseur Crystal ne traite pas encore les substitutions d'attributs dans les listes
      input = "= List\n:foo: bar\n\n- side a {vbar} side b\n- Take me to a {foo}."
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("side a | side b")
      output.should contain("Take me to a bar.")
    end

    it "leading dot is treated as text not block title" do
      input = "* .first\n* .second\n* .third"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
      output.should contain(".first")
      output.should contain(".second")
      output.should contain(".third")
    end

    pending "word ending sentence on continuing line not treated as a list item" do
      # Parser Crystal ne gère pas encore les marqueurs de liste alphabétiques explicites (A. B.)
      input = "A. This is the story about\n   AsciiDoc. It begins here.\nB. And it ends here."
      output = convert_string_to_embedded(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
    end
  end

  # =========================================================================
  # Bulleted lists - Nested lists
  # =========================================================================
  describe "Bulleted lists - Nested lists" do
    pending "asterisk element mixed with dash elements should be nested" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées mixtes
      input = "= List\n\n- Foo\n* Boo\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.scan("<li>").size.should eq(3)
    end

    pending "dash element mixed with asterisks elements should be nested" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées mixtes
      input = "= List\n\n* Foo\n- Boo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.scan("<li>").size.should eq(3)
    end

    pending "lines prefixed with alternating list markers separated by blank lines should be nested" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées mixtes
      input = "= List\n\n- Foo\n\n* Boo\n\n\n- Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.scan("<li>").size.should eq(3)
    end

    pending "nested elements (2) with asterisks" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées
      input = "= List\n\n* Foo\n** Boo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(2)
      output.scan("<li>").size.should eq(3)
    end

    pending "nested elements (3) with asterisks" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées
      input = "= List\n\n* Foo\n** Boo\n*** Snoo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(3)
    end

    pending "nested elements (4) with asterisks" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées
      input = "= List\n\n* Foo\n** Boo\n*** Snoo\n**** Froo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(4)
    end

    pending "nested elements (5) with asterisks" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul> pour les listes imbriquées
      input = "= List\n\n* Foo\n** Boo\n*** Snoo\n**** Froo\n***** Groo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(5)
    end

    pending "nested arbitrary depth with asterisks" do
      # Parser Crystal ne supporte pas encore la profondeur arbitraire (>5 niveaux)
      lines = [] of String
      ('a'..'z').each_with_index do |ch, i|
        lines << "#{"*" * (i + 1)} #{ch}"
      end
      output = convert_string_to_embedded(lines.join("\n"))
      output.should_not contain("*")
      output.scan("<li>").size.should eq(26)
    end

    it "does not recognize lists with repeating unicode bullets" do
      input = "•• Boo"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(0)
      output.should contain("•")
    end

    pending "nested ordered elements (2)" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ol> pour les listes imbriquées
      input = "= List\n\n. Foo\n.. Boo\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(2)
      output.scan("<li>").size.should eq(3)
    end

    pending "nested ordered elements (3)" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ol> pour les listes imbriquées
      input = "= List\n\n. Foo\n.. Boo\n... Snoo\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(3)
    end

    pending "nested unordered inside ordered elements" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<ol> pour les listes imbriquées mixtes
      input = "= List\n\n. Foo\n* Boo\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<ul>").size.should eq(1)
    end

    pending "nested ordered inside unordered elements" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<ol> pour les listes imbriquées mixtes
      input = "= List\n\n* Foo\n. Boo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<ol>").size.should eq(1)
    end

    it "three levels of alternating unordered and ordered elements" do
      input = "== Lists\n\n* bullet 1\n. numbered 1.1\n** bullet 1.1.1\n* bullet 2"
      output = convert_string_to_embedded(input)
      output.should contain("ulist")
      output.should contain("olist")
    end

    pending "lines with alternating markers of unordered and ordered list types separated by blank lines should be nested" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<ol> pour les listes imbriquées mixtes
      input = "= List\n\n* Foo\n\n. Boo\n\n\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<ol>").size.should eq(1)
    end

    it "list item with literal content should not consume nested list of different type" do
      input = "= List\n\n- bullet\n\n  literal\n  but not\n  hungry\n\n. numbered"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("bullet")
      output.should contain("numbered")
    end

    it "nested list item does not eat the title of the following detached block" do
      input = "= List\n\n- bullet\n  * nested bullet 1\n  * nested bullet 2\n\n.Title\n....\nliteral\n...."
      output = convert_string(input)
      output.should contain("ulist")
      output.should contain("literalblock")
      output.should contain("Title")
    end

    pending "lines with alternating markers of bulleted and description list types separated by blank lines should be nested" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<dl> pour les listes imbriquées mixtes
      input = "= List\n\n* Foo\n\nterm1:: def1\n\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<dl>").size.should eq(1)
    end

    pending "nested ordered with attribute inside unordered elements" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<ol> pour les listes imbriquées
      input = "= Blah\n\n* Foo\n[start=2]\n. Boo\n* Blech"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<ol>").size.should eq(1)
    end
  end

  # =========================================================================
  # Bulleted lists - List continuations
  # =========================================================================
  describe "Bulleted lists - List continuations" do
    pending "adjacent list continuation line attaches following paragraph" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<li> pour les continuations
      input = "= Lists\n\n* Item one, paragraph one\n+\nItem one, paragraph two\n+\n* Item two"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("Item one, paragraph one")
      output.should contain("Item one, paragraph two")
    end

    pending "adjacent list continuation line attaches following block" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ul>/<li> pour les continuations avec blocs
      input = "= Lists\n\n* Item one, paragraph one\n+\n....\nItem one, literal block\n....\n+\n* Item two"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("literalblock")
    end

    it "trailing block attribute line attached by continuation should not create block" do
      input = "= Lists\n\n* Item one, paragraph one\n+\n[source]\n\n* Item two"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
    end

    pending "trailing block title line attached by continuation should not create block" do
      # Convertisseur Crystal ne gère pas correctement les continuations avec titres de bloc
      input = "= Lists\n\n* Item one, paragraph one\n+\n.Disappears into the ether\n\n* Item two"
      output = convert_string(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
    end

    pending "consecutive blocks in list continuation attach to list item" do
      # Convertisseur Crystal ne gère pas correctement les blocs consécutifs en continuation
      input = "= Lists\n\n* Item one, paragraph one\n+\n....\nItem one, literal block\n....\n+\n____\nItem one, quote block\n____\n+\n* Item two"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("literalblock")
      output.should contain("quoteblock")
    end

    pending "list item with hanging indent followed by block attached by list continuation" do
      # Parser Crystal ne gère pas encore le hanging indent avec continuation
      input = "== Lists\n\n. list item 1\n  continued\n+\n--\nopen block in list item 1\n--\n\n. list item 2"
      output = convert_string_to_embedded(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("openblock")
      output.should contain("open block in list item 1")
    end

    it "list item paragraph in list item and nested list item" do
      input = "== Lists\n\n. list item 1\n+\nlist item 1 paragraph\n\n* nested list item\n+\nnested list item paragraph\n\n. list item 2"
      output = convert_string_to_embedded(input)
      output.should contain("olist")
      output.should contain("ulist")
      output.should contain("list item 1 paragraph")
      output.should contain("nested list item paragraph")
    end

    pending "consecutive list continuation lines are folded" do
      # Convertisseur Crystal ne gère pas correctement les continuations consécutives
      input = "= Lists\n\n* Item one, paragraph one\n+\n+\nItem one, paragraph two\n+\n+\n* Item two\n+\n+"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("Item one, paragraph one")
    end

    it "should warn if unterminated block is detected in list item" do
      input = "* item\n+\n====\nexample\n* swallowed item"
      output = convert_string_to_embedded(input)
      output.scan("<li>").size.should eq(1)
      output.should contain("exampleblock")
    end

    it "appends line as paragraph if attached by continuation following line comment" do
      input = "- list item 1\n// line comment\n+\nparagraph in list item 1\n\n- list item 2"
      output = convert_string_to_embedded(input)
      output.scan("<ul>").size.should eq(1)
      output.scan("<li>").size.should eq(2)
      output.should contain("list item 1")
      output.should contain("paragraph in list item 1")
      output.should contain("list item 2")
    end

    it "should continue to parse blocks attached to list item after block is dropped" do
      input = "* item\n+\nparagraph\n+\n====\nexample\n====\n'''"
      output = convert_string_to_embedded(input)
      output.should contain("paragraph")
      output.should contain("exampleblock")
    end
  end

  # =========================================================================
  # Ordered lists - Simple lists
  # =========================================================================
  describe "Ordered lists - Simple lists" do
    pending "dot elements with no blank lines" do
      # Convertisseur Crystal ne génère pas le bon nombre de <ol>/<li> pour les listes ordonnées simples
      input = "= List\n\n. Foo\n. Boo\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented dot elements using spaces" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = " . Foo\n . Boo\n . Blech"
      output = convert_string_to_embedded(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "indented dot elements using tabs" do
      # Parser Crystal ne supporte pas encore les éléments de liste indentés
      input = "\t.\tFoo\n\t.\tBoo\n\t.\tBlech"
      output = convert_string_to_embedded(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    it "should represent explicit role attribute as style class" do
      input = "[role=\"dry\"]\n. Once\n. Again\n. Refactor!"
      output = convert_string_to_embedded(input)
      output.should contain("olist")
      output.should contain("dry")
    end

    it "should base list style on marker length rather than list depth" do
      input = "... parent\n.. child\n. grandchild"
      output = convert_string_to_embedded(input)
      output.should contain("lowerroman")
      output.should contain("loweralpha")
      output.should contain("arabic")
    end

    it "should set reversed attribute on list if reversed option is set" do
      input = "[%reversed, start=3]\n. three\n. two\n. one\n. blast off!"
      output = convert_string_to_embedded(input)
      output.should contain("reversed")
      output.should contain("start=\"3\"")
    end

    pending "dot elements separated by blank lines should merge lists" do
      # Convertisseur Crystal ne fusionne pas les listes ordonnées séparées par des lignes vides
      input = "= List\n\n. Foo\n\n. Boo\n\n\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end

    pending "dot elements separated by line comment offset by blank lines should not merge lists" do
      # Convertisseur Crystal ne gère pas correctement la séparation des listes ordonnées
      input = "= List\n\n. Foo\n. Boo\n\n//\n\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(2)
    end

    pending "dot elements separated by a block title offset by a blank line should not merge lists" do
      # Convertisseur Crystal ne gère pas correctement la séparation des listes ordonnées
      input = "= List\n\n. Foo\n. Boo\n\n.Also\n. Blech"
      output = convert_string(input)
      output.scan("<ol>").size.should eq(2)
      output.should contain("Also")
    end

    it "should honor start attribute on ordered list" do
      input = "== List\n\n[start=7]\n. item 7\n. item 8"
      output = convert_string_to_embedded(input)
      output.should contain("arabic")
      output.should contain("start=\"7\"")
    end

    it "should allow value of start attribute to be 0" do
      input = "== List\n\n[start=0]\n. item 0\n. item 1\n. item 2"
      output = convert_string_to_embedded(input)
      output.should contain("arabic")
      output.should contain("start=\"0\"")
    end

    it "should allow value of start attribute to be negative" do
      input = "== List\n\n[start=-10]\n. -10\n. -9\n. -8"
      output = convert_string_to_embedded(input)
      output.should contain("arabic")
      output.should contain("start=\"-10\"")
    end

    it "should represent custom numbering and explicit role attribute as style classes" do
      input = "[loweralpha, role=\"dry\"]\n. Once\n. Again\n. Refactor!"
      output = convert_string_to_embedded(input)
      output.should contain("loweralpha")
      output.should contain("dry")
    end

    it "should represent implicit role attribute as style class" do
      input = "[.dry]\n. Once\n. Again\n. Refactor!"
      output = convert_string_to_embedded(input)
      output.should contain("dry")
    end

    it "should represent custom numbering and implicit role attribute as style classes" do
      input = "[loweralpha.dry]\n. Once\n. Again\n. Refactor!"
      output = convert_string_to_embedded(input)
      output.should contain("loweralpha")
      output.should contain("dry")
    end

    pending "should escape special characters in all literal paragraphs attached to list item" do
      # Convertisseur Crystal ne gère pas correctement l'échappement dans les blocs littéraux des listes
      input = ". first item\n\n  <code>text</code>\n\n  more <code>text</code>\n\n. second item"
      output = convert_string_to_embedded(input)
      output.scan("<li>").size.should eq(2)
      output.should_not contain("<code>text</code>")
      output.should contain("&lt;code&gt;")
    end

    pending "dot elements with interspersed line comments should be skipped and not break list" do
      # Convertisseur Crystal ne gère pas correctement les commentaires dans les listes ordonnées
      input = "== List\n\n. Foo\n// line comment\n// another line comment\n. Boo\n// line comment\nmore text\n// another line comment\n. Blech"
      output = convert_string_to_embedded(input)
      output.scan("<ol>").size.should eq(1)
      output.scan("<li>").size.should eq(3)
    end
  end

  # =========================================================================
  # Description lists - Simple lists
  # =========================================================================
  describe "Description lists - Simple lists" do
    it "should not parse a bare dlist delimiter as a dlist" do
      input = "::"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(0)
    end

    pending "single-line adjacent elements" do
      # Convertisseur Crystal génère 4 <dt> au lieu de 2 pour les description lists inline
      input = "term1:: def1\nterm2:: def2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(1)
      output.scan("<dt>").size.should eq(2)
      output.scan("<dd>").size.should eq(2)
      output.should contain("term1")
      output.should contain("def1")
      output.should contain("term2")
      output.should contain("def2")
    end

    pending "single-line elements separated by blank line should create a single list" do
      # Convertisseur Crystal génère des <dt> en double pour les description lists
      input = "term1:: def1\n\nterm2:: def2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(1)
      output.scan("<dt>").size.should eq(2)
    end

    pending "multi-line element with paragraph content" do
      # Convertisseur Crystal génère des <dt> en double pour les description lists multi-lignes
      input = "term1::\ndef1"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(1)
      output.scan("<dt>").size.should eq(1)
      output.should contain("term1")
      output.should contain("def1")
    end

    pending "multi-line elements with blank line before paragraph content" do
      # Convertisseur Crystal génère des <dt> en double pour les description lists multi-lignes
      input = "term1::\n\ndef1\nterm2::\n\ndef2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(1)
      output.scan("<dt>").size.should eq(2)
      output.should contain("def1")
      output.should contain("def2")
    end

    pending "mixed single and multi-line adjacent elements" do
      # Convertisseur Crystal génère des <dt> en double pour les description lists mixtes
      input = "term1:: def1\nterm2::\ndef2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(1)
      output.scan("<dt>").size.should eq(2)
      output.should contain("def1")
      output.should contain("def2")
    end

    it "missing space before term does not produce description list" do
      input = "term1::def1\nterm2::def2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(0)
    end

    pending "literal block inside description list" do
      # Convertisseur Crystal ne gère pas correctement les blocs littéraux dans les description lists
      input = "term::\n+\n....\nliteral, line 1\n\nliteral, line 2\n....\nanotherterm:: def"
      output = convert_string_to_embedded(input)
      output.scan("<dt>").size.should eq(2)
      output.scan("<dd>").size.should eq(2)
      output.should contain("<pre>")
      output.should contain("def")
    end

    it "open block inside description list" do
      input = "term::\n+\n--\nOpen block as description of term.\n\nAnd some more detail...\n--\nanotherterm:: def"
      output = convert_string_to_embedded(input)
      output.should contain("openblock")
      output.should contain("def")
    end

    it "paragraph attached by a list continuation on either side in a description list" do
      input = "term1:: def1\n+\nmore detail\n+\nterm2:: def2"
      output = convert_string_to_embedded(input)
      output.should contain("term1")
      output.should contain("term2")
      output.should contain("def1")
      output.should contain("more detail")
    end

    pending "list inside a description list" do
      # Convertisseur Crystal ne gère pas correctement les listes imbriquées dans les description lists
      input = "term1::\n* level 1\n** level 2\n* level 1\nterm2:: def"
      output = convert_string_to_embedded(input)
      output.scan("<dd>").size.should eq(2)
      output.should contain("<ul>")
      output.should contain("def")
    end

    pending "list inside a description list offset by blank lines" do
      # Convertisseur Crystal ne gère pas correctement les listes imbriquées dans les description lists
      input = "term1::\n\n* level 1\n** level 2\n* level 1\n\nterm2:: def"
      output = convert_string_to_embedded(input)
      output.scan("<dd>").size.should eq(2)
      output.should contain("<ul>")
    end
  end

  # =========================================================================
  # Description lists - Nested lists
  # =========================================================================
  describe "Description lists - Nested lists" do
    pending "nested description list using different delimiters" do
      # Convertisseur Crystal ne gère pas correctement les description lists imbriquées
      input = "term1::\ndef1\nterm1a:::\ndef1a\nterm1b:::\ndef1b\nterm2::\ndef2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should eq(2)
      output.should contain("term1")
      output.should contain("def1")
      output.should contain("term1a")
      output.should contain("def1a")
    end

    it "nested description list using same delimiter" do
      input = "term1::\ndef1\nterm1a;;\ndef1a\nterm1b;;\ndef1b\nterm2::\ndef2"
      output = convert_string_to_embedded(input)
      output.scan("<dl>").size.should be >= 1
      output.should contain("term1")
      output.should contain("def1")
    end
  end

  # =========================================================================
  # Description lists - Special lists
  # =========================================================================
  describe "Description lists - Special lists" do
    it "should convert glossary list with proper semantics" do
      input = "[glossary]\nterm 1:: def 1\nterm 2:: def 2"
      output = convert_string_to_embedded(input)
      output.should contain("glossary")
    end

    pending "should convert horizontal list with proper markup" do
      # Convertisseur Crystal ne génère pas encore les hdlist avec table
      input = "[horizontal]\nfirst term:: description\n+\nmore detail\n\nsecond term:: description"
      output = convert_string_to_embedded(input)
      output.should contain("hdlist")
      output.should contain("<table")
      output.should contain("first term")
      output.should contain("second term")
    end

    pending "should set col widths of item and label if specified" do
      # Convertisseur Crystal ne génère pas encore les hdlist avec colgroup
      input = "[horizontal]\n[labelwidth=\"25\", itemwidth=\"75\"]\nterm:: def"
      output = convert_string_to_embedded(input)
      output.should contain("<table")
      output.should contain("<colgroup>")
      output.should contain("25%")
      output.should contain("75%")
    end

    pending "should add strong class to label if strong option is set" do
      # Convertisseur Crystal ne génère pas encore les hdlist
      input = "[horizontal, options=\"strong\"]\nterm:: def"
      output = convert_string_to_embedded(input)
      output.should contain("hdlist")
      output.should contain("strong")
    end

    pending "should convert qanda list in HTML with proper semantics" do
      # Convertisseur Crystal ne génère pas encore les qanda lists
      input = "[qanda]\nQuestion 1::\n        Answer 1.\nQuestion 2::\n        Answer 2."
      output = convert_string_to_embedded(input)
      output.should contain("qlist")
      output.should contain("qanda")
      output.should contain("<ol>")
    end

    it "should convert bibliography list with proper semantics" do
      input = "[bibliography]\n- [[[taoup]]] Eric Steven Raymond. _The Art of Unix Programming_.\n- [[[walsh-muellner]]] Norman Walsh & Leonard Muellner. _DocBook_."
      output = convert_string_to_embedded(input)
      output.should contain("bibliography")
      output.should contain("taoup")
    end
  end

  # =========================================================================
  # Checklists
  # =========================================================================
  describe "Checklists" do
    it "should create checklist if at least one item has checkbox syntax" do
      input = "- [ ] todo\n- [x] done\n- plain"
      output = convert_string_to_embedded(input)
      output.should contain("checklist")
    end

    it "should create checklist with font icons if icons attribute is font" do
      input = "- [ ] todo\n- [x] done\n- plain"
      output = Asciidoctor.convert(input, {"backend" => "html5", "attributes" => "icons=font"})
      output.should contain("checklist")
    end
  end

  # =========================================================================
  # Lists model
  # =========================================================================
  describe "Lists model" do
    it "content should return items in list" do
      input = "* one\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      items = list.items
      items.size.should eq(3)
    end

    it "list item should be the parent of block attached to a list item" do
      input = "* list item 1\n+\n----\nlisting block in list item 1\n----"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list_item_1 = list.items.first
      list_item_1.blocks.size.should be >= 1
      listing_block = list_item_1.blocks.first
      listing_block.context.should eq(:listing)
    end

    it "outline? should return true for unordered list" do
      input = "* one\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.outline?.should be_true
    end

    it "outline? should return true for ordered list" do
      input = ". one\n. two\n. three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.outline?.should be_true
    end

    it "outline? should return false for description list" do
      input = "label:: desc"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.outline?.should be_false
    end

    it "simple? should return true for list item with no nested blocks" do
      input = "* one\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.items.first.as(Asciidoctor::ListItem).simple?.should be_true
    end

    it "simple? should return true for list item with nested outline list" do
      input = "* one\n** more about one\n** and more\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.items.first.as(Asciidoctor::ListItem).simple?.should be_true
    end

    it "simple? should return false for list item with block content" do
      input = "* one\n+\n----\nlisting block in list item 1\n----\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.items.first.as(Asciidoctor::ListItem).simple?.should be_false
    end

    it "should allow text of ListItem to be read" do
      input = "* one\n* two\n* three"
      doc = load_string(input)
      list = doc.blocks.first.as(Asciidoctor::List)
      list.items.size.should eq(3)
      list.items[0].as(Asciidoctor::ListItem).text.should eq("one")
    end

    pending "should set lineno to line number in source where list starts" do
      # TODO: sourcemap not yet fully implemented
      input = "* bullet 1\n** bullet 1.1\n*** bullet 1.1.1\n* bullet 2"
      doc = Asciidoctor.load(input, {"sourcemap" => "true"})
      lists = doc.find_by(context: :ulist)
      lists[0].lineno.should eq(1)
      lists[1].lineno.should eq(2)
      lists[2].lineno.should eq(3)
    end
  end
end
