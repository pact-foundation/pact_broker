const handlebars = require('handlebars')
const data = require('./routes.json')
const template = `openapi: '3.0.3'

info:
  version: "0.0.1"
  title: "pact test"

paths:
{{#each this}}
  {{this.path}}:
    get:
      summary: {{this.class}}
      operationId: {{this.path}}
      responses:
        default:
          description: {{this.class}}
{{/each}}
`
const render = handlebars.compile(template, { noEscape: true })
const res = render(data, {helpers: { json: JSON.stringify }})
console.log(res)