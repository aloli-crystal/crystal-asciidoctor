require "../spec_helper"

describe "Paragraphs" do
  pending "should not drop leading space on first line of a paragraph" do
    # Convertisseur Crystal traite les paragraphes indentés comme des literalblock et supprime les espaces de début
    input = "  Indented paragraph."
    output = Asciidoctor.convert(input)
    output.should contain("  Indented paragraph.")
  end

  pending "should treat a paragraph that begins with a space as a normal paragraph" do
    # Convertisseur Crystal traite les paragraphes indentés comme des literalblock
    input = " a paragraph"
    output = Asciidoctor.convert(input)
    output.should contain("<p>a paragraph</p>")
  end

  it "should treat a paragraph that begins with a space as a literal block" do
    input = " a paragraph"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a paragraph")
  end

  pending "should treat a paragraph that begins with a right angle bracket as a normal paragraph" do
    # Convertisseur Crystal ne fait pas l'échappement HTML des caractères spéciaux
    input = "> a paragraph"
    output = Asciidoctor.convert(input)
    output.should contain("<p>&gt; a paragraph</p>")
  end

  it "should render a paragraph that begins with a right angle bracket" do
    input = "> a paragraph"
    output = Asciidoctor.convert(input)
    output.should contain("a paragraph")
  end

  pending "should not recognize a lone right angle bracket as a blockquote" do
    # Convertisseur Crystal ne fait pas l'échappement HTML
    input = ">"
    output = Asciidoctor.convert(input)
    output.should contain("<p>&gt;</p>")
  end

  it "should separate paragraphs by a blank line" do
    input = "Paragraph 1\n\nParagraph 2"
    output = Asciidoctor.convert(input)
    output.should contain("Paragraph 1")
    output.should contain("Paragraph 2")
    output.scan("<p>").size.should eq(2)
  end

  it "should not create a paragraph from a blank line" do
    input = " \n\nParagraph 1\n\n \n\nParagraph 2\n\n "
    output = Asciidoctor.convert(input)
    output.should contain("Paragraph 1")
    output.should contain("Paragraph 2")
    output.scan("<p>").size.should eq(2)
  end

  it "should not create a paragraph from a line with only tabs and spaces" do
    input = " \t \n\nParagraph 1\n\n \t \n\nParagraph 2\n\n \t "
    output = Asciidoctor.convert(input)
    output.should contain("Paragraph 1")
    output.should contain("Paragraph 2")
    output.scan("<p>").size.should eq(2)
  end

  pending "should not create a paragraph that contains only a hard line break" do
    # Convertisseur Crystal génère 2 <p> au lieu de 1 (le + est traité comme un paragraphe)
    input = "+\n\nparagraph"
    output = Asciidoctor.convert(input)
    output.should contain("<p>paragraph</p>")
    output.scan("<p>").size.should eq(1)
  end

  it "should set the content_model of a paragraph to simple" do
    doc = Asciidoctor.load("A paragraph.")
    doc.blocks.size.should eq(1)
    p = doc.blocks[0]
    p.context.should eq(:paragraph)
    p.content_model.should eq(Asciidoctor::ContentModel::Simple)
  end

  pending "should substitute special characters in a paragraph by default" do
    # Convertisseur Crystal ne fait pas l'échappement HTML des caractères spéciaux
    input = "He said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("He said, &lt;Let's rock!&gt;")
  end

  it "should render special characters in a paragraph" do
    input = "He said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("He said,")
    output.should contain("rock!")
  end

  pending "should not substitute special characters in a literal paragraph" do
    # Convertisseur Crystal ne traite pas encore [literal] correctement (traité comme paragraphe normal)
    input = "[literal]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("<pre>He said, &lt;Let's rock!&gt;</pre>")
  end

  pending "should not substitute special characters in a paragraph with literal style" do
    # Convertisseur Crystal ne traite pas encore [literal] correctement
    input = "[literal]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("<pre>He said, &lt;Let's rock!&gt;</pre>")
  end

  pending "should not substitute special characters in a paragraph with listing style" do
    # Convertisseur Crystal ne traite pas encore [listing] correctement
    input = "[listing]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("<pre><code>He said, &lt;Let's rock!&gt;</code></pre>")
  end

  pending "should not substitute special characters in a paragraph with source style" do
    # Convertisseur Crystal ne traite pas encore [source] correctement
    input = "[source]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("<pre><code>He said, &lt;Let's rock!&gt;</code></pre>")
  end

  pending "should not substitute special characters in a paragraph with verse style" do
    # Convertisseur Crystal ne traite pas encore [verse] correctement
    input = "[verse]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("He said, &lt;Let's rock!&gt;")
  end

  it "should not substitute special characters in a paragraph with normal style and subs=none" do
    input = "[subs=none]\nHe said, <Let's rock!>"
    output = Asciidoctor.convert(input)
    output.should contain("He said, <Let's rock!>")
  end

  pending "should perform substitutions on a paragraph with a role" do
    # Convertisseur Crystal ne traite pas encore l'inline markup (*bold*)
    input = "[.lead]\n*G*o*o*d times!"
    output = Asciidoctor.convert(input)
    output.should contain("<p class=\"lead\"><strong>G</strong>o<strong>o</strong>d times!</p>")
  end

  it "should apply role class to a paragraph with a role" do
    input = "[.lead]\n*G*o*o*d times!"
    output = Asciidoctor.convert(input)
    output.should contain("lead")
    output.should contain("times!")
  end

  pending "should perform substitutions on a paragraph with an id and role" do
    # Convertisseur Crystal ne traite pas encore l'inline markup (*bold*)
    input = "[#first.lead]\n*G*o*o*d times!"
    output = Asciidoctor.convert(input)
    output.should contain("<p id=\"first\" class=\"lead\"><strong>G</strong>o<strong>o</strong>d times!</p>")
  end

  it "should apply id and role to a paragraph" do
    input = "[#first.lead]\n*G*o*o*d times!"
    output = Asciidoctor.convert(input)
    output.should contain("first")
    output.should contain("lead")
  end

  it "should not create a paragraph with a hard line break if hardbreaks option is not set" do
    input = "line one\nline two"
    output = Asciidoctor.convert(input)
    output.should_not contain("<br>")
  end

  pending "should create a paragraph with a hard line break if hardbreaks option is set on document" do
    # Convertisseur Crystal ne traite pas encore l'attribut hardbreaks
    input = "line one\nline two"
    output = Asciidoctor.convert(input, {"attributes" => "hardbreaks"})
    output.should contain("line one<br>\nline two")
  end

  pending "should create a paragraph with a hard line break if hardbreaks option is set on paragraph" do
    # Convertisseur Crystal ne traite pas encore l'option hardbreaks sur les paragraphes
    input = "[hardbreaks]\nline one\nline two"
    output = Asciidoctor.convert(input)
    output.should contain("line one<br>\nline two")
  end

  pending "should create a paragraph with a hard line break if hardbreaks option is set on parent block" do
    # Convertisseur Crystal ne traite pas encore l'option hardbreaks sur les blocs parents
    input = "[hardbreaks]\n--\nline one\nline two\n--"
    output = Asciidoctor.convert(input)
    output.should contain("line one<br>\nline two")
  end

  pending "should not create a paragraph with a hard line break if hardbreaks option is disabled on paragraph" do
    # Convertisseur Crystal ne traite pas encore l'option hardbreaks=false
    input = "[hardbreaks=false]\nline one\nline two"
    output = Asciidoctor.convert(input, {"attributes" => "hardbreaks"})
    output.should contain("line one line two")
  end

  pending "should create a paragraph with a hard line break for a line that ends with a plus" do
    # Convertisseur Crystal ne traite pas encore le + en fin de ligne comme hard line break
    input = "line one +\nline two"
    output = Asciidoctor.convert(input)
    output.should contain("line one<br>\nline two")
  end

  pending "should not create a paragraph with a hard line break for a line that ends with a plus if hardbreaks are disabled" do
    # Convertisseur Crystal ne traite pas encore hardbreaks=false
    input = "[hardbreaks=false]\nline one +\nline two"
    output = Asciidoctor.convert(input, {"attributes" => "hardbreaks"})
    output.should contain("line one line two")
  end

  it "should preserve indentation of a literal paragraph as a literal block" do
    input = " literal\n\n  another"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("literal")
    output.should contain("another")
  end

  it "should not treat a spaced-out list as a literal paragraph" do
    input = "* a\n\n* b"
    output = Asciidoctor.convert(input)
    output.scan("<li>").size.should eq(2)
  end

  it "should not mistake a literal paragraph for a block title" do
    input = " a literal paragraph\n\n.not a title\n====\nfoo\n===="
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a literal paragraph")
  end

  it "should not mistake a literal paragraph for a list" do
    input = " a literal paragraph\n\n* not a list"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a literal paragraph")
  end

  it "should render a section title after a literal paragraph" do
    input = " a literal paragraph\n\n== not a title"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a literal paragraph")
  end

  it "should render an admonition after a literal paragraph" do
    input = " a literal paragraph\n\nNOTE: not an admonition"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a literal paragraph")
    output.should contain("admonitionblock")
  end

  it "should render an image after a literal paragraph" do
    input = " a literal paragraph\n\nimage::not-an-image.png[]"
    output = Asciidoctor.convert(input)
    output.should contain("literalblock")
    output.should contain("a literal paragraph")
    output.should contain("<img")
    output.should contain("not-an-image.png")
  end
end
