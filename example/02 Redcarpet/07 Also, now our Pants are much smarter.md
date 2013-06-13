Redcarpet 2 comes with a standalone [SmartyPants](
http://daringfireball.net/projects/smartypants/) implementation. It is fully
compliant with the original implementation. It is the fastest SmartyPants
parser there is, with a difference of several orders of magnitude.

The SmartyPants parser can be found in `Redcarpet::Render::SmartyPants`. It has
been implemented as a module, so it can be used standalone or as a mixin.

When mixed with a Renderer class, it will override the `postprocess` method
to perform SmartyPants replacements once the rendering is complete

~~~~ ruby
# Mixin
class HTMLWithPants < Redcarpet::Render::HTML
  include Redcarpet::Render::SmartyPants
end

# Standalone
Redcarpet::Render::SmartyPants.render("<p>Oh SmartyPants, you're so crazy...</p>")
~~~~~

SmartyPants works on top of already-rendered HTML, and will ignore replacements
inside the content of HTML tags and inside specific HTML blocks such as
`<code>` or `<pre>`.