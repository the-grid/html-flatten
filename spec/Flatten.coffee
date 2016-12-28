Flatten = require '../build/flatten-html'
chai = require 'chai'
schema = require './utils/schema'

describe 'Flatten', ->
  f = null
  before ->
    do schema.before
  beforeEach ->
    f = new Flatten()
  after ->
    do schema.after

  describe 'flattening HTML structures inside item', ->
    it 'should be able to find a video and a paragraph', (done) ->
      sent =
        id: 'ddc572c9-7343-4dbd-a2f9-b0e347353612'
        html: """
        <script>alert('foo');</script>
        <p>Hello world, <b>this</b> is <span>some</span> text</p>
        <video src="http://foo.bar"></video>
        <video autoplay="true" loop="true" controls="false">
          <source type="video/mp4" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.mp4"/>
          <source type="video/webm" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.webm"/>
        </video>
        <hr>
        <p class='pagination-centered'><img class='img-polaroid' src='http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png' /><img /></p>
        <img alt="Some pretty impressive climbing right there -&gt;&quot;&commat;Arcteryx&colon; &commat;Gilwad climbing Helmcken Falls http&colon;&sol;&sol;ow&period;ly&sol;JwnFL" src="https://pbs.twimg.com/media/B-iy-ETCYAAGEcU.jpg:large">
        <p><button data-uuid="71bfc2e0-4a96-11e4-916c-0800200c9a66" data-role="cta" data-verb="purchase" data-price="96">Buy now</button></p>
        """

      expected =
        id: 'ddc572c9-7343-4dbd-a2f9-b0e347353612'
        content: [
          type: 'text'
          html: '<p>Hello world, <b>this</b> is some text</p>'
          text: 'Hello world, this is some text'
        ,
          type: 'video'
          video: 'http://foo.bar/'
          html: '<video src="http://foo.bar/"></video>'
        ,
          type: 'video'
          html: '<video autoplay="true" loop="true" controls="false"><source type="video/mp4" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.mp4"><source type="video/webm" src="//s3-us-west-2.amazonaws.com/cdn.thegrid.io/posts/cta-ui-bg.webm"></video>'
        ,
          type: 'hr'
          html: '<hr>'
        ,
          type: 'image'
          src: 'http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png'
          html: '<img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">'
        ,
          type: 'image'
          src: 'https://pbs.twimg.com/media/B-iy-ETCYAAGEcU.jpg:large'
          caption: 'Some pretty impressive climbing right there ->"@Arcteryx: @Gilwad climbing Helmcken Falls http://ow.ly/JwnFL'
          html: '<img alt="Some pretty impressive climbing right there -&gt;&quot;&commat;Arcteryx&colon; &commat;Gilwad climbing Helmcken Falls http&colon;&sol;&sol;ow&period;ly&sol;JwnFL" src="https://pbs.twimg.com/media/B-iy-ETCYAAGEcU.jpg:large">'
        ,
          type: 'cta'
          uuid: '71bfc2e0-4a96-11e4-916c-0800200c9a66'
          verb: 'purchase'
          price: '96'
          html: '<button data-uuid="71bfc2e0-4a96-11e4-916c-0800200c9a66" data-role="cta" data-verb="purchase" data-price="96">Buy now</button>'
          label: 'Buy now'
        ]

      f.flattenItem sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'item', done

  describe 'flattening HTML structures', ->
    it 'should be able to find a video and an image inside figures', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <figure><iframe frameborder="0" src="http://www.youtube.com/embed/YzC7MfCtkzo"></iframe></figure>
          <figure><img alt=\"An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.\" src=\"http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png\">An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.</figure>
          <figure><div><img src=\"http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1\"></div>\n<figcaption><small>Tom Turley / <a href=\"http://www.gettyimages.com/\">Getty Images</a></small></figcaption></figure>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: 'http://www.youtube.com/embed/YzC7MfCtkzo'
            html: '<iframe frameborder="0" src="http://www.youtube.com/embed/YzC7MfCtkzo"></iframe>'
          ,
            type: 'image'
            src: 'http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png'
            html: '<figure><img alt=\"An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.\" src=\"http://cnet3.cbsistatic.com/hub/i/r/2013/09/10/92df7aec-6ddf-11e3-913e-14feb5ca9861/resize/620x/929f354f66ca3b99ab045f6f15a6693a/noflo-jekyll.png\">An illustration of NoFlo used to create a flow-based version of the Jekyll tool for converting text into content suitable for Web publishing.</figure>'
          ,
            type: 'image'
            src: 'http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1'
            caption: 'Tom Turley / <a href="http://www.gettyimages.com/">Getty Images</a>'
            html: "<figure><img src=\"http://timenewsfeed.files.wordpress.com/2012/02/slanglol.jpg?w=480&amp;h=320&amp;crop=1\"><figcaption>Tom Turley / <a href=\"http://www.gettyimages.com/\">Getty Images</a></figcaption></figure>"
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to find Embed.ly videos and audios', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <iframe class=\"embedly-embed\" src=\"//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube\" width=\"500\" height=\"281\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>
          <iframe class=\"embedly-embed\" src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud\" width=\"500\" height=\"500\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>
          <iframe class="embedly-embed" src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fmtc.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4%3FversionId%3DMfbYrYHKtQn5CarqDt9SoZHnUeQRVt7Z&src_secure=1&url=https%3A%2F%2Fvine.co%2Fv%2FOUnPWge7Jnj&image=https%3A%2F%2Fv.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4.jpg%3FversionId%3DedU_LrAtIFsGvZj.Fgi0Si1bem68tBlk&key=internal&type=video%2Fmp4&schema=vine" width="500" height="500" scrolling="no" frameborder="0" allowfullscreen></iframe>
          <iframe class="embedly-embed" src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fmaps.google.de%2Fmaps%3Fsll%3D52.48535%2C13.4261%26sspn%3D0.0050177%2C0.0109864%26q%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26dg%3Dntvb%26output%3Dembed&url=https%3A%2F%2Fmaps.google.de%2Fmaps%3Fsll%3D52.48535%2C13.4261%26sspn%3D0.0050177%2C0.0109864%26q%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26output%3Dclassic%26dg%3Dntvb&image=http%3A%2F%2Fmaps-api-ssl.google.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26zoom%3D15%26size%3D250x250%26sensor%3Dfalse&key=internal&type=text%2Fhtml&schema=google" width="500" height="412" scrolling="no" frameborder="0" allowfullscreen></iframe>
          <iframe src=\"https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.google.com%2Fmaps%2Fembed%2Fv1%2Fview%3Fmaptype%3Dsatellite%26center%3D35.0349449%252C-83.9676685%26key%3DAIzaSyBctFF2JCjitURssT91Am-_ZWMzRaYBm4Q%26zoom%3D15&url=https%3A%2F%2Fwww.google.com%2Fmaps%2F%4035.0349449%2C-83.9676685%2C585m%2Fdata%3D%213m1%211e3%3Fdg%3Ddbrw%26newdg%3D1&image=http%3A%2F%2Fmaps-api-ssl.google.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3D35.0349449%2C-83.9676685%26zoom%3D15%26size%3D250x250%26sensor%3Dfalse&key=b7d04c9b404c499eba89ee7072e1c4f7&type=text%2Fhtml&schema=google\" width=\"600\" height=\"450\" scrolling=\"no\" frameborder=\"0\" allowfullscreen=\"allowfullscreen\"></iframe>
          <iframe class="embedly-embed" src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Ffast.wistia.net%2Fembed%2Fiframe%2Fmgdmzrzrm4%3Ftwitter%3Dtrue&src_secure=1&url=http%3A%2F%2Fdave.wistia.com%2Fmedias%2Fmgdmzrzrm4%3FembedType%3Dapi%26videoWidth%3D640&image=https%3A%2F%2Fembed-ssl.wistia.com%2Fdeliveries%2F1700d47fbfd310773b221d52e3a6d8c1cb91050a.jpg%3Fimage_crop_resized%3D640x360&key=internal&type=text%2Fhtml&schema=wistia" width="500" height="281" scrolling="no" frameborder="0" allowfullscreen></iframe>
          <iframe src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fi.imgur.com%2FaK4RY7D.mp4&src_secure=1&url=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gifv&image=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gif%3Fnoredirect&key=b7d04c9b404c499eba89ee7072e1c4f7&type=video%2Fmp4&schema=imgur" width="718" height="404" scrolling="no" frameborder="0" allowfullscreen></iframe>
          <iframe class="embedly-embed" src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fgiphy.com%2Fembed%2FsRm0Q3hirbSX6%2Ftwitter%2Fiframe&src_secure=1&url=http%3A%2F%2Fgiphy.com%2Fgifs%2FsRm0Q3hirbSX6&image=https%3A%2F%2Fmedia.giphy.com%2Fmedia%2FsRm0Q3hirbSX6%2Fgiphy.gif&key=internal&type=text%2Fhtml&schema=giphy" width="435" height="181" scrolling="no" frameborder="0" allowfullscreen></iframe>
          <iframe class="embedly-embed" src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2Fvideoseries%3Flist%3DPLoh_dGQ3aUhvr6c5hASTc5wFkjQ3COFXi&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dt7Xr3AsBEK4&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2Ft7Xr3AsBEK4%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube" width="500" height="281" scrolling="no" frameborder="0" allowfullscreen></iframe>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube'
            html: '<iframe src=\"//cdn.embedly.com/widgets/media.html?src=http%3A%2F%2Fwww.youtube.com%2Fembed%2F8Dos61_6sss%3Ffeature%3Doembed&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D8Dos61_6sss&image=http%3A%2F%2Fi.ytimg.com%2Fvi%2F8Dos61_6sss%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube\" width=\"500\" height=\"281\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>'
          ,
            type: 'audio'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud'
            html: '<iframe src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fw.soundcloud.com%2Fplayer%2F%3Fvisual%3Dtrue%26url%3Dhttp%253A%252F%252Fapi.soundcloud.com%252Ftracks%252F153760638%26show_artwork%3Dtrue&url=http%3A%2F%2Fsoundcloud.com%2Fsupersquaremusic%2Fanywhere-everywhere-super-square-original&image=http%3A%2F%2Fi1.sndcdn.com%2Fartworks-000082002645-fhibur-t500x500.jpg%3Fe76cf77&key=internal&type=text%2Fhtml&schema=soundcloud\" width=\"500\" height=\"500\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fmtc.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4%3FversionId%3DMfbYrYHKtQn5CarqDt9SoZHnUeQRVt7Z&src_secure=1&url=https%3A%2F%2Fvine.co%2Fv%2FOUnPWge7Jnj&image=https%3A%2F%2Fv.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4.jpg%3FversionId%3DedU_LrAtIFsGvZj.Fgi0Si1bem68tBlk&key=internal&type=video%2Fmp4&schema=vine'
            html: '<iframe src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fmtc.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4%3FversionId%3DMfbYrYHKtQn5CarqDt9SoZHnUeQRVt7Z&src_secure=1&url=https%3A%2F%2Fvine.co%2Fv%2FOUnPWge7Jnj&image=https%3A%2F%2Fv.cdn.vine.co%2Fr%2Fvideos%2FB5B06468B91176403722801139712_342c9a1c624.1.5.15775156368984795444.mp4.jpg%3FversionId%3DedU_LrAtIFsGvZj.Fgi0Si1bem68tBlk&key=internal&type=video%2Fmp4&schema=vine" width="500" height="500" scrolling="no" frameborder="0" allowfullscreen></iframe>'
          ,
            type: 'location'
            html: '<iframe src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fmaps.google.de%2Fmaps%3Fsll%3D52.48535%2C13.4261%26sspn%3D0.0050177%2C0.0109864%26q%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26dg%3Dntvb%26output%3Dembed&url=https%3A%2F%2Fmaps.google.de%2Fmaps%3Fsll%3D52.48535%2C13.4261%26sspn%3D0.0050177%2C0.0109864%26q%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26output%3Dclassic%26dg%3Dntvb&image=http%3A%2F%2Fmaps-api-ssl.google.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3DKarl-Marx-Stra%25C3%259Fe%2B12%2C%2B12043%2BBerlin%26zoom%3D15%26size%3D250x250%26sensor%3Dfalse&key=internal&type=text%2Fhtml&schema=google" width="500" height="412" scrolling="no" frameborder="0" allowfullscreen></iframe>'
          ,
            type: 'location'
            html: '<iframe src=\"https://cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.google.com%2Fmaps%2Fembed%2Fv1%2Fview%3Fmaptype%3Dsatellite%26center%3D35.0349449%252C-83.9676685%26key%3DAIzaSyBctFF2JCjitURssT91Am-_ZWMzRaYBm4Q%26zoom%3D15&url=https%3A%2F%2Fwww.google.com%2Fmaps%2F%4035.0349449%2C-83.9676685%2C585m%2Fdata%3D%213m1%211e3%3Fdg%3Ddbrw%26newdg%3D1&image=http%3A%2F%2Fmaps-api-ssl.google.com%2Fmaps%2Fapi%2Fstaticmap%3Fcenter%3D35.0349449%2C-83.9676685%26zoom%3D15%26size%3D250x250%26sensor%3Dfalse&key=b7d04c9b404c499eba89ee7072e1c4f7&type=text%2Fhtml&schema=google\" width=\"600\" height=\"450\" scrolling=\"no\" frameborder=\"0\" allowfullscreen=\"allowfullscreen\"></iframe>'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Ffast.wistia.net%2Fembed%2Fiframe%2Fmgdmzrzrm4%3Ftwitter%3Dtrue&src_secure=1&url=http%3A%2F%2Fdave.wistia.com%2Fmedias%2Fmgdmzrzrm4%3FembedType%3Dapi%26videoWidth%3D640&image=https%3A%2F%2Fembed-ssl.wistia.com%2Fdeliveries%2F1700d47fbfd310773b221d52e3a6d8c1cb91050a.jpg%3Fimage_crop_resized%3D640x360&key=internal&type=text%2Fhtml&schema=wistia'
            html: '<iframe src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Ffast.wistia.net%2Fembed%2Fiframe%2Fmgdmzrzrm4%3Ftwitter%3Dtrue&src_secure=1&url=http%3A%2F%2Fdave.wistia.com%2Fmedias%2Fmgdmzrzrm4%3FembedType%3Dapi%26videoWidth%3D640&image=https%3A%2F%2Fembed-ssl.wistia.com%2Fdeliveries%2F1700d47fbfd310773b221d52e3a6d8c1cb91050a.jpg%3Fimage_crop_resized%3D640x360&key=internal&type=text%2Fhtml&schema=wistia" width="500" height="281" scrolling="no" frameborder="0" allowfullscreen></iframe>'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fi.imgur.com%2FaK4RY7D.mp4&src_secure=1&url=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gifv&image=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gif%3Fnoredirect&key=b7d04c9b404c499eba89ee7072e1c4f7&type=video%2Fmp4&schema=imgur'
            html: '<iframe src="//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fi.imgur.com%2FaK4RY7D.mp4&src_secure=1&url=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gifv&image=http%3A%2F%2Fi.imgur.com%2FaK4RY7D.gif%3Fnoredirect&key=b7d04c9b404c499eba89ee7072e1c4f7&type=video%2Fmp4&schema=imgur" width="718" height="404" scrolling="no" frameborder="0" allowfullscreen></iframe>'
          ,
            type: 'video'
            video: '//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fgiphy.com%2Fembed%2FsRm0Q3hirbSX6%2Ftwitter%2Fiframe&src_secure=1&url=http%3A%2F%2Fgiphy.com%2Fgifs%2FsRm0Q3hirbSX6&image=https%3A%2F%2Fmedia.giphy.com%2Fmedia%2FsRm0Q3hirbSX6%2Fgiphy.gif&key=internal&type=text%2Fhtml&schema=giphy'
            html: "<iframe src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fgiphy.com%2Fembed%2FsRm0Q3hirbSX6%2Ftwitter%2Fiframe&src_secure=1&url=http%3A%2F%2Fgiphy.com%2Fgifs%2FsRm0Q3hirbSX6&image=https%3A%2F%2Fmedia.giphy.com%2Fmedia%2FsRm0Q3hirbSX6%2Fgiphy.gif&key=internal&type=text%2Fhtml&schema=giphy\" width=\"435\" height=\"181\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>"
          ,
            type: 'video'
            video: "//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2Fvideoseries%3Flist%3DPLoh_dGQ3aUhvr6c5hASTc5wFkjQ3COFXi&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dt7Xr3AsBEK4&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2Ft7Xr3AsBEK4%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube"
            html: "<iframe src=\"//cdn.embedly.com/widgets/media.html?src=https%3A%2F%2Fwww.youtube.com%2Fembed%2Fvideoseries%3Flist%3DPLoh_dGQ3aUhvr6c5hASTc5wFkjQ3COFXi&url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3Dt7Xr3AsBEK4&image=https%3A%2F%2Fi.ytimg.com%2Fvi%2Ft7Xr3AsBEK4%2Fhqdefault.jpg&key=internal&type=text%2Fhtml&schema=youtube\" width=\"500\" height=\"281\" scrolling=\"no\" frameborder=\"0\" allowfullscreen></iframe>"
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to find images inside paragraphs', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <p>Another exciting new product is <a href="http://noflojs.org/">NoFlo,</a> a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.<a href="http://noflojs.org/"><img src="http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg" alt=""></a></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'text'
            html: '<p>Another exciting new product is <a href="http://noflojs.org/">NoFlo,</a> a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.</p>'
            text: 'Another exciting new product is NoFlo, a flow-based Javascript programming tool. Developed as the result of a successful Kickstarter campaign (disclosure: I was a backer), it highlights both the dissatisfaction with the currently available tools, and the untapped potential for flow-based programming tools, that could be more easily understood by non-programmers. NoFlo builds upon Node.js to deliver functional apps to the browser. Native output to Android and iOS is in the works.'
          ,
            type: 'image'
            src: 'http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg'
            html: '<a href="http://noflojs.org/"><img src="http://netdna.webdesignerdepot.com/uploads/2014/07/0091.jpg" alt=""></a>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to normalize video and image URLs', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://bergie.iki.fi/'
          html: """
          <p>Hello world, <b>this</b> is some text</p>
          <video src="/files/foo.mp4"></video>
          <p class='pagination-centered'><img class='img-polaroid' src='../../files/image.gif' /><img /></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://bergie.iki.fi/'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: 'http://bergie.iki.fi/files/foo.mp4'
            html: '<video src="http://bergie.iki.fi/files/foo.mp4"></video>'
          ,
            type: 'image'
            src: 'http://bergie.iki.fi/files/image.gif'
            html: '<img src="http://bergie.iki.fi/files/image.gif">'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to flatten a paragraph with only an image to an image', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <p><a href="http://foo.bar"><img src="http://foo.bar" alt="An image" title="My cool photo" data-foo="bar"></a></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'image'
            src: 'http://foo.bar/'
            title: 'My cool photo'
            caption: 'An image'
            html: '<a href="http://foo.bar/"><img src="http://foo.bar/" alt="An image" title="My cool photo" data-foo="bar"></a>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should decode entities in attributes', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <img src="http://foo.bar/j.jpg" alt="An image &amp; &lt;stuff&gt;" title="&yuml;o" data-foo="bar">
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            src: 'http://foo.bar/j.jpg'
            type: 'image'
            title: 'ÿo'
            caption: 'An image & <stuff>'
            html: '<img src="http://foo.bar/j.jpg" alt="An image &amp; &lt;stuff&gt;" title="&yuml;o" data-foo="bar">'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to flatten headlines and paragraphs', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <h1>Hello World</h1>
          <p class="intro">Some text</p>
          <h2 id="foo">Foo bar</h2>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'h1'
            html: '<h1>Hello World</h1>'
            text: 'Hello World'
          ,
            type: 'text'
            html: '<p>Some text</p>'
            text: 'Some text'
          ,
            type: 'h2'
            html: '<h2>Foo bar</h2>'
            text: 'Foo bar'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to flatten lists', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          """
        ]
      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to flatten things wrapped in divs', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <div>
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          </div>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to flatten things wrapped multiple levels of structural tags', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <div>
          <section>
          <span>
          <ul>
            <li>Hello world<ul>
              <li>Foo</li>
            </ul></li>
            <li>Foo bar</li>
          </ul>
          </span>
          </section>
          </div>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'list'
            html: '<ul><li>Hello world<ul><li>Foo</li></ul></li><li>Foo bar</li></ul>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to discard useless content', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <p><span style=\"font-size: x-large;\"><br></br></span></p>
          <p>&nbsp;</p>
          <p><span style=\"font-size: large;\">Afterwards, we'll be running a dojo. No prior experience with FP is needed for this part; we'll all be coming from different levels. Our goals here are to equip you with a more of an understanding of functional programming and it's real-world applications and to learn from each other. More than all that: to have some fun with FP!</span></p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Afterwards, we\'ll be running a dojo. No prior experience with FP is needed for this part; we\'ll all be coming from different levels. Our goals here are to equip you with a more of an understanding of functional programming and it\'s real-world applications and to learn from each other. More than all that: to have some fun with FP!</p>'
            text: 'Afterwards, we\'ll be running a dojo. No prior experience with FP is needed for this part; we\'ll all be coming from different levels. Our goals here are to equip you with a more of an understanding of functional programming and it\'s real-world applications and to learn from each other. More than all that: to have some fun with FP!'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should keep p nested in blockquote', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <blockquote><p data-grid-id="0123">block quote</p></blockquote>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'quote'
            html: """
            <blockquote><p>block quote</p></blockquote>
            """
            text: 'block quote'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should not strip br from p', (done) ->

      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <blockquote><p>one<br>two</p></blockquote>
          <p>three<br />four</p>
          <p><br></p>
          <ul><li>br at end<br></li></ul>
          <p>multiple<br><br>breaks</p>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
              type: 'quote'
              html: "<blockquote><p>one<br>two</p></blockquote>"
              text: 'one two'
            ,
              type: 'text'
              html: "<p>three<br>four</p>"
              text: 'three four'
            ,
              type: 'list'
              html: "<ul><li>br at end</li></ul>"
            ,
              type: 'text'
              html: "<p>multiple<br>breaks</p>"
              text: 'multiple  breaks'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should not strip \\n from pre', (done) ->

      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: "<pre><code>one\ntwo</code></pre>"
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [{
            type: 'code'
            html: "<pre><code>one\ntwo</code></pre>"
          }]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

    it 'should be able to detect iframe videos', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: """
          <iframe src="//player.vimeo.com/video/72238422?color=ffffff" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
          <iframe src="//foo.bar.com/foo"></iframe>
          """
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'video'
            video: '//player.vimeo.com/video/72238422?color=ffffff'
            html: '<iframe src="//player.vimeo.com/video/72238422?color=ffffff" width="500" height="281" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>'
          ,
            type: 'interactive'
            html: '<iframe src="//foo.bar.com/foo"></iframe>'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening a partially pre-flattened page', ->
    it 'should keep the already flattened parts as they were', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
          ,
            type: 'video'
            video: 'http://foo.bar/'
            html: '<video src="http://foo.bar/"></video>'
          ,
            type: 'image'
            src: 'http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png'
            html: '<img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">'
          ]
        ,
          id: 'ae453322-62b5-40b2-bbe9-b3e7e240d24f'
          html: """
          <p>Hello there</p>
          """
        ]
      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'text'
            html: '<p>Hello world, <b>this</b> is some text</p>'
            text: 'Hello world, this is some text'
          ,
            type: 'video'
            video: 'http://foo.bar/'
            html: '<video src="http://foo.bar/"></video>'
          ,
            type: 'image'
            src: 'http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png'
            html: '<img src="http://blog.interfacevision.com/assets/img/posts/example_visual_language_minecraft_01.png">'
          ]
        ,
          id: 'ae453322-62b5-40b2-bbe9-b3e7e240d24f'
          content: [
            type: 'text'
            html: '<p>Hello there</p>'
            text: 'Hello there'
          ]
        ]

      f.processPage sent, (err, data) ->
        chai.expect(data).to.deep.eql expected
        return done err if err
        schema.validate data, 'page', done

  describe 'flattening Twitter-style HTML structures', ->
    it 'should be able to find a video and a paragraph', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'https://twitter.com/RonConway/status/472107533788672000'
          html: "Help <a href=\"/BUILDNational\" class=\"twitter-atreply pretty-link\" dir=\"ltr\"><s>@</s><b>BUILDnational</b></a> win $500,000 in the <a href=\"/hashtag/GoogleImpactChallenge?src=hash\" data-query-source=\"hashtag_click\" class=\"twitter-hashtag pretty-link js-nav\" dir=\"ltr\"><s>#</s><b>GoogleImpactChallenge</b></a>! VOTE here: <a href=\"http://t.co/7AzWeaex0D\" rel=\"nofollow\" dir=\"ltr\" data-expanded-url=\"http://bit.ly/1h0KqKN\" class=\"twitter-timeline-link\" target=\"_blank\" title=\"http://bit.ly/1h0KqKN\"><span class=\"tco-ellipsis\"></span><span class=\"invisible\">http://</span><span class=\"js-display-url\">bit.ly/1h0KqKN</span><span class=\"invisible\"></span><span class=\"tco-ellipsis\"><span class=\"invisible\">&nbsp;</span></span></a> <a href=\"/hashtag/BUILDgreaterimpact?src=hash\" data-query-source=\"hashtag_click\" class=\"twitter-hashtag pretty-link js-nav\" dir=\"ltr\"><s>#</s><b>BUILDgreaterimpact</b></a> <a href=\"/hashtag/togetherweBUILD?src=hash\" data-query-source=\"hashtag_click\" class=\"twitter-hashtag pretty-link js-nav\" dir=\"ltr\"><s>#</s><b>togetherweBUILD</b></a>"
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'https://twitter.com/RonConway/status/472107533788672000'
          content: [
            type: 'text'
            html: "<p>Help <a href=\"https://twitter.com/BUILDNational\">@<b>BUILDnational</b></a> win $500,000 in the <a href=\"https://twitter.com/hashtag/GoogleImpactChallenge?src=hash\">#<b>GoogleImpactChallenge</b></a>! VOTE here: <a href=\"http://t.co/7AzWeaex0D\" title=\"http://bit.ly/1h0KqKN\">http://bit.ly/1h0KqKN</a><a href=\"https://twitter.com/hashtag/BUILDgreaterimpact?src=hash\">#<b>BUILDgreaterimpact</b></a><a href=\"https://twitter.com/hashtag/togetherweBUILD?src=hash\">#<b>togetherweBUILD</b></a></p>"
            text: 'Help @BUILDnational win $500,000 in the #GoogleImpactChallenge! VOTE here: http://bit.ly/1h0KqKN  #BUILDgreaterimpact #togetherweBUILD'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data.items[0].content[0].text).to.equal expected.items[0].content[0].text
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening content with Article elements', ->
    it 'should produce an article block', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://html5doctor.com/the-article-element/'
          html: "<article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article><article><h1>Red Delicious</h1><img src=\"http://www.theproducemom.com/wp-content/uploads/2012/01/red_delicious_jpg.jpg\"><p>These bright red apples are the most common found in many supermarkets...</p></article><article><img src=\"https://s3-us-west-2.amazonaws.com/the-grid-img/p/904a32ea9f56b9e7bf1b500e5e2e2217a090b225.jpg\"></article>"
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://html5doctor.com/the-article-element/'
          content: [
            type: 'article'
            html: "<article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article>"
            title: 'Apple'
            caption: 'The <b>apple</b> is the pomaceous fruit of the apple tree...'
          ,
            type: 'article'
            html: "<article><h1>Red Delicious</h1><img src=\"http://www.theproducemom.com/wp-content/uploads/2012/01/red_delicious_jpg.jpg\"><p>These bright red apples are the most common found in many supermarkets...</p></article>"
            title: 'Red Delicious'
            caption: 'These bright red apples are the most common found in many supermarkets...'
            src: 'http://www.theproducemom.com/wp-content/uploads/2012/01/red_delicious_jpg.jpg'
          ,
            type: 'image'
            html: "<img src=\"https://s3-us-west-2.amazonaws.com/the-grid-img/p/904a32ea9f56b9e7bf1b500e5e2e2217a090b225.jpg\">"
            src: 'https://s3-us-west-2.amazonaws.com/the-grid-img/p/904a32ea9f56b9e7bf1b500e5e2e2217a090b225.jpg'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening content with query-stringed image URL', ->
    it 'should produce an article block', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://html5doctor.com/the-article-element/'
          html: "<article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article><article><h1>Red Delicious</h1><img src=\"https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/5764f83177c27abe632d7dce03e55e6d/noop.jpeg?input=https%3A%2F%2Fcdn-images-1.medium.com%2Fmax%2F1200%2F1*f7gpfegwe5jhpYs_1R_neA.jpeg\"><p>These bright red apples are the most common found in many supermarkets...</p></article>"
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          metadata:
            isBasedOnUrl: 'http://html5doctor.com/the-article-element/'
          content: [
            type: 'article'
            html: "<article><h1>Apple</h1><p>The <b>apple</b> is the pomaceous fruit of the apple tree...</p></article>"
            title: 'Apple'
            caption: 'The <b>apple</b> is the pomaceous fruit of the apple tree...'
          ,
            type: 'article'
            html: "<article><h1>Red Delicious</h1><img src=\"https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/5764f83177c27abe632d7dce03e55e6d/noop.jpeg?input=https%3A%2F%2Fcdn-images-1.medium.com%2Fmax%2F1200%2F1*f7gpfegwe5jhpYs_1R_neA.jpeg\"><p>These bright red apples are the most common found in many supermarkets...</p></article>"
            title: 'Red Delicious'
            caption: 'These bright red apples are the most common found in many supermarkets...'
            src: 'https://imgflo.herokuapp.com/graph/vahj1ThiexotieMo/5764f83177c27abe632d7dce03e55e6d/noop.jpeg?input=https%3A%2F%2Fcdn-images-1.medium.com%2Fmax%2F1200%2F1*f7gpfegwe5jhpYs_1R_neA.jpeg'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening content from Medium hosted image', ->
    it 'should produce an article block', (done) ->
      sent =
        path: 'medium.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html: "<figure><img src='https://cdn-images-1.medium.com/max/1200/1*f7gpfegwe5jhpYs_1R_neA.jpeg'></figure>"
        ]

      expected =
        path: 'medium.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'image'
            src: 'https://cdn-images-1.medium.com/max/1200/1*f7gpfegwe5jhpYs_1R_neA.jpeg'
            html: "<figure><img src=\"https://cdn-images-1.medium.com/max/1200/1*f7gpfegwe5jhpYs_1R_neA.jpeg\"></figure>"
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening a link with cta role', ->
    it 'should produce a cta block', (done) ->
      sent =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          html:
            '<a href="https://link.com/" data-role="cta">Call to action!</a>' +
            '<a href="https://paypal.com/button" data-role="cta" data-cta="7edd2510-363d-4c24-8dad-aa648ffc628f" data-type="verrb" data-price="555">buy it?</a>' +
            '<button data-role="cta" data-cta="700c7d7e-737f-4b05-bc8c-cb42700bc0fb" data-type="purchase" data-price="777" data-item="04699d63-c919-4410-9a54-9803dc8e2c25">buy now</button>'
        ]

      expected =
        path: 'foo/bar.html'
        site: 'the-domains/example.net'
        config: {}
        items: [
          id: '6010f3ac-63f2-4407-a65d-9d6b7e9a40f2'
          content: [
            type: 'cta'
            html: '<a href="https://link.com/" data-role="cta">Call to action!</a>'
            url: "https://link.com/"
            label: 'Call to action!'
          ,
            type: 'cta'
            html: '<a href="https://paypal.com/button" data-role="cta" data-cta="7edd2510-363d-4c24-8dad-aa648ffc628f" data-type="verrb" data-price="555">buy it?</a>'
            url: "https://paypal.com/button"
            label: 'buy it?'
            cta: '7edd2510-363d-4c24-8dad-aa648ffc628f'
            verb: 'verrb'
            price: '555'
          ,
            type: 'cta'
            html: '<button data-role="cta" data-cta="700c7d7e-737f-4b05-bc8c-cb42700bc0fb" data-type="purchase" data-price="777" data-item="04699d63-c919-4410-9a54-9803dc8e2c25">buy now</button>'
            price: '777'
            item: '04699d63-c919-4410-9a54-9803dc8e2c25'
            cta: '700c7d7e-737f-4b05-bc8c-cb42700bc0fb'
            verb: 'purchase'
            label: 'buy now'
          ]
        ]

      f.processPage sent, (err, data) ->
        return done err if err
        chai.expect(data).to.deep.eql expected
        schema.validate data, 'page', done

  describe 'flattening a full XHTML file', ->
    # return if window?
    it 'should produce flattened contents', (done) ->
      fs = require 'fs'
      path = require 'path'
      # sourcePath = path.resolve __dirname, './fixtures/tika.xhtml'
      # console.log sourcePath
      # html = fs.readFileSync sourcePath, 'utf-8'
      html = fs.readFileSync __dirname+'/fixtures/tika.xhtml', 'utf-8'
      sent =
        html: html

      f.flattenItem sent, (err, data) ->
        return done err if err
        images = data.content.filter (block) -> block.type is 'image'
        chai.expect(images.length).to.equal 6
        srcs = images.map (image) -> image.src
        chai.expect(srcs).to.eql [
          'image1.jpg'
          'image2.jpg'
          'image3.jpg'
          'image4.jpg'
          'image5.jpg'
          'image6.jpg'
        ]
        texts = data.content.filter (block) -> block.type is 'text'
        chai.expect(texts.length).to.equal 4
        schema.validate data, 'item', done
