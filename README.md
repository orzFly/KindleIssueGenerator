KindleIssueGenerator (kig.rb)
=============================

A ruby script which provides a simple way to use Amazon's 'Kindlegen.exe' to
generate issues for Kindle.

Dependency
----------
* gem 'htmlentities'
* gem 'redcarpet' if used?(Markdown)

Usage
-----
* In a empty directory, invoke: `kig.rb init`
* Edit `issue.rb'
* Create directories for sections
* Create HTML/TXT/Markdown files in directories for articles
* Compile by `kig.rb compile`

License
-------
See http://orzfly.com/licenses/mit