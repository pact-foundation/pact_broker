# Rack

https://medium.com/quick-code/rack-middleware-vs-rack-application-vs-rack-the-gem-vs-rack-the-architecture-912cd583ed24
https://github.com/rack/rack/blob/main/SPEC.rdoc
https://www.rubyguides.com/2018/09/rack-middleware/


* Responds to `call`
* Accepts a hash of parameters
* Returns an array where the first item is the http status, the second is a hash of headers, and the third is an object that responds to `each` (or `call`) that provides the body (99% of the time it's an array of length 1 with a string)

