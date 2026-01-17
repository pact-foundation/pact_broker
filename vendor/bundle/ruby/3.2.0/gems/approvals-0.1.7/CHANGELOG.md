# Changelog

### Next Release

* Your contribution here

* Updated gemspec to make 'json' an explicit dependency

### v0.0.22 (2015-10-22)

* Fix bug in non-binary comparisons.

### v0.0.21 (2015-10-12)

* [#64](https://github.com/kytrinyx/approvals/pull/64) Silence deprecation warnings - [@tmock12](https://github.com/tmock12)
* Fixed typos and replaced a deprecated standard library method call.

### v0.0.20 (2015-04-21)

* [#63](https://github.com/kytrinyx/approvals/issues/62) Make CLI --ask compatible with new or old .approval file. - [@kytrinyx](https://github.com/kytrinyx)

### v0.0.19 (2015-04-20)

* [#62](https://github.com/kytrinyx/approvals/issues/62) Fix bug in CLI with --ask option that deletes approval file instead of overwriting it. - [@kytrinyx](https://github.com/kytrinyx)

### v0.0.18 (2015-04-18)

- Greatly improve output on failure (Show the diff even if approved file is missing, don't complain if there's no .approvals file, print diff command before showing each diff for better context, and reverse the order of the arguments to the diff so that the additions/removals make sense). - [@randycoulman](https://github.com/randycoulman)
- General improvements (fix typos, replace PNG badges with SVG ones) - [@jamonholmgren](https://github.com/jamonholmgren), [@olivierlacan](https://github.com/olivierlacan)

### v0.0.17 (2014-10-10)

- [#55](https://github.com/kytrinyx/approvals/pull/55) Upgrade to RSpec 3.1 - [@Willianvdv](https://github.com/Willianvdv)

### v0.0.16 (2014-05-19)

- General improvements (refactoring, simplify travis build, fix whitespace issues) - [@zph](https://github.com/zph), [@markijbema](https://github.com/markijbema)
- Ignore trailing whitespace when making assertions. - [@kytrinyx](https://github.com/kytrinyx)

### v0.0.15 (2014-04-05)

- [#46](https://github.com/kytrinyx/approvals/pull/46) Improve handling of malformed HTML. - [@hotgazpacho](https://github.com/hotgazpacho)

### v0.0.14 (2014-04-05)

- [#48](https://github.com/kytrinyx/approvals/pull/48) Fix CLI namespace clash. - [@zph](https://github.com/zph)

### v0.0.13 (2014-03-10)

- Allow verifying hashes and arrays as json. - [@markijbema](https://github.com/markijbema)
- Add support for RSpec 3.0. - [@markijbema](https://github.com/markijbema)
- General improvements (documentation, README, refactoring). - [@markijbema](https://github.com/markijbema), [@kytrinyx](https://github.com/kytrinyx)

### v0.0.12 (2014-02-16)

- [#34](https://github.com/kytrinyx/approvals/pull/34) Make default formatter configurable. - [@markijbema](https://github.com/markijbema)
- Update dependencies, and lock them to major releases.
- Add a license to the gemspec.
- Add a default rake task.

### v0.0.11 (2014-02-16)

- [#33](https://github.com/kytrinyx/approvals/pull/33) Append a trailing newline to all approval files. - [@markijbema](https://github.com/markijbema)

### v0.0.10 (2014-01-30)

- [#9](https://github.com/kytrinyx/approvals/pull/9) Add option to let RSpec handle diffing when approval fails. - [@jeremyruppel](https://github.com/jeremyruppel)
- [#19](https://github.com/kytrinyx/approvals/pull/19) Switch rspec fail_with args so diff is correct. - [@bmarini](https://github.com/bmarini)
- Fix build, clean up specs, add badges, add CHANGELOG, fix warnings. - [@markijbema](https://github.com/markijbema)

### v0.0.9 (2013-10-08)

Before this version, no changelog was maintained
