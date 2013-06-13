What a terrible idea! Markdown is already ill-specified enough; if you create
software that is renderer-independent, the results will be completely unreliable!

Each renderer has its own API and its own set of extensions: you should choose one
(it doesn't have to be Redcarpet, though that would be great!), write your
software accordingly, and force your users to install it. That's the
only way to have reliable and predictable Markdown output on your program.

Still, if major forces (let's say, tornadoes or other natural disasters) force you
to keep a Markdown-compatibility layer, Redcarpet also supports this:

~~~~~ ruby
require 'redcarpet/compat'
~~~~~

Requiring the compatibility library will declare a `Markdown` class with the
classical RedCloth API, e.g.

~~~~~ ruby
Markdown.new('this is my text').to_html
~~~~~

This class renders 100% standards compliant Markdown with 0 extensions. Nada.
Don't even try to enable extensions with a compatibility layer, because
that's a maintenance nightmare and won't work.

On a related topic: if your Markdown gem has a `lib/markdown.rb` file that
monkeypatches the Markdown class, you're a terrible human being. Just saying.