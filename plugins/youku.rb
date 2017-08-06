class Youku < Liquid::Tag

def initialize(tagName, markup, tokens)
  super
  
  @params = markup.split(" ")
  if @params.count >= 1
    @id = @params[0]
    if @params.count >= 3
      @width = @params[1]
      @height = @params[2]
    else
      @width = 560
      @height = 420
    end
  else
    raise "No Youku ID provided in the \"youku\" tag"    
  end
end

def render(context)
# "<iframe height=498 width=510 src="http://player.youku.com/embed/XNTEzNzcwNDI0" frameborder=0 allowfullscreen></iframe>"
"<iframe style=\"margin:0 auto; display: block\" height=\"#{@height}\" width=\"#{@width}\" src=\"http://player.youku.com/embed/#{@id}?color=white&theme=light\"></iframe>"
end

Liquid::Template.register_tag "youku", self
end
