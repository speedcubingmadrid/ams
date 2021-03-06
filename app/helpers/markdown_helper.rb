# frozen_string_literal: true

module MarkdownHelper
  # Thanks WCA again: https://raw.githubusercontent.com/thewca/worldcubeassociation.org/master/WcaOnRails/app/helpers/markdown_helper.rb
  class WcaMarkdownRenderer < Redcarpet::Render::HTML

    def table(header, body)
      t = "<table class='table'>\n"
      t += "<thead>" + header + "</thead>\n" if header
      t += "<tbody>" + body + "</tbody>\n" if body
      t += "</table>"
      t
    end

    # This is annoying. Redcarpet implements this id generation logic in C, and
    # AFAIK doesn't provide any hook for calling this method directly from Ruby.
    # See C code here: https://github.com/vmg/redcarpet/blob/f441dec42a5097530328b20e9d5ed1a025c600f7/ext/redcarpet/html.c#L273-L319
    # Redcarpet issue here: https://github.com/vmg/redcarpet/issues/638.
    def header_anchor(text)
      Nokogiri::HTML(Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(with_toc_data: true)).render("# #{text}")).css('h1')[0]["id"]
    end

    def header(text, header_level)
      if @options[:with_toc_data]
        id = header_anchor(text)
        text = anchorable(text, id)
      end

      "<h#{header_level}>#{text}</h#{header_level}>\n"
    end

    def postprocess(full_document)
      # Support embed Google Maps
      full_document.gsub!(/map\(([^)]*)\)/) do
        google_maps_url = "https://www.google.com/maps/embed/v1/place?key=#{ENVied.GOOGLE_MAPS_API_KEY}&q=#{URI.encode_www_form_component(CGI.unescapeHTML($1))}"
        "<iframe width='600' height='450' frameborder='0' style='border:0' src=\"#{google_maps_url}\"></iframe>"
      end

      # Support embed YouTube videos
      # Note: the URL in parentheses is turned into an <a></a> tag by the `autolink` extension.
      full_document.gsub!(/youtube\(.*?href="([^)]*)".*?\)/) do
        embed_url = $1.gsub("watch?v=", "embed/")
        "<iframe width='640' height='390' frameborder='0' src='#{embed_url}'></iframe>"
      end

      full_document
    end
  end

  def md(content, target_blank: false, toc: false)
    if content.nil?
      return ""
    end

    options = {
      hard_wrap: true,
    }

    extensions = {
      tables: true,
      autolink: true,
    }

    if target_blank
      options[:link_attributes] = { target: "_blank" }
    end

    output = "".html_safe

    if toc
      options[:with_toc_data] = true
      output += Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC.new(options), extensions).render(content).html_safe
    end

    output += Redcarpet::Markdown.new(WcaMarkdownRenderer.new(options), extensions).render(content).html_safe
    output
  end
end
