# News

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
