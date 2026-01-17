# Expgen

Expgen solves a very simple problem: Given a regular expression, find a string
which matches that regular expression. Use it like this:

``` ruby
Expgen.gen(/foo\w+b[a-z]{2,3}/) # => "fooxbdp"
```

For a full list of supported syntax, see the spec file.

Some things are really difficult to generate accurate expressions for, it's
even quite easy to create a regexp which matches *no* strings. For example
`/a\bc/` will not match any string, since there can never be a word boundary
between characters.

When given a negative character class, Expgen takes the entire ASCII character
set (sans control characters) and removes from it any characters excluded by the
character class. In other words, if the character class excludes the *entire*
ASCII character set, Expgen will be unable to fill this space.

The following is a list of things Expgen does *not* support:

- Anchors (are ignored)
- Lookaheads and lookbehinds
- Subexpressions
- Backreferences

## Doesn't this already exist?

There is a gem called Randexp which does much the same thing. Expgen differs
from Randexp in two important ways. (1) It actually works. (2) It supports a
*much* wider range of regexp syntax.

The idea behind Expgen is that you should be able to take any reasonable, real
world regular expression and be able to generate matching strings. The focus is
on finding Strings which match a particular expression, not necessarily using
it as a random generator.

# License

MIT, see separate LICENSE.txt file
