# Interpreting the Matrix results

* If there is a row with a blank provider version, it's because the pact for that consumer version hasn't been verified by that provider (the result of a left outer join).
* If there is no row, it's because it has been verified, but not by the provider version you've specified.
