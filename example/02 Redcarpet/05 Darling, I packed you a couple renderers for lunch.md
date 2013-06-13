Redcarpet comes with two built-in renderers, `Redcarpet::Render::HTML` and
`Redcarpet::Render::XHTML`, which output HTML and XHTML, respectively. These
renderers are actually implemented in C and hence offer brilliant
performance — several degrees of magnitude faster than other Ruby Markdown
solutions.

All the rendering flags that previously applied only to HTML output have
now been moved to the `Render::HTML` class, and may be enabled when
instantiating the renderer:

~~~~~ ruby
Render::HTML.new(render_options = {})
~~~~~

Initializes an HTML renderer. The following flags are available:

* `:filter_html`: do not allow any user-inputted HTML in the output.

* `:no_images`: do not generate any `<img>` tags.

* `:no_links`: do not generate any `<a>` tags.

* `:no_styles`: do not generate any `<style>` tags.

* `:safe_links_only`: only generate links for protocols which are considered
safe.

* `:with_toc_data`: add HTML anchors to each header in the output HTML,
to allow linking to each section.

* `:hard_wrap`: insert HTML `<br>` tags inside on paragraphs where the origin
Markdown document had newlines (by default, Markdown ignores these newlines).

* `:xhtml`: output XHTML-conformant tags. This option is always enabled in the
`Render::XHTML` renderer.

* `:prettify`: add prettyprint classes to `<code>` tags for google-code-prettify.

* `:link_attributes`: hash of extra attributes to add to links.

Example:

~~~~~ ruby
renderer = Redcarpet::Render::HTML.new(:no_links => true, :hard_wrap => true)
~~~~~


The `HTML` renderer has an alternate version, `Redcarpet::Render::HTML_TOC`,
which will output a table of contents in HTML based on the headers of the
Markdown document.

Furthermore, the abstract base class `Redcarpet::Render::Base` can be used
to write a custom renderer purely in Ruby, or extending an existing renderer.
See the following section for more information.
