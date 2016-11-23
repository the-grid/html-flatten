htmlparser = require 'htmlparser2'
he = require 'he'
uri = require 'urijs'
urlParser = require 'url'
Promise = require 'bluebird'

module.exports = class Flatten
  structuralTags: [
    '?xml'
    '!DOCTYPE'
    'html'
    'head'
    'link'
    'style'
    'title'
    'body'
    'div'
    'font'
    'section'
    'span'
    'header'
    'footer'
    'nav'
    'br'
    'meta'
    's'
    'small'
    'script'
  ]
  blockLevel: [
    'p'
    'h1'
    'h2'
    'h3'
    'h4'
    'h5'
    'h6'
    'h7'
    'div'
    'blockquote'
    'pre'
    'hr'
  ]
  ignoredAttribs: [
    'data-query-source'
    'data-expanded-url'
    'data-grid-id'
  ]
  allowedAttribs: [
    'src'
    'href'
    'title'
    'alt'
    'webkitallowfullscreen'
    'mozallowfullscreen'
    'allowfullscreen'
    'width'
    'height'
    'scrolling'
    'frameborder'
    'autoplay'
    'loop'
    'controls'
    'type'
  ]

  constructor: (options={}) ->
    if options.structuralTags?
      @structuralTags = options.structuralTags
    if options.ignoredAttribs?
      @ignoredAttribs = options.ignoredAttribs
    if options.allowedAttribs?
      @allowedAttribs = options.allowedAttribs

  processPage: (page, callback) ->
    if page.html and not page.items
      @flattenItem page, (err) ->
        return callback err if err
        callback null, page
      return

    unless page.items?.length
      callback null, page
      return

    flattenItem = Promise.promisify @flattenItem.bind @
    Promise.map page.items, (item) ->
      flattenItem item
    .nodeify (err) ->
      return callback err if err
      callback null, page

  flattenItem: (item, callback) ->
    if item.content and not item.html
      # Pre-flattened item, just make sure HTML is sane
      return @cleanUpItem item, callback

    item.html = '' unless item.html
    if item.html and not item.html.match /^[\s]*</
      item.html = "<p>#{item.html}</p>"

    handler = new htmlparser.DefaultHandler (err, dom) =>
      item.content = []
      for tag in dom
        normalized = @normalizeTag tag, item.id
        continue unless normalized
        for block in normalized
          item.content.push block
      delete item.html
      callback null, item
    parser = new htmlparser.Parser handler
    parser.parseComplete item.html

  cleanUpItem: (item, callback) ->
    delete item.starred
    cleanUp = Promise.promisify @cleanUpBlock.bind @
    Promise.map item.content, (block) ->
      cleanUp block, item
    .nodeify (err) ->
      return callback err if err
      callback null, item

  cleanUpBlock: (block, item, callback) ->
    return callback null unless block
    if block.type is 'placeholder'
      block.html = ''
      do callback
      return
    handler = new htmlparser.DefaultHandler (err, dom) =>
      blocks = []
      for tag in dom
        normalized = @normalizeTag tag, item.id
        continue unless normalized
        for b in normalized
          blocks.push b

      blockIdx = item.content.indexOf block
      #return callback() if blockIdx is -1
      unless blocks.length
        # Empty block, remove
        item.content.splice blockIdx, 1
        return callback()
      if blocks.length is 1
        # Block returned only one block

        if blocks[0].type is 'interactive' and block.type in [
          'location'
          'video'
          'audio'
        ]
          # The block was manually classified, keep it in type
          blocks[0].type = block.type

        # Update values
        item.content[blockIdx][k] = v for k, v of blocks[0]
        return callback()

      if block.type is blocks[0].type
        # First result is still the original, update that and add the others
        [first, blocks...] = blocks
        item.content[blockIdx][k] = v for k, v of first
        for b, i in blocks
          item.content.splice blockIdx + 1 + i, 0, b
        return callback()

      [first, blocks...] = blocks
      item.content[blockIdx] = first
      for b, i in blocks
        item.content.splice blockIdx + 1 + i, 0, b
      do callback
    parser = new htmlparser.Parser handler
    parser.parseComplete block.html

  normalizeUrl: (url, base) ->
    return url unless base
    return '' unless url
    parsed = uri url
    return url if parsed.protocol() in ['javascript', 'mailto', 'data', 'blob', 'filesystem', 'file', 'chrome-extension', 'filesystem:chrome-extension']
    try
      abs = parsed.absoluteTo(base).toString()
    catch e
      console.log url, e
      return url
    abs

  normalizeTag: (tag, id) ->
    results = []

    if tag.type is 'text'
      html = @tagToHtml tag, id
      return results unless html.length
      results.push
        type: 'text'
        html: @tagToHtml tag, id
      return results

    if tag.name in @structuralTags
      return results unless tag.children?.length
      for child in tag.children
        continue if child.type is 'text'
        normalized = @normalizeTag child, id
        continue unless normalized
        results = results.concat normalized
      return results

    switch tag.name
      when 'video'
        tag.attribs.src = @normalizeUrl tag.attribs.src, id if tag.attribs.src
        video =
          type: 'video'
          html: @tagToHtml tag, id
        video.video = tag.attribs.src if tag.attribs.src
        video.src = tag.attribs.poster if tag.attribs.poster
        results.push video
      when 'iframe'
        return results unless tag.attribs
        tag.attribs.src = @normalizeUrl tag.attribs.src, id
        type = @classifyIframe tag.attribs.src
        block =
          type: @classifyIframe tag.attribs.src
          html: @tagToHtml tag, id
        block.video = tag.attribs.src if block.type in ['video', 'audio']
        results.push block
      when 'img'
        return results unless tag.attribs
        tag.attribs.src = @normalizeUrl tag.attribs.src, id
        if tag.attribs.src is 'http://en.wikipedia.org/wiki/Special:CentralAutoLogin/start?type=1x1'
          return results
        return results unless tag.attribs.src
        img =
          type: 'image'
          src: tag.attribs.src
          html: @tagToHtml tag, id
        img.title = he.decode(tag.attribs.title) if tag.attribs.title
        img.caption = he.decode(tag.attribs.alt) if tag.attribs.alt
        results.push img
      when 'figure'
        return results unless tag.children?.length
        type = 'image'
        src = undefined
        caption = null
        for child in tag.children
          if child.name in @structuralTags
            normalized = @normalizeTag child, id
            for n in normalized
              if n.type is 'image'
                src = n.src
          if child.name is 'iframe'
            return @normalizeTag child, id
          if child.name is 'code'
            type = 'code'
          if child.name is 'img'
            if child.attribs
              child.attribs.src = @normalizeUrl child.attribs.src, id
              src = child.attribs.src
            type = 'image'
          if child.name is 'figcaption'
            caption = @tagToHtml child, id, false
        img =
          type: type
          src: src
          html: @tagToHtml tag, id, true
        img.caption = he.decode(caption) if caption
        results.push img
      when 'article'
        return results unless tag.children?.length
        caption = null
        title = null
        src = null
        if tag.children.length is 1 and tag.children[0].name is 'img' and tag.children[0].attribs?.src
          results.push
            type: 'image'
            html: @tagToHtml tag.children[0]
            src: @normalizeUrl tag.children[0].attribs.src
          return results
        for child in tag.children
          if child.name is 'h1' and not title
            title = ''
            continue unless child.children
            title += @tagToHtml c for c in child.children
          if child.name is 'p' and not caption
            caption = ''
            continue unless child.children
            caption += @tagToHtml c for c in child.children
          if child.name is 'img' and child.attribs.src and not src
            src = @normalizeUrl child.attribs.src, id
         article =
           type: 'article'
           html: @tagToHtml tag, id
         article.title = he.decode(title) if title
         article.caption = he.decode(caption) if caption
         article.src = src if src
         results.push article
      when 'p', 'em', 'small'
        return unless tag.children?.length
        hasContent = false
        normalized = []
        remove = []
        for child in tag.children
          if child.name is 'video'
            normalized = normalized.concat @normalizeTag child, id
            remove.push child
          else if child.name is 'img'
            normalized = normalized.concat @normalizeTag child, id
            remove.push child
          else if child.name is 'button'
            normalized = normalized.concat @normalizeTag child, id
            remove.push child
          else if child.name is 'a'
            normalizedChild = @normalizeTag child, id
            for n in normalizedChild
              continue unless n.type in ['image', 'video']
              normalized.push n
              remove.push child
          else
            hasContent = true
        # If we only have images or videos inside, then return them
        # as individual items
        for r in remove
          tag.children.splice tag.children.indexOf(r), 1

        # If we have other stuff too, then return them as-is
        html = @tagToHtml tag, id
        unless html in ['<p></p>', '']
          results.push
            type: 'text'
            html: html
            text: @tagToText tag

        if normalized.length
          results.push n for n in normalized
      when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
        normalized =
          type: tag.name
          html: @tagToHtml tag, id
          text: @tagToText tag
        results.push normalized
      when 'pre'
        results.push
          type: 'code'
          html: @tagToHtml tag, id
      when 'ul', 'ol', 'dl'
        results.push
          type: 'list'
          html: @tagToHtml tag, id
      when 'blockquote'
        results.push
          type: 'quote'
          html: @tagToHtml tag, id
          text: @tagToText tag
      when 'table'
        results.push
          type: 'table'
          html: @tagToHtml tag, id
      when 'time'
        results.push
          type: 'time'
          html: @tagToHtml tag, id
      when 'a'
        return results unless tag.children?.length
        if tag.attribs?.href
          tag.attribs.href = @normalizeUrl tag.attribs.href, id
        normalizedChildren = []
        for c in tag.children
          normalizedChildren = normalizedChildren.concat @normalizeTag c, id
        return results unless normalizedChildren.length
        if tag.attribs?.href
          normalizedChildren[0].html = @tagToHtml tag, id
        if tag.attribs?['data-role'] is 'cta'
          normAttributes = @normalizeCtaAttributes(tag.attribs)
          for key, val of normAttributes
            normalizedChildren[0][key] = val
          normalizedChildren[0].url = tag.attribs.href
          normalizedChildren[0].label = @tagToText(tag)
        return normalizedChildren
      when 'button'
        return results unless tag.attribs?['data-role']
        normalized = {}
        normAttributes = @normalizeCtaAttributes(tag.attribs)
        for key, val of normAttributes
          normalized[key] = val
        normalized.html = @tagToHtml tag, id
        normalized.label = @tagToText(tag)
        results.push normalized
        return results
      when 'hr'
        results.push
          type: 'hr'
          html: '<hr>'
      # Tags that we ignore entirely
      when 'form', 'input', 'textarea', 'aside', 'meta', 'script', 'br'
        return results
      else
        results.push
          type: 'unknown'
          html: @tagToHtml tag, id
    results

  normalizeCtaAttributes: (attributes) ->
    normalized = {}
    for key, val of attributes
      continue unless key.indexOf('data-') is 0
      attrib = key.substr 5
      attrib = 'verb' if attrib is 'type'
      attrib = 'type' if attrib is 'role'
      normalized[attrib] = val
    normalized

  isAttributeAllowed: (attribute) ->
    if attribute.substr(0, 5) is 'data-'
      return false if attribute in @ignoredAttribs
      return true
    return false unless attribute in @allowedAttribs
    true

  classifyIframe: (url) ->
    parsed = urlParser.parse url, true, true
    return 'interactive' unless parsed.hostname

    if parsed.hostname is 'cdn.embedly.com' and parsed.query.src
      return @classifyIframe parsed.query.src

    return 'video' if parsed.hostname.indexOf('youtube.com') isnt -1
    return 'video' if parsed.hostname.indexOf('vimeo.com') isnt -1
    return 'video' if parsed.hostname.indexOf('vine.co') isnt -1
    return 'video' if parsed.hostname.indexOf('wistia.com') isnt -1
    return 'video' if parsed.hostname.indexOf('wistia.net') isnt -1
    return 'video' if parsed.hostname.indexOf('imgur.com') isnt -1
    return 'video' if parsed.hostname.indexOf('cdninstagram.com') isnt -1
    return 'video' if parsed.hostname.indexOf('livestream.com') isnt -1
    return 'video' if parsed.hostname.indexOf('giphy.com') isnt -1
    return 'audio' if parsed.hostname.indexOf('soundcloud.com') isnt -1
    return 'audio' if parsed.hostname.indexOf('bandcamp.com') isnt -1
    return 'location' if parsed.hostname.indexOf('maps.google.') isnt -1
    return 'location' if parsed.hostname.indexOf('www.google.com') isnt -1 and parsed.pathname.indexOf('/maps') isnt -1

    return 'interactive'

  tagToHtml: (tag, id, keepCaption = false, allowBlock = true) ->
    if tag.type is 'text'
      return '' unless tag.data
      return '' if tag.data.trim() is ''
      return '' if tag.data is '&nbsp;'
      return tag.data
    allowSubBlock = tag.name in ['video', 'article', 'figure', 'blockquote']

    if tag.name in @blockLevel and not tag.children?.length
      return ''

    if tag.name in @structuralTags or (tag.name in ['figcaption'] and not keepCaption)
      return '' unless tag.children?.length
      content = ''
      for child in tag.children
        content += @tagToHtml child, id, keepCaption, allowSubBlock
      return content
    if tag.name in @blockLevel and not allowBlock
      content = ''
      for child in tag.children
        content += @tagToHtml child, id, keepCaption, allowSubBlock
      return content

    attributes = ''
    if tag.attribs
      for attrib, val of tag.attribs
        continue unless @isAttributeAllowed attrib
        if tag.name is 'a' and attrib is 'href'
          val = @normalizeUrl val, id
        if tag.name is 'img' and attrib is 'src'
          val = @normalizeUrl val, id
        if val or attrib in ['alt', 'title']
          attributes += " #{attrib}=\"#{val}\""
        else
          attributes += " #{attrib}"
    html = "<#{tag.name}#{attributes}>"
    if tag.children
      content = ''
      for child, index in tag.children
        # Allow internal line breaks
        if child.name is 'br' and content isnt ''
          nextSibling = tag.children[index+1]
          if nextSibling and nextSibling.name isnt 'br'
            content += '<br>'
            continue
        content += @tagToHtml child, id, keepCaption, allowSubBlock
      html += content
    if tag.name isnt 'img' and tag.name isnt 'source'
      html += "</#{tag.name}>"
    return html

  tagToText: (tag) ->
    text = ''
    if tag.type is 'text'
      tag.data = '' unless tag.data
      tag.data = tag.data.replace '&nbsp;', ' '
      return he.decode tag.data
    if tag.name is 'br'
      return ' '
    if tag.children?.length
      for child in tag.children
        text += @tagToText child
    text
