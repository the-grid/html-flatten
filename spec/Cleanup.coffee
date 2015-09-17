Flatten = require '../build/flatten-html'
chai = require 'chai'

describe 'Cleanup', ->
  f = null
  beforeEach ->
    f = new Flatten

  describe 'cleaning an already-clean block structure', ->
    it 'should keep things as they are', (done) ->
      item =
        content: [
          id: 'foo'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          metadata:
            title: 'Foo'
        ,
          id: 'bar'
          type: 'text'
          html: '<p>This is some text</p>'
          metadata:
            title: 'Bar'
        ]
      expected = JSON.parse JSON.stringify item

      f.flattenItem item, ->
        chai.expect(item).to.eql expected
        done()

  describe 'cleaning a dirty HTML structure', ->
    it 'should produce clean blocks', (done) ->
      item =
        content: [
          id: 'foo'
          type: 'h1'
          html: '<h1 style="color: brown">Hello world!</h1><p><br/></p><p>Foobar</p>'
          metadata:
            title: 'Foo'
        ,
          id: 'bar'
          type: 'text'
          html: '<p>This is some text</p>'
          metadata:
            title: 'Bar'
        ]
      orig = JSON.parse JSON.stringify item
      f.flattenItem item, ->
        chai.expect(item.content.length).to.equal 3
        chai.expect(item.content[0]).to.eql
          id: 'foo'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          metadata:
            title: 'Foo'
        chai.expect(item.content[1]).to.eql
          type: 'text'
          html: '<p>Foobar</p>'
        chai.expect(item.content[2]).to.eql orig.content[1]
        done()

  describe 'cleaning up a full item', ->
    it 'should produce clean blocks', (done) ->
      fs = require 'fs'
      path = require 'path'
      item = JSON.parse fs.readFileSync __dirname+'/fixtures/put.json', 'utf-8'
      orig = JSON.parse JSON.stringify item
      f.flattenItem item, ->
        types = item.content.map (b) -> b.type
        chai.expect(types).to.eql [
          'image'
          'image'
          'image'
        ]
        done()
