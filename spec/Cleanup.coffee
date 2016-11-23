Flatten = require '../build/flatten-html'
schema = require './utils/schema'
chai = require 'chai'

describe 'Cleanup', ->
  f = null
  before ->
    do schema.before
  beforeEach ->
    f = new Flatten
  after ->
    do schema.after

  describe 'cleaning an already-clean block structure', ->
    it 'should keep things as they are', (done) ->
      item =
        content: [
          id: 'b02291ca-947c-41fc-9a58-acb648806fd5'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          metadata:
            title: 'Foo'
        ,
          id: 'aedd2c5d-bf6d-45a6-87c0-c4ba5feb1931'
          type: 'text'
          html: '<p>This is some text</p>'
          metadata:
            title: 'Bar'
        ,
          id: '31e2a358-8654-456e-8205-430ea8e748ec'
          type: 'hr'
          html: '<hr>'
        ]
      expected = JSON.parse JSON.stringify item
      expected.content[0].text = 'Hello world!'
      expected.content[1].text = 'This is some text'

      f.flattenItem item, (err, flattened) ->
        return done err if err
        chai.expect(flattened).to.eql expected
        schema.validate flattened, 'item', done

  describe 'cleaning a block structure with placeholder', ->
    it 'should keep things as they are', (done) ->
      item =
        content: [
          id: 'ddc9e89a-4b89-4a52-9a87-7e06f9f7f12a'
          type: 'h1'
          html: '<h1>Hello world!</h1>'
          metadata:
            title: 'Foo'
        ,
          id: '7aac2956-dde8-4a6c-8f96-edfd77e96bfd'
          type: 'placeholder'
          html: ''
        ,
          id: '56b38d9d-4b48-4c6c-83de-856ed06ff68e'
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
        schema.validate item, 'item', done

  describe 'cleaning a dirty HTML structure', ->
    it 'should produce clean blocks', (done) ->
      item =
        content: [
          id: 'c7ce12bb-6928-43b7-8640-55a32d612d26'
          type: 'h1'
          html: '<h1 style="color: brown">Hello world!</h1><p><br/></p><p>Foobar</p>'
          metadata:
            title: 'Foo'
        ,
          id: '90e6ec26-457d-4906-82cf-d31078542e11'
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
          id: 'c7ce12bb-6928-43b7-8640-55a32d612d26'
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
        schema.validate item, 'item', done

  describe 'cleaning a block inside a block', ->
    it 'should produce a clean block', (done) ->
      item =
        content: [
          id: 'e53152b1-e6fa-4f9a-9590-2010de528553'
          type: 'h1'
          html: '<h1><p data-grid-id="1d6da340-4dc3-4979-b14a-e676bd6d829b">Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing</p></h1>'
          metadata:
            title: 'Foo'
        ,
          id: '69a4b35a-6856-422b-b298-6db4c5bdb9f0'
          type: 'quote'
          html: '<blockquote><p data-grid-id="099b7305-7631-45cf-9b00-a553baa5da47">A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.</p><p data-grid-id="bcdd91f9-e33e-48ee-b0f8-f85929ef34ba"></p><p data-grid-id="d1b31853-a2d7-4a77-a1f6-2830ec4b13c2"></p></blockquote>'
        ]
      orig = JSON.parse JSON.stringify item
      f.flattenItem item, (err) ->
        return done err if err
        chai.expect(item.content.length).to.equal 2
        chai.expect(item.content[0]).to.eql
          id: 'e53152b1-e6fa-4f9a-9590-2010de528553'
          type: 'h1'
          html: '<h1>Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing</h1>'
          text: 'Welcome to a Digital Solutions agency that specialize in cost effective SEO, SEM, SMM, Branding, Planning, Content, Automation, Programmatic, Web and App Development, Metrics and Purchasing'
          metadata:
            title: 'Foo'
        chai.expect(item.content[1]).to.eql
          id: '69a4b35a-6856-422b-b298-6db4c5bdb9f0'
          type: 'quote'
          html: '<blockquote><p>A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.</p></blockquote>'
          text: 'A designer knows he has achieved perfection not when there is nothing left to add, but when there is nothing left to take away.'
        schema.validate item, 'item', done

  describe 'cleaning up a more specific iframe block', ->
    it 'should retain the block type', (done) ->
      item =
        content: [
          id: 'ca4eee49-0245-40be-a2fb-e82000e3cf31'
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
        schema.validate item, 'item', done

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
        schema.validate item, 'item', done
