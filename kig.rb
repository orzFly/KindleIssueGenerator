#!/usr/bin/env ruby
# encoding: utf-8
module Kernel
  def warning(message)
    warn "#{File.basename($0)}: warning: #{message}"
  end

  def error(message)
    STDERR.puts "#{File.basename($0)}: error: #{message}"
  end

  def fatal(message)
    STDERR.puts "#{File.basename($0)}: fatal: #{message}"
    exit 1
  end
end

begin
  require 'htmlentities'
rescue LoadError
  fatal "Need ruby gem: htmlentities"
end
require 'tmpdir'
require 'fileutils'
require 'rexml/document'

module KindleIssueGenerator
  fatal "Require Ruby 1.9 or higher" if RUBY_VERSION < "1.9"

  module DocumentFormats
    class Format
      def initialize(file)
        j = File.read(file)
		r = nil
		r ||= ((j.force_encoding("utf-8").gsub("123",""); j) rescue nil)
		r ||= (j.force_encoding("gb18030").encode("utf-8") rescue nil)
		r ||= (j.force_encoding("gbk").encode("utf-8") rescue nil)
		r ||= (j.force_encoding("gb2312").encode("utf-8") rescue nil)
		r ||= ""
		@content = r
      end
    end
    
    class HTML < Format
      def html
        @content
      end
      
      def plain
        # strip_tags(@content)
      end
    end
    HTM = HTML
    
    class TXT < Format
      def html
        "<pre>#{HTMLEntities.new.encode(@content)}</pre>"
      end
      
      def plain
        @content
      end
    end
  end

  class Article
    attr_accessor :sortindex
    attr_reader   :uid
    attr_accessor :author
    attr_accessor :title
    attr_accessor :description
    attr_accessor :body
    attr_accessor :format
    
    def initialize
      @uid = 32.times.map{"0123456789abcdefghijklmnopqrstuvwxyz"[(36 * rand).floor]}.join
    end
    
    def self.from_file(filename)
      art = Article.new
      fn = File.basename(filename)
      art.format = fn[fn.rindex(".") + 1, fn.length].upcase
      art.title = fn[0, fn.rindex(".")]
      if art.title[/^(\d+)\s*(.*?)$/]
        art.sortindex = $1.to_i
        art.title = $2
      end
      
      if DocumentFormats.const_defined?(art.format)
        fc = DocumentFormats.const_get(art.format)
        f = fc.new(filename)
        art.body = f.html
        art.description = f.plain.gsub("\n", "").gsub("\r", "")[0, 200]
      else
        fatal("Unsupport format: `#{art.format}' for `#{filename}'")
      end
      
      art
    end
  end
  
  class Section
    attr_accessor :sortindex
    attr_reader   :uid
    attr_accessor :title
    attr_accessor :articles
    
    def initialize
      @uid = 32.times.map{"0123456789abcdefghijklmnopqrstuvwxyz"[(36 * rand).floor]}.join
      @articles = []
    end
    
    def [](id)
      @articles[id]
    end
    
    def []=(id, value)
      @articles[id] = value
    end
    
    def self.from_directory(dir)
      sec = Section.new
      sec.title = File.basename(dir)
      if sec.title[/^(\d+)\s*(.*?)$/]
        sec.sortindex = $1.to_i
        sec.title = $2
      end
      
      Dir[File.join(dir, "*")].each do |i|
        t = File.basename(i)
        if (t.index(".") || 0) >= 1
          sec.articles << Article.from_file(i)
        end
      end
      
      if sec.articles.all?{|i|i.sortindex}
        sec.articles.sort_by!{|i|i.sortindex}
      else
        sec.articles.sort_by!{|i|i.title}
      end
      
      sec
    end
  end
  
  class Issue
    attr_accessor :sections
    attr_accessor :title
    attr_accessor :author
    attr_accessor :logo_filename
    attr_accessor :cover_filename
    attr_accessor :uid
    attr_accessor :language
    attr_accessor :publisher
    attr_accessor :date
    attr_accessor :description
    attr_accessor :review
    
    def initialize
      @sections = []
    end
    
    def [](id)
      @sections[id]
    end
    
    def []=(id, value)
      @sections[id] = value
    end
    
    def self.from_repository(basedir)
      i = Issue.new
      i.parse_manifest(File.read(File.join(basedir, "issue.rb")))
      
      Dir[File.join(basedir, "*")].each do |j|
        if File.directory?(j) && File.basename(j)[0] != "."
          i.sections << Section.from_directory(j)
        end
      end
      
      if i.sections.all?{|j|j.sortindex}
        i.sections.sort_by!{ |j| j.sortindex }
      else
        i.sections.sort_by!{ |j| j.title }
      end
      
      i
    end
    
    def parse_manifest(r)
      eval r
    end
    
    def compile(output)
	  Dir.mktmpdir { |path|
		open File.join(path, "end.html"), "w" do |io| io.write <<EOF end
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>END</title>
    <link rel="stylesheet" href="issue.css" type="text/css" />
</head>
<body id="_undefined" class="">
<h1 class="centered">End of Book</h1>
<hr />
<p class="centered"><small>Thanks for your reading<br />KindleIssueGenerator</small></p>
</body>
</html>
EOF

      open File.join(path, "issue.css"), "w" do |io| io.write <<EOF end
/* For supported css features see: http://www.idpf.org/2007/ops/OPS_2.0_final_spec.html#Section3.0 */
/* Warn: kindle will strip long tags, so do not use selector may span long tags. */

.pagebreak { page-break-before: always; }
.centered { text-align: center; }
.bottom { vertical-align: text-bottom; }
.quiet { color: #888; }
.x-small { font-size: x-small; }

.toc-index { color: #666; }
a.toc-link { color: #000; }
.toc-domain { color: #999; }

#item-title { margin: 0 0 .2em; }
#item-feed-title { margin: .2em 0 1em; color: #777; font-size: x-small; }

p#discard-items-msg { padding: 0 2em; font-size: x-small; }

code { font-size: small; } 
EOF
      
		open File.join(path, "#{@uid}.opf"), "w" do |io| io.write <<EOF end
<?xml version="1.0" encoding="UTF-8" ?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0" unique-identifier="#{HTMLEntities.new.encode(@uid)}">
    <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
        <dc:title>#{HTMLEntities.new.encode(@title)}</dc:title>
        <dc:language>#{HTMLEntities.new.encode(@language)}</dc:language>
        <dc:identifier id="uid">#{HTMLEntities.new.encode(@uid)}</dc:identifier>
        <dc:creator>#{HTMLEntities.new.encode(@author)}</dc:creator>
        <dc:publisher>#{HTMLEntities.new.encode(@publisher)}</dc:publisher>
        <dc:subject>NON-CLASSIFIABLE</dc:subject>
        <dc:date>#{HTMLEntities.new.encode(@date)}</dc:date>
        <dc:description>#{HTMLEntities.new.encode(@description)}</dc:description>
        <x-metadata>
            <output encoding="utf-8" content-type="application/x-mobipocket-subscription-magazine"></output>
			#{@cover_filename ? '<EmbeddedCover>' + HTMLEntities.new.encode(@cover_filename) + '</EmbeddedCover>' : nil}
			<Review>#{HTMLEntities.new.encode(@review)}</Review>
        </x-metadata>
        
    </metadata>

    <manifest>
        <item id="toc" media-type="application/x-dtbncx+xml" href="toc.ncx"/>
        <item id="toc-html" media-type="application/xhtml+xml" href="toc.html"></item>
        #{@cover_filename ? '<item id="cover" media-type="image/jpeg" href="' + HTMLEntities.new.encode(@cover_filename) + '" properties="cover-image" />' : nil}
	    <item id="end" media-type="application/xhtml+xml" href="end.html"></item>
		#{
			@sections.map {|sec|
				'<item id="section-' + sec.uid + '" media-type="application/xhtml+xml" href="section-' + sec.uid + '.html"></item>' + 
				sec.articles.map {|art|
					'<item id="item-' + art.uid + '" media-type="application/xhtml+xml" href="item-' + art.uid + '.html"></item>'
				}.join
			}.join
		}
    </manifest>

    <spine toc="toc">
        <itemref idref="toc-html"/>
		#{
			@sections.map {|sec|
				'<itemref idref="section-' + sec.uid + '" />' + 
				sec.articles.map {|art|
					'<itemref idref="item-' + art.uid + '" />'
				}.join
			}.join
		}
        <itemref idref="end"/>
    </spine>

    <guide>
        <reference type="toc" title="Table of Contents" href="toc.html"></reference>
    </guide>
</package>
EOF

		open File.join(path, "toc.ncx"), "w" do |io| io.write <<EOF end
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN" "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="en-US">
    <head>
        <meta name="dtb:uid" content="#{HTMLEntities.new.encode(@uid)}"/>
        <meta name="dtb:depth" content="3"/>
        <meta name="dtb:totalPageCount" content="0"/>
        <meta name="dtb:maxPageNumber" content="0"/>
    </head>
    
    <docTitle><text>#{HTMLEntities.new.encode(@title)}</text></docTitle>
    <docAuthor><text>#{HTMLEntities.new.encode(@author)}</text></docAuthor>
    
    <navMap>
        <navPoint playOrder="0" class="periodical" id="periodical">
            <navLabel><text>Table of Contents</text></navLabel>
            <content src="toc.html" />
			#{
				i = 0; nil
				@sections.map {|sec|
					'<navPoint class="section" playOrder="' + (i += 1).to_s + '"><navLabel><text>' + HTMLEntities.new.encode(sec.title) + '</text></navLabel><content src="section-' + sec.uid + '.html" />' + 
					sec.articles.map {|art|
						'<navPoint id="item-' + art.uid + '" class="article" playOrder="' + (i += 1).to_s + '">
							<navLabel><text>' + HTMLEntities.new.encode(art.title) + '</text></navLabel>
							<content src="item-' + art.uid + '.html" />
							<mbp:meta name="author">' + HTMLEntities.new.encode(art.author || "Unknown Author") + '</mbp:meta>
							<mbp:meta name="description">' + HTMLEntities.new.encode(art.description || "...") + '</mbp:meta>
						</navPoint>'
					}.join + 
					'</navPoint>'
				}.join
			}
        </navPoint>
    </navMap>
</ncx>
EOF

		open File.join(path, "toc.html"), "w" do |io| io.write <<EOF end
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>Table of Contents</title>
    <link rel="stylesheet" href="issue.css" type="text/css" />
</head>
<body id="_undefined" class="">
<h1>TABLE OF CONTENTS</h1>
<div id="toc">
    #{
		@sections.map {|sec|
			i = 0
			'<h2>' + HTMLEntities.new.encode(sec.title) + '</h2>' + 
			sec.articles.map {|art|
				'<div><big class="toc-index">' + (i += 1).to_s + '. </big><a href="item-' + art.uid + '.html">' + HTMLEntities.new.encode(art.title) + '</a><small class="toc-domain">' + HTMLEntities.new.encode(sec.title) + '</small></div>'
			}.join
		}.join
	}
</div>
</body>
</html>
EOF

		  @sections.each { |sec|
			open File.join(path, "section-#{sec.uid}.html"), "w" do |io| io.write "<html><head></head><body></body></html>" end
			sec.articles.each { |art|
				open File.join(path, "item-#{art.uid}.html"), "w" do |io| io.write <<EOF end
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <title>#{HTMLEntities.new.encode(art.title)}</title>
    <link rel="stylesheet" href="issue.css" type="text/css" />
</head>
<body id="_undefined" class="">
<h1 id="item-title" class="centered">#{HTMLEntities.new.encode(art.title)}</h1>
<div id="item-feed-title" class="centered">
    #{HTMLEntities.new.encode(sec.title)}
    | #{HTMLEntities.new.encode(art.author || "Unknown Author")}
</div>
<div id="content">#{art.body}</div>
</body>
</html>
EOF
	#"
			}
		}
		  
		  pwd = Dir.pwd
		  Dir.chdir(path)
		  system("#{File.join(File.dirname(__FILE__), "kindlegen.exe")} *.opf -o result.mobi")
		  Dir.chdir(pwd)
			
		  FileUtils.cp(File.join(path, "result.mobi"), output)
	  }
    end
  end
  
  module Commands
    module Generic
      def self.version
        puts "#{File.basename($0)} 1.0"
      end
      
      def self.usage
        puts <<USAGE
usage: #{File.basename($0)} <command> [<args>]
USAGE
      end
      
      def self.help
        self.usage
      end
      
      def self.init
        if K.is_repo?
          fatal("Already initialized")
        end
		open "issue.rb", "w" do |io| io.write <<EOJ end
# encoding: utf-8
@title = ""
@author = ""
@logo_filename = nil
@cover_filename = nil
@uid = "#{32.times.map{"0123456789abcdefghijklmnopqrstuvwxyz"[(36 * rand).floor]}.join}"
@language = "en-us"
@publisher = "KindleIssueGenerator"
@date = Time.now.strftime("%Y-%m-%d")
@description = <<EOF

EOF
@review = <<EOF
EOF
EOJ
		puts <<USAGE
`issue.rb' generated.

Next things:
* Edit `issue.rb'
* Create directories for sections
* Create HTML/TXT/Markdown files in directories for articles
* Compile by `#{File.basename($0)} compile`
USAGE
      end
    end
    
    module Repository
      def self.compile
        i = Issue.from_repository(".")
        i.compile("./issue.mobi")
      end
    end
  end
  
  def self.is_repo?
    File.exist? "issue.rb"
  end
end
K = KindleIssueGenerator

ARGV[0] ||= "usage"
ARGV[0] = ARGV[0].gsub(/[^A-Za-z]/, "").downcase
if K::Commands::Generic.respond_to? ARGV[0]
  K::Commands::Generic.send ARGV[0].to_sym, *ARGV[1..-1]
elsif K::Commands::Repository.respond_to? ARGV[0]
  if K.is_repo?
    K::Commands::Repository.send ARGV[0].to_sym, *ARGV[1..-1]
  else
    fatal "Not a book repository"
  end
else
  error "`#{ARGV[0]}' is not a valid command."
  K::Commands::Generic.usage
end