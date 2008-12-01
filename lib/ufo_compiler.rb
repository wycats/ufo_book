require "rubygems"
require "image_size"

class Slurper
  class DuplicateName < StandardError; end
  class MissingName < StandardError; end
  
  def initialize(text, opts = {})
    @text, @chapter, @base_dir, @max_width = 
      text, opts[:chapter], opts[:base_dir] || Dir.pwd, 
      opts[:max_width] || 528
      
    @listing, @listings = 0, {}
    @figure, @figures = 0, {}
    @grid, @grids = 0, {}
    @section = []
    @section << @chapter ? @chapter : 0
    parse_text
  end
  
  def section(number)
    section = @chapter ? "#{@chapter}." : ""
    section << number.to_s
    section
  end
  
  def parse_text
    replace_listing!
    replace_figure!
    replace_table!
    replace_reference!(:listing)
    replace_reference!(:figure)
    replace_reference!(:grid, "Table")
    replace_cueballs!
    strip_todos! unless $EXTRAS
  end
  
  def img_size(width, height)
    if width < 528
      [width, height]
    else
      ratio = width / 528.0
      [(width / ratio).floor, (height / ratio).floor]
    end
  end
  
  def assert_unused(kind, name)
    list = instance_variable_get("@#{kind}s")
    if list.key?(name)
      raise DuplicateName, "You used #{$1} as a #{kind} name more than once"
    end    
  end  
  
  def replace_listing!
    @text.gsub!(/(<listing:(.*?)(?::"([^"]*?)")?>\n?)(.*?)\n\n/m) do |m|
      tag, name, contents = $1, $2, $4
      
      contents.gsub!(/# (\d+)/) do |n|
        "# !!-<a name=\"#{name}_cue_#{$1}\">#{$1}</a>-!!"
      end
      "#{tag}#{contents}\n\n"
    end

    @text.gsub!(/<listing:(.*?)(?::"([^"]*?)")?>/) do |m|
      assert_unused(:listing, $1)
    
      @listings[$1] = (@listing += 1)
      ret = "<p class='listing title'><a name=\"#{$1}\">Listing #{section(@listing)}</a>"
      ret << $2 if $2
      ret << "</p>"
    end
  end
  
  def replace_name!(kind)
    @text.gsub!(/<#{kind}:(.*?)(:"(.*)")?>/) do |m|
      assert_unused(kind, $1)
      
      name, string = $1, $3

      ivar, ivar_plural = 
        instance_variable_get("@#{kind}"), instance_variable_get("@#{kind}s")

      instance_variable_set("@#{kind}", ivar + 1)

      ivar_plural[$1] = (ivar += 1)
      
      yield(ivar, name, string)
    end    
  end

  def replace_figure!
    replace_name!(:figure) do |figure, path, string|
      img = File.read(File.join(@base_dir, "images", path))
      size = ImageSize.new(img)
      width, height = img_size(size.width, size.height)

      %{<div class='figure'><img src="#{@base_dir}/images/#{path}" width='#{width}' height='#{height}'/></div>\n} <<
      "<p class='figure title'><a name='#{path}'>Figure #{section(figure)}</a> #{string}</p>"
    end
  end
    
  def replace_table!
    replace_name!(:grid) do |grid, name, string|
      "<p class='table title'><a name='#{name}'>Table #{section(grid)}</a> #{string}</p>"
    end
  end

  def replace_reference!(type, name = type.to_s.capitalize)
    @text.gsub!(/<ref:#{type}:(.*)>/) do |m|
      kinds = instance_variable_get("@#{type}s")
    
      if !kinds.key?($1)
        raise MissingName, "You tried to reference #{$1}, but that #{type} did not exist"
      end
            
      "#{name} #{section(kinds[$1])}"
    end    
  end

  def replace_cueballs!
    @text.gsub!(/<cue:(.*?):(\d*)>/) do |m|
      "<a href=\"##{$1}_cue_#{$2}\">##{$2}</a>"
    end
  end
  
  def strip_todos!
    @text.gsub!(/^\s*> TODO((?!^\s*$).)*(^\s*$)/m, "")
  end
  
  def number_sections
    @text.gsub!(/^# (.*)/) { "# _#{$1}_{: .title} _#{@chapter}_{: .number}&nbsp;" } if @chapter
    
    @text.gsub!(/^(##+) (.*)/) do |m|
      msize = $1.size
      if msize == @section.size
        @section[-1] += 1
      elsif msize > @section.size
        @section[msize - 1] = 1
      else
        @section = @section[0..(msize - 1)]
        @section[msize - 1] ||= 0
        @section[msize - 1] += 1
      end
      ret = @section.map {|x| x ? x : 1}.join(".")
      "#{$1} _#{ret}_{: .number} _#{$2}_{: .title}&nbsp;"
    end
    
    @text
  end
  
  def to_s
    @text
  end
end