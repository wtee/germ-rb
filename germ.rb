#!/usr/pkg/bin/ruby

# germ -- let your ideas germinate

# This is free and unencumbered software released into the public domain
# under the terms of the Unlicense <http://unlicense.org>.

require 'date'

# ==== Configuration ====

# This directory is used whenever your gopherlog links to itself. It's where your
# germ script resides relative to your server's root directory.
Link_dir = "/users/wt"

# This directory is where you keep the documents that make up your gopherlog, 
# including your posts as well as your header and divider files.
Doc_dir = "/ftp/pub#{Link_dir}/rc_posts"

# This is the maximum number of posts to display per menu.
Max_posts = 6

# This is the text displayed on the main and archive menues to select individual posts.
Permalink_txt = "View Post/Comments"

# This is the text that indicates a post has been truncated for the main menu.
More_txt = "[Continued...]"

# This divides comments so that it is easy to tell where one begins and another ends.
# This is also used to count the number of comments a post has (as there is one Cmt_div
# per comment), so it is advisable that it not be changed after you start receiving 
# comments. Such a change would ruin comment counting.
Cmt_div = "---"

# This is the server that your gopherlog is hosted on.
Server = "sdf.org"

# This is the port your server listens to. If you don't know it's not 70 you should 
# probably leave it as it is.
Port = "70"

# This is the name of your germ installation, which it uses when it links to itself.
# make sure it is correct or none of your links will work.
Name = "rcphlog.cgi"

# This is where you plugins go.
Plugin_dir = ""

# This file is shown at the top of your blog.
Header = "#{Doc_dir}/header.txt"

# This file is the divider that goes between your posts.
Div = "#{Doc_dir}/div.txt"


# ==== End Configuration ====

ENV['PATH'] = ''

Txt_line_end = "\tnull\ttext\t70\r\n"
Ver = "germ 1.0pre"
Footer = "i#{Txt_line_end}ipowered by #{Ver}#{Txt_line_end}.\r\n"
To_home_string = "1Home\t#{Link_dir}/#{Name}\t#{Server}\t#{Port}\r\n"

def show_main(posts)
    post_list = posts.split
    if Max_posts > post_list.length then
        show_page(post_list.join(' '))
    else 
        show_page(post_list[0..(Max_posts - 1)].join(' '))
        print "1Older Posts\t#{Link_dir}/#{Name}?archive1\t#{Server}\t#{Port}\r\n"
    end
end

def show_archive(posts)
    n = $query.sub(/archive/, '').to_i
    post_list = posts.split
    min = Max_posts * n
    max = Max_posts * n + Max_posts - 1 
    if max > post_list.length then
        max = post_list.length
    end
        show_page(post_list[min..max].join(' '))
    if n == 1 then
        print "1Newer Posts\t#{Link_dir}/#{Name}\t#{Server}\t#{Port}\r\n"
    elsif n > 1
        print "1Newer Posts\t#{Link_dir}/#{Name}?archive#{n - 1}\t#{Server}\t#{Port}\r\n"
    end
    if post_list.length > max then
        print "1Older Posts\t#{Link_dir}/#{Name}?archive#{n + 1}\t#{Server}\t#{Port}\r\n"
    end
end

def show_tagged_posts(posts)
    tag = $query.sub(/^tag=/,'').gsub(/_/,' ')
    tagged_posts = Array.new
    post_list = posts.split
    post_list.each do |post|
        f = File.open(post) 
        tag_line = f.gets
        if tag_line.match(/^#tags/i) then
            if tag_line.match(/(^#tags\s+#{tag}|,\s*#{tag})/i) then
                tagged_posts.push(post)
            end
        end
        f.close
    end
    show_page(tagged_posts.join(' '))
end

def show_page(posts)
    post_list = posts.split
    post_list.each do |post|
        show_post(post)
        show_file(Div)
    end
end

def show_post(file)
    if File.size?(file) then
         tag_list = ''
         post = file.sub(/#{Doc_dir}\//, '')
         f = File.open(file, "r") # || print "3Can't open #{file}! #{$!} #{Txt_line_end}"
         print "i#{f.mtime.strftime("%Y %B %d, %R")}#{Txt_line_end}i#{Txt_line_end}"
         while line = f.gets
             line.chomp!
             if line.match(/^#tags\s+/i) then
                 tag_list = line.sub(/^#tags\s+/i,'')
             elsif line.match(/^[0-9ceghisIMTdx].+?\t/)
                 print "#{line}\r\n"
             elsif line.match(/^--more--$/)
                 if $query.match(/^\w+\.post$/) then
                     next
                 else
                     print "i#{More_txt}#{Txt_line_end}"
                     break
                 end
             else 
                 print "i#{line}#{Txt_line_end}"
             end
         end
         f.close
         if tag_list.length > 0 then 
            show_tags(tag_list) 
         end
         if $query.match(/^.*?\.post$/) then
             show_comments("#{file}.cmt")
         else 
             print "i#{Txt_line_end}1#{Permalink_txt}(#{cmt_count("#{file}.cmt")})\t#{Link_dir}/#{Name}?#{post}\t#{Server}\t#{Port}\r\n"
         end
    end   
end

def show_tags(tags)
    tag_list = tags.split(/,\s*/)
    print "i#{Cmt_div}#{Txt_line_end}"
    print "iTags:#{Txt_line_end}"
    tag_list.each do |tag|
        link_tag = tag.gsub(/\s+/, '_')
        print "1#{tag}\t#{Link_dir}/#{Name}?tag=#{link_tag}\t#{Server}\t#{Port}\r\n"
    end
    print "i#{Cmt_div}#{Txt_line_end}"
end

def show_comments(file)
    post = file.sub(/#{Doc_dir}\//,'').sub(/\.cmt/,'')
    print "i#{Txt_line_end}"
    print "7Leave Comment\t#{Link_dir}/#{Name}\t#{Server}\t#{Port}\r\n"
    print "iTo leave comment enter \'#{post}\' at the prompt followed by a space and then your comment of 950 characters or less.".txt_wrap("#{Txt_line_end}i") + "\r\n"
    show_file(Div)
    if File.exists?(file) then show_file(file) end
end

def cmt_count(file)
    count = 0
    if File.exists?(file) then
        f = File.open(file)
        while line = f.gets 
            if line.match(/^#{Cmt_div}$/) then count += 1 end
        end 
        f.close
    end
    return count
end

def get_comment 
    if $query.length > 950 then
    print "3Sorry, comments should be less than 950 characters.#{Txt_line_end}#{To_home_string}"
    else
        comment = $query.split
        link_post = comment.shift
        post = "#{Doc_dir}/#{link_post}"
        cmt_file = "#{post}.cmt"
        tmp_cmt_file = "#{cmt_file}.tmp"
	    if File.exists?(post)
	        f = File.new(tmp_cmt_file, "w")
	        f.flock(File::LOCK_EX)
	        f.puts DateTime.now.strftime('%Y %B %d, %R')
	        f.puts comment.join(' ').txt_wrap
	        f.puts "\n#{Cmt_div}\n\n"
	        if File.exists?(cmt_file) then 
	            old = File.open(cmt_file, "r")
	            while line = old.gets 
                        f.puts line
                    end
	            old.close
	        end
	        f.close
	        File.rename(tmp_cmt_file, cmt_file)
	        File.chmod(0640, cmt_file)
	        print "iYour comment has been posted.#{Txt_line_end}"
	        print "1View your comment\t#{Link_dir}/#{Name}?#{link_post}\t#{Server}\t#{Port}\r\n"
	    else
                print "3 Sorry, #{link_post} does not exist.#{Txt_line_end}#{To_home_string}"
	    end
	end
end 

def show_header
    print To_home_string
    show_file(Header)
#    show_file(Div)
end

def show_file(file)
    f = File.open(file, "r") # || print "3Can't open #{file}! #{$!} #{Txt_line_end}"
    while line = f.gets
        print "i#{line.chomp}#{Txt_line_end}"
    end
    f.close
end

class String
    def txt_wrap(line_end = "\n", width = 65)
        self.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1#{line_end}")
    end
end

# check to see if the server is using cgi variables to communicate with germ
# like a proper server or if its passing information as arguments like some
# gopher servers.

if ENV.has_key?('QUERY_STRING') then
    $query = ENV['QUERY_STRING']
else 
    $query = ARGV.join(' ')
end

# load posts from Doc_dir.

post_list = posts = Array.new
fd = Dir.open(Doc_dir)
fd.each { |file| posts.push("#{Doc_dir}/#{file}") if file.match(/post$/) }
fd.close
post_list = posts.sort_by{ |post| File.mtime(post) }.reverse

# parse client input and display appropriate page.

if $query.length == 0 then
    show_header
    show_main(post_list.join(' '))
elsif $query.match(/^.*?\.post$/)
    show_header
    show_post("#{Doc_dir}/#{$query}")
elsif $query.match(/^archive\d+$/)
    show_header
    show_archive(post_list.join(' '))
elsif $query.match(/^tag=.*/)
    show_header
    show_tagged_posts(post_list.join(' '))
elsif $query.match(/^.*?\.post\s\.*/)
    get_comment
else
    print"3Oh dear, something seems to have gone wrong!#{Txt_line_end}#{To_home_string}"
end
print Footer
