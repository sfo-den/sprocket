require 'sprockets_test'

class TestResolve < Sprockets::TestCase
  def setup
    @env = Sprockets::Environment.new(".")
  end

  test "resolve in default environment" do
    @env.append_path(fixture_path('default'))

    assert_equal fixture_path('default/gallery.js'),
      @env.resolve("gallery.js")
    assert_equal fixture_path('default/coffee/foo.coffee'),
      @env.resolve("coffee/foo.js")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min")
    assert_equal fixture_path('default/jquery.tmpl.min.js'),
      @env.resolve("jquery.tmpl.min.js")
    assert_equal fixture_path('default/manifest.js.yml'),
      @env.resolve('manifest.js.yml')

    refute @env.resolve_all("null").first
    assert_raises(Sprockets::FileNotFound) do
      @env.resolve("null")
    end
  end

  test "resolve accept type list before paths" do
    @env.append_path(fixture_path('resolve/javascripts'))
    @env.append_path(fixture_path('resolve/stylesheets'))

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript, text/css')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'text/css, application/javascript')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'application/javascript; q=0.8, text/css')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: 'text/css; q=0.8, application/javascript')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: '*/*; q=0.8, application/javascript')
    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo', accept: '*/*; q=0.8, text/css')
  end

  test "resolve extension before accept type" do
    @env.append_path(fixture_path('resolve/javascripts'))
    @env.append_path(fixture_path('resolve/stylesheets'))

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: 'application/javascript')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: '*/*')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: '*/*')

    assert_equal fixture_path('resolve/javascripts/foo.js'),
      @env.resolve('foo.js', accept: 'text/css, */*')
    assert_equal fixture_path('resolve/stylesheets/foo.css'),
      @env.resolve('foo.css', accept: 'application/javascript, */*')
  end

  test "resolve accept type quality in paths" do
    @env.append_path(fixture_path('resolve/javascripts'))

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'application/javascript')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'text/css')

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'application/javascript, text/css')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'text/css, application/javascript')

    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: 'application/javascript; q=0.8, text/css')
    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: 'text/css; q=0.8, application/javascript')

    assert_equal fixture_path('resolve/javascripts/bar.js'),
      @env.resolve('bar', accept: '*/*; q=0.8, application/javascript')
    assert_equal fixture_path('resolve/javascripts/bar.css'),
      @env.resolve('bar', accept: '*/*; q=0.8, text/css')
  end

  test "locate asset uri" do
    @env.append_path(fixture_path('default'))

    assert_equal "file://#{fixture_path('default/gallery.js')}?type=application/javascript",
      @env.locate("gallery.js")
    assert_equal "file://#{fixture_path('default/coffee/foo.coffee')}?type=application/javascript",
      @env.locate("coffee/foo.js")
    assert_equal "file://#{fixture_path('default/manifest.js.yml')}?type=text/yaml",
      @env.locate("manifest.js.yml")

    assert_equal "file://#{fixture_path('default/gallery.js')}?type=application/javascript",
      @env.locate("gallery", accept: 'application/javascript')
    assert_equal "file://#{fixture_path('default/coffee/foo.coffee')}?type=text/coffeescript",
      @env.locate("coffee/foo", accept: 'text/coffeescript')
  end
end
