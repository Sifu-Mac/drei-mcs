module CommentsHelper
  URL_PATTERN = %r{(https?://[^\s<]+)}.freeze

  def comment_body_with_links(body)
    fragments = body.to_s.split(URL_PATTERN)

    safe_join(fragments.map do |fragment|
      if fragment.match?(%r{\Ahttps?://})
        link_to fragment, fragment,
          target: "_blank",
          rel: "noopener noreferrer",
          style: "color:#1e5eff;text-decoration:underline;text-underline-offset:2px"
      else
        ERB::Util.html_escape(fragment)
      end
    end)
  end
end
