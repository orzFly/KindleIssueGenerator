
The core of the Redcarpet library is the `Redcarpet::Markdown` class. Each
instance of the class is attached to a `Renderer` object; the Markdown class
performs parsing of a document and uses the attached renderer to generate
output.

The `Markdown` object is encouraged to be instantiated once with the required
settings, and reused between parses.

~~~~~ ruby
# Initializes a Markdown parser
Markdown.new(renderer, extensions = {})
~~~~~


Here, the `renderer` variable refers to a renderer object, inheriting
from `Redcarpet::Render::Base`. If the given object has not been
instantiated, the library will do it with default arguments.

You can also specify a hash containing the Markdown extensions which the
parser will identify. The following extensions are accepted:

* `:no_intra_emphasis`: do not parse emphasis inside of words.
Strings such as `foo_bar_baz` will not generate `<em>` tags.

* `:tables`: parse tables, PHP-Markdown style.

* `:fenced_code_blocks`: parse fenced code blocks, PHP-Markdown
style. Blocks delimited with 3 or more `~` or backtickswill be considered
as code, without the need to be indented. An optional language name may
be added at the end of the opening fence for the code block.

* `:autolink`: parse links even when they are not enclosed in `<>`
characters. Autolinks for the http, https and ftp protocols will be
automatically detected. Email addresses are also handled, and http
links without protocol, but starting with `www`.

* `:disable_indented_code_blocks`: do not parse usual markdown
code blocks. Markdown converts text with four spaces at
the front of each line to code blocks. This options
prevents it from doing so. Recommended to use
with `fenced_code_blocks: true`.

* `:strikethrough`: parse strikethrough, PHP-Markdown style
Two `~` characters mark the start of a strikethrough,
e.g. `this is ~~good~~ bad`.

* `:lax_spacing`: HTML blocks do not require to be surrounded by an
empty line as in the Markdown standard.

* `:space_after_headers`: A space is always required between the hash
at the beginning of a header and its name, e.g. `#this is my header`
would not be a valid header.

* `:superscript`: parse superscripts after the `^` character; contiguous superscripts are nested together, and complex values can be enclosed in parenthesis, e.g. `this is the 2^(nd) time`

* `:underline`: parse underscored emphasis as underlines.
`This is _underlined_ but this is still *italic*`.

* `:highlight`: parse highlights.
`This is ==highlighted==`. It looks like this: `<mark>highlighted</mark>`

Example:

~~~~~ ruby
markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, :autolink => true, :space_after_headers => true)
~~~~~

Rendering with the `Markdown` object is done through `Markdown#render`.
Unlike in the RedCloth API, the text to render is passed as an argument
and not stored inside the `Markdown` instance, to encourage reusability.
Example:

~~~~~ ruby
markdown.render("This is *bongos*, indeed.")
# => "<p>This is <em>bongos</em>, indeed</p>"
~~~~~