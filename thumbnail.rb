# -- coding: utf-8

=begin
{% thumbnail 200x200> %}
static/images/m1.jpg
static/images/m2.jpg
{% endthumbnail%}
=end

class ThumbnailBlock < Liquid::Block
  def initialize(tagname, size, tokens)
    super
    # imagemagick -resize options:
    # http://www.imagemagick.org/script/command-line-options.php?ImageMagick=b7tpeg7uqvmkq3i9p7ofc6g4t0#resize
    # http://www.imagemagick.org/script/command-line-processing.php#geometry
    # default is "600x400" that means thumbnail can be max size to "600x400" but aspect ratio considered
    @size = size.length > 0 ? size : "600x400"
    @size.strip!
  end

  def render(context)
    text = "<p>"
    site = context.registers[:site]
    #lines = super.first.strip.split("\n")
    lines = super.strip.split("\n")
    #system(%W!echo #{lines}!)
    lines.each do |path|
      src = File.join(site.source, path)
      if File.exists?(src) && path.length > 0
        thumb = File.join(site.source, "static/images/thumb-#{@size.gsub(%r![^a-zA-Z0-9]!,"")}-#{Digest::MD5.hexdigest(File.read(src))}#{File.basename(path)}")
        if File.exists?(thumb)
          text << "<a href=\"#{src.gsub(site.source, "")}\"><img src=\"#{thumb.gsub(site.source, "")}\" /></a>"
        else
          cmd = ['/usr/bin/convert', "-resize", @size, src, thumb]
          #system(*["echo", *cmd])
          if system(*cmd)
            text << "<a href=\"#{src.gsub(site.source, "")}\"><img src=\"#{thumb.gsub(site.source, "")}\" /></a>"
          end
        end
      else
        text << "<br />" << path << "<br />"
      end
    end
    text << "</p>\n\n"
  end
end

Liquid::Template.register_tag('thumbnail', ThumbnailBlock)
