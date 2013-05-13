# -- coding: utf-8

=begin

# _config.yml

sprockets:
  assets_dir: assets
  css:
    style: nested # http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#output_style
  js:
    compressor: uglifier
    uglifier_options: # https://github.com/lautis/uglifier
      mangle: true
      output:
        ascii_only: true

# Usage:
$ echo 'alert "hi"' > assets/script.js.coffee

in "_layout/foo.html"
<script src="{% asset script.js %}"></script>

generate as:
<script src="/assets/script-915b2cd86d2ab91b0bd790bee7496f3e.js"></script>

# Dependency:
- sprockets
- sprockets-sass
- sass
- (optional) coffee-script
- (optional) uglifier
=end

module Jekyll
  require "sprockets"
  require "sprockets-sass"
  require "sass"

  DEFAULT_ASSETS_DIR = "assets"

  def self.sprockets_filename(env, name)
    # test.css.scss => test-deadbeaf12345678deadbeaf.css
    asset = env[name]
    aa = env.attributes_for(name)
    "#{aa.pathname.basename.to_s[/^[^.]+/]}-#{asset.digest}#{aa.format_extension}"
  end

  class SprocketsTag < Liquid::Tag
    def initialize(tag_name, args, tokens)
      super
      @arg = args.split(/\s+/).first
      @tag_name = tag_name
    end

    def render(context)
      config = context.environments.first["site"]
      env = ::Sprockets::Environment.new
      if config["sprockets"] && config["sprockets"]["asset_dir"]
        env.append_path(config["sprockets"]["asset_dir"])
      else
        env.append_path(DEFAULT_ASSETS_DIR)
      end
      asset = env[@arg]
      File.join(File.dirname(asset.pathname.to_s.sub(config["source"], "")), Jekyll.sprockets_filename(env, @arg))
    end
  end


  class StaticFile
    alias :_write :write
    def write(dest)
      return _write(dest) unless @dir[assets_dir]

      asset = sprockets[@name]
      return false unless asset
      filename = Jekyll.sprockets_filename(sprockets, @name)
      dest_path = File.join(dest, @dir, filename)
      @@mtimes[path] = asset.mtime
      FileUtils.mkdir_p(File.dirname(dest_path))
      content =
        case sprockets.attributes_for(path).format_extension
          when ".css"
            # http://sass-lang.com/docs/yardoc/file.SASS_REFERENCE.html#output_style
            style = config["css"]["style"] || :nested
            Sass::Engine.new(asset.to_s, :syntax => :scss, :style => style.to_sym).render

          when ".js"
            # https://github.com/lautis/uglifier
            return asset.to_s unless config["js"] || config["js"]

            require "uglifier"
            ::Uglifier.compile(
              asset.to_s,
              :mangle => config["js"]["uglifier_options"]["mangle"] || false,
              :output => config["js"]["uglifier_options"]["output"] || {},
              :compress => config["js"]["uglifier_options"]["compress"] || {},
            )

          else
            asset.to_s
        end
      File.open(dest_path, "w"){|f| f.write content }
      FileUtils.touch(dest_path, :mtime => asset.mtime)

      true
    end

    private

    def config
      @site.config["sprockets"] || {}
    end

    def assets_dir
      config["assets_dir"] || DEFAULT_ASSETS_DIR
    end

    def sprockets
      env = ::Sprockets::Environment.new
      env.append_path(File.expand_path("../../#{assets_dir}", __FILE__))
      env
    end
  end
end

Liquid::Template.register_tag('asset', Jekyll::SprocketsTag)
