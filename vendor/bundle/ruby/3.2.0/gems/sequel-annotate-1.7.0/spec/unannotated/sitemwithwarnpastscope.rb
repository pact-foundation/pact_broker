# warn_past_scope: true
# warn_indent: false
# Additional comment that should stay
class SItemWithWarnPastScope < Sequel::Model(SDB[:items])
end
