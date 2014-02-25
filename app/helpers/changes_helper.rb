#TODO: move to template
module ChangesHelper
  def htmlize_changes(changes)
    return '' if changes.empty?

    res = StringIO.new()
    url = changes[:url]

    changes[:commits].each do |c|
      res.write "<div>"
      res.puts "#{boldize("commit")} #{link_to_commit(url, c[:sha])}<br />"
      res.puts "#{boldize("Author:")} #{h c[:author][:name]} &lt;#{h c[:author][:email]}&gt;<br />"
      res.puts "#{boldize("Date:")} #{h Time.at(c[:authored_date]).to_s}<br />"
      res.puts "#{h(c[:message].chomp)}<br />"

      c[:changes].each do |cc|
        case cc[:type]
          when 'A', 'D', 'M'
            res.puts "#{boldize(cc[:type])} #{h cc[:path]}  |  #{h cc[:stats]}<br />"
          when 'S'
            res.puts  "#{boldize("S")} #{h cc[:name]} #{h cc[:sha_was]} => #{h cc[:sha]}<br />"
            res.write '<div style="margin-left: 10px">'
            res.write htmlize_changes(cc)
            res.write "</div>"
        end
      end
      res.puts "<br />"
      res.write "</div>"
    end

    res.string
  end

private
  def boldize(s)
    content_tag(:strong, s)
  end
end