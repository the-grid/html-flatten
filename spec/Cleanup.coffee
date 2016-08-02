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
      expected.content[0].text = 'Hello world!'
      expected.content[1].text = 'This is some text'

      f.flattenItem item, (err) ->
        return done err if err
        chai.expect(item).to.eql expected
        done()

  describe 'cleaning a block structure with placeholder', ->
    it 'should keep things as they are', (done) ->
      item =
        content: [
          id: 'foo'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          metadata:
            title: 'Foo'
        ,
          id: 'baz'
          type: 'placeholder'
          html: ''
        ,
          id: 'bar'
          type: 'text'
          html: '<p>This is some text</p>'
          metadata:
            title: 'Bar'
        ]
      expected = JSON.parse JSON.stringify item
      expected.content[0].text = 'Hello world!'
      expected.content[2].text = 'This is some text'

      f.flattenItem item, (err) ->
        return done err if err
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
      f.flattenItem item, (err) ->
        return done err if err
        chai.expect(item.content.length).to.equal 3
        chai.expect(item.content[0]).to.eql
          id: 'foo'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          text: 'Hello world!'
          metadata:
            title: 'Foo'
        chai.expect(item.content[1]).to.eql
          type: 'text'
          html: '<p>Foobar</p>'
          text: 'Foobar'
        chai.expect(item.content[2]).to.eql orig.content[1]
        done()

  describe 'cleaning a block inside a block', ->
    it 'should produce a clean block', (done) ->
      item =
        content: [
          id: 'foo'
          type: 'h1'
          html: '<h1><p data-grid-id="1d6da340-4dc3-4979-b14a-e676bd6d829b">Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing</p></h1>'
          metadata:
            title: 'Foo'
        ,
          id: 'bar'
          type: 'quote'
          html: '<blockquote><p data-grid-id="099b7305-7631-45cf-9b00-a553baa5da47">A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.</p><p data-grid-id="bcdd91f9-e33e-48ee-b0f8-f85929ef34ba"></p><p data-grid-id="d1b31853-a2d7-4a77-a1f6-2830ec4b13c2"></p></blockquote>'
        ]
      orig = JSON.parse JSON.stringify item
      f.flattenItem item, (err) ->
        return done err if err
        chai.expect(item.content.length).to.equal 2
        chai.expect(item.content[0]).to.eql
          id: 'foo'
          type: 'h1'
          html: '<h1>Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing</h1>'
          text: 'Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing'
          metadata:
            title: 'Foo'
        chai.expect(item.content[1]).to.eql
          id: 'bar'
          type: 'quote'
          html: '<blockquote><p>A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.</p></blockquote>'
          text: 'A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.'
        done()

  describe 'cleaning up a more specific iframe block', ->
    it 'should retain the block type', (done) ->
      item =
        content: [
          id: 'location'
          type: 'location'
          html: "<iframe src=\"https://the-grid.github.io/ed-location/?latitude=19.327691&longitude=-99.82173&zoom=7&address=M%C3%A9xico%2C%20Mexico\"></iframe>"
          metadata:
            geo:
              latitude: 19.327691
              longitude: -99.82173
              zoom: 7
            isBasedOnUrl: "https://the-grid.github.io/ed-location/?latitude=19.327691&longitude=-99.82173&zoom=7&address=M%C3%A9xico%2C%20Mexico"
            address: "México, Mexico"
            starred: true
        ]

      orig = JSON.parse JSON.stringify item
      f.flattenItem item, (err, cleaned) ->
        return done err if err
        chai.expect(cleaned).to.eql orig
        done()

  describe 'cleaning up a full item', ->
    it 'should produce clean blocks', (done) ->
      fs = require 'fs'
      path = require 'path'
      item = JSON.parse fs.readFileSync __dirname+'/fixtures/put.json', 'utf-8'
      orig = JSON.parse JSON.stringify item
      f.flattenItem item, (err) ->
        return done err if err
        types = item.content.map (b) -> b.type
        chai.expect(types).to.eql [
          'image'
          'image'
          'image'
        ]
        done()
