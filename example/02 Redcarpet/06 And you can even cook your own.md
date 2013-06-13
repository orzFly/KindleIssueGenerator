Custom renderers are created by inheriting from an existing renderer. The
built-in renderers, `HTML` and `XHTML` may be extended as such:

~~~~~ ruby
# create a custom renderer that allows highlighting of code blocks
class HTMLwithPygments < Redcarpet::Render::HTML
  def block_code(code, language)
    Pygments.highlight(code, :lexer => language)
  end
end

markdown = Redcarpet::Markdown.new(HTMLwithPygments, :fenced_code_blocks => true)
~~~~~

But new renderers can also be created from scratch (see `lib/redcarpet/render_man.rb` for
an example implementation of a Manpage renderer)

~~~~~~ ruby
class ManPage < Redcarpet::Render::Base
  # you get the drill -- keep going from here
end
~~~~~

The following instance methods may be implemented by the renderer:

### Block-level calls

If the return value of the method is `nil`, the block will be skipped.
If the method for a document element is not implemented, the block will
be skipped.

Example:

~~~~ ruby
class RenderWithoutCode < Redcarpet::Render::HTML
  def block_code(code, language)
    nil
  end
end
~~~~

* block_code(code, language)
* block_quote(quote)
* block_html(raw_html)
* header(text, header_level)
* hrule()
* list(contents, list_type)
* list_item(text, list_type)
* paragraph(text)
* table(header, body)
* table_row(content)
* table_cell(content, alignment)

### Span-level calls

A return value of `nil` will not output any data. If the method for
a document element is not implemented, the contents of the span will
be copied verbatim:

* autolink(link, link_type)
* codespan(code)
* double_emphasis(text)
* emphasis(text)
* image(link, title, alt_text)
* linebreak()
* link(link, title, content)
* raw_html(raw_html)
* triple_emphasis(text)
* strikethrough(text)
* superscript(text)
* underline(text)
* highlight(text)

### Low level rendering

* entity(text)
* normal_text(text)

### Header of the document

Rendered before any another elements:

* doc_header()

### Footer of the document

Rendered after all the other elements:

* doc_footer()

### Pre/post-process

Special callback: preprocess or postprocess the whole document before
or after the rendering process begins:

* preprocess(full_document)
* postprocess(full_document)

You can look at
["How to extend the Redcarpet 2 Markdown library?"](http://dev.af83.com/2012/02/27/howto-extend-the-redcarpet2-markdown-lib.html)
for some more explanations.