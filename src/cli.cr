require "./asciicrystal"

options = Asciicrystal::Cli::Options.parse(ARGV)
invoker = Asciicrystal::Cli::Invoker.new(options)
exit invoker.invoke!
