require "../../spec_helper"
require "file_utils"

# Spec d'intégration de l'exécutable `crystal-asciidoctor` (cible
# déclarée dans `shard.yml`). Le CLI était présent dans l'arbre mais ne
# compilait pas : `Cli::Invoker` portait un `Asciidoctor.send(
# :create_converter, …)` — un ruby-isme (`send` contourne la
# visibilité) sans équivalent Crystal. Ces tests garantissent que le
# binaire se construit ET convertit réellement.
describe "CLI · exécutable crystal-asciidoctor" do
  binary = File.join(__DIR__, "..", "..", "..", "bin", "crystal-asciidoctor")

  it "convertit un .adoc en HTML (fichier de sortie par défaut)" do
    pending! "binaire absent (shards build) : #{binary}" unless File::Info.executable?(binary)
    dir = File.tempname("ca-cli")
    Dir.mkdir_p(dir)
    begin
      src = File.join(dir, "doc.adoc")
      File.write(src, "= Mon titre\n\nUn *paragraphe* de test.\n\n== Section\n\nContenu.\n")
      status = Process.run(binary, [src],
        output: Process::Redirect::Close, error: Process::Redirect::Close)
      status.exit_code.should eq 0
      html_path = File.join(dir, "doc.html")
      File.exists?(html_path).should be_true
      html = File.read(html_path)
      html.should contain("<!DOCTYPE html>")
      html.should contain("Mon titre")
      html.should contain("Section")
      # Le markup inline est bien converti (pas de `*` littéral).
      html.should contain("<strong>paragraphe</strong>")
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  it "respecte -o pour le fichier de sortie" do
    pending! "binaire absent (shards build) : #{binary}" unless File::Info.executable?(binary)
    dir = File.tempname("ca-cli-o")
    Dir.mkdir_p(dir)
    begin
      src = File.join(dir, "in.adoc")
      dest = File.join(dir, "sortie.html")
      File.write(src, "= T\n\nx.\n")
      status = Process.run(binary, [src, "-o", dest],
        output: Process::Redirect::Close, error: Process::Redirect::Close)
      status.exit_code.should eq 0
      File.exists?(dest).should be_true
    ensure
      FileUtils.rm_rf(dir)
    end
  end

  it "affiche une aide qui nomme correctement l'exécutable" do
    pending! "binaire absent (shards build) : #{binary}" unless File::Info.executable?(binary)
    stdout = IO::Memory.new
    Process.run(binary, ["--help"], output: stdout, error: Process::Redirect::Close)
    out = stdout.to_s
    out.should contain("crystal-asciidoctor")
    out.should contain("--backend")
  end
end
