# News
## <a id="2-3-5">2.3.5</a>: 2012-12-11

This is a bug fix release.

### Fixes

  * [POParser] Fixed the class name for backward compatibility.

## <a id="2-3-4">2.3.4</a>: 2012-12-11

This is a many changes and new implements release.

### Improvements

  * [Merger] Implemented "fuzzy-match" with Levenshtein distance.
  * Added the class "PO" for management PO entries. Please use PO
    instead of PoData. (see details in
    http://rubydoc.info/gems/gettext/GetText/PO.html)
  * [POEntry (renamed from PoMessages)] Supported to specify msgstr.
  * [POEntry]　Stored comments each type
    (translator\_comment, extracted\_comment, flag, previous).
    see
    http://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
    for details of comment type.
  * [POEntry] Checked if specified type is valid in #type=.
  * [PoParser][MO] Concatenated msgctxt, msgid, msgid\_plural to
    "#{msgctxt}\004#{msgid}\000"{msgid\_plural}" by MO instead of
    PoParser. PoData and MO treat a concatenated string as msgid, but
    PO doesn't.
  * [PoParser] Parsed each type comment from whole comment.

### Changes

  * Rename some classes and methods.
    * PoMessage to PoEntry. This isn't "message" but "entry".
      (See http://www.gnu.org/software/gettext/manual/gettext.html#PO-Files)
    * PoMessages#== to POEntry#mergeable?.
    * PoMessages#to\_po\_str to POEntry#to\_s.
    * PoMessages#sources(sources=) to POEntry#references(references=)
    * MoFile to MO. For backword compatible, MoFile can be used now.
    * PoParser to POParser. For backword compatible, PoParser can be used now.
  * Raised no error when POEntry doesn't have references.
    It is useful for no references in .PO file.

# News
## <a id="2-3-3">2.3.3</a>: 2012-10-18

It's a package fix and msginit improvement release.

### Improvements

  * [msginit] Supported plural forms for Bosnian, Catalan, Norwegian
    Bokmal and Chinese.

### Fixes

  * Fixed the bug that messages (i.e. the help message for rmsgfmt)
    aren't localized in each environment. However, some
    messages aren't tranlated or resolved fuzzy. Please
    help us to translate or resolve them.
    [Github #12][Reported by mtasaka]
  * Used String#% to localize some messages.

### Thanks

  * mtasaka

## <a id="2-3-2">2.3.2</a>: 2012-09-20

It's a bug fix release.

### Fixes

  * Fixed the bug that untranslated messages are included in a .mo file.
    [Github #11][Reported by Ramón Cahenzli]

### Thanks

  * Ramón Cahenzli

## <a id="2-3-1">2.3.1</a>: 2012-09-13

It's a Bug and package fix release.
Then, it's also encoding support release, only if you use Ruby 1.9.

### Improvements

  * [xgettext] Added backword compatibility method
    (GetText::RGetText.run).
    [Suggested by Fotos Georgiadis]
  * [xgettext] Removed deprecated parse argument support.
  * [erb parer] Assumed the encoding in the magic comment of the
    input file as the encoding of it.
  * [ruby parser] Assumed the encoding in the magic comment of the
    input file as the encoding of it.
  * [xgettext] Added the "--output-encoding" option to set encoding of
    output pot file.
  * [xgettext] Used UTF-8 as the default encoding of output pot file.
  * [xgettext] Supported multiple encoding sources.

### Changes

  * [MoFile] Returned nil instead of "" as msgstr when its msgid isn't
    translated (when this msgstr is "").
  * [PoParser] Converted msgstr from "" to nil when parsing.

### Fixes

  * Added missing .yardopts file. [Reported by Takahiro Kambe]
  * [news] Fixed Eddie Lau name instead of github name.
  * [msginit] Added the "Plural-Forms:" entry to the header even if a
    pot file doesn't have it.
  * [msgmerge] Fixed the bug the new line between a header and
    contents doesn't exist.
  * [msginit] Fixed the bug that msgstr with msgid_plural aren't
    generated in output po file.
  * [xgettext] Supported class based xgettext parser add API.
    [GitHub #10] [Suggested by Michael Grosser]
  * [erb parer] Fixed erb parser bug with unicode msgid in Ruby 1.9
    ERB templates.
    [Github #9] [Patch by Fotos Georgiadis]
  * Added missing documents for GetText::Tools::XGetText.

### Thanks

  * Takahiro Kambe
  * Michael Grosser
  * Fotos Georgiadis

## <a id="2-3-0">2.3.0</a>: 2012-08-28

Various improvements, changes and fixes release.

### Improvements

  * Improved TextDomain#translate\_singluar\_message performance.
    [Base idea is provided by @angelf]
  * Added msginit command.
  * [xgettext] Added command line options for package name, version,
    copyright holder and msgid bugs address.[Github#8]
    [Reported by Francesco Poli (wintermute) and 375gnu, and patch by 375gnu]
  * [xgettext] Supported s\_ and ns\_ with parameter.
  * [poparser] Reported warnings when fuzzy message is used.
    [Reported by Michael Grosser]
  * Used %{...} to check the availability of String#% with hash and
    raise Error if this syntax isn't supported.
  * Searched mo files under LC_MESSAGES/ directory.
  * Updated documents for tools.

### Changes

  * Renamed the package name from "Ruby-GetText-Package" to "gettext".
  * Renamed RGetText to XGetText, RMsgMerge to MsgMerge, RMsgFmt to MsgFmt.
  * Renamed rgettext to rxgettext.
  * Defined tools(XGetText, MsgMerge, MsgFmt) as Class under GetText::Tools
    module.
  * Removed shortcuts for tools in GetText module.
    Please use GetText::Tools:XXX.run instead of GetText.xxx.
  * Changed API of tools.
    e.g.) Before: GetText.rsmgfmt(targetfile, output\_path)
          Now: GetText::Tools::MsgFmt.run(targetfile, "-o", output\_path)
  * [xgettext] Used relative path for source path.
    This path appears in generated pot file.
  * [xgettext] Returned the pot header instead of "" as the translation of
    "" msgid.
  * [poparser] Treated not translated msgid when parsing po file.
    A translation of no translated msgid is msgid itself even now.
  * [xgettext] Removed descriptions of ruby in information by "-v" option.

### Fixes

  * Included msgctxt when generating .po file. [Patch by 3dd13]
  * Fixed a typo in msgmerge. [Patch by Yves-Eric Martin]
  * [msgmerge] Followed PoParser API change.
  * [ruby-parser] Reseted the last comment when po message is stored.[Github#6]
    [Reported by 375gnu and Francesco Poli (wintermute), and Patch by 375gnu]
  * [ruby-parser] Processed RubyToken::TkDSTRING too.[Github#6]
    [Reported by 375gnu and Francesco Poli (wintermute), and Patch by 375gnu]
  * [msgmerge] Fixed not to add fuzzy to header message.
  * [msgmerge] Escaped backslash and "\n".

### Thanks

  * @angelf
  * Francesco Poli (wintermute)
  * 375gnu
  * Michael Grosser
  * Eddie Lau
  * Yves-Eric Martin

## <a id="2-2-0">2.2.0</a>: 2012-03-11

Ruby 1.9 support release.

### Improvements

  * Supported ruby-1.9. [Patch by hallelujah]
  * Supported $SAFE=1. [Patch by bon]
  * Improved argument check. [Suggested by Morus Walter]
  * Supported ruby-1.8.6 again. [Bug#27447] [Reported by Mamoru Tasaka]

### Fixes

  * Fixed Ukrainan translation path. [Bug#28277] [Reported by Gunnar Wolf]
  * Fixed a bug that only the last path in GETTEXT_PATH environment
    variable is used. [Bug#28345] [Reported by Ivan Pirlik]
  * Fixed a bug that Ruby-GetText-Package modifies $LOAD_PATH. [Bug#28094]
    [Reported by Tatsuki Sugiura]

### Thanks

  * hallelujah
  * bon
  * Morus Walter
  * Mamoru Tasaka
  * Gunnar Wolf
  * Ivan Pirlik
  * Tatsuki Sugiura
