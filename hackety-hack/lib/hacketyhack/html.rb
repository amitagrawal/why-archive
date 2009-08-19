module Hpricot
  OK_ELE = ['a', 'abbr', 'acronym', 'address', 'area', 'b', 'big',
    'blockquote', 'br', 'button', 'caption', 'center', 'cite', 'code', 'col',
    'colgroup', 'dd', 'del', 'dfn', 'dir', 'div', 'dl', 'dt', 'em', 'fieldset',
    'font', 'form', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'hr', 'i', 'img', 'input',
    'ins', 'kbd', 'label', 'legend', 'li', 'map', 'menu', 'ol', 'optgroup',
    'option', 'p', 'pre', 'q', 's', 'samp', 'select', 'small', 'span', 'strike',
    'strong', 'sub', 'sup', 'table', 'tbody', 'td', 'textarea', 'tfoot', 'th',
    'thead', 'tr', 'tt', 'u', 'ul', 'var']

  OK_ATTR = ['abbr', 'accept', 'accept-charset', 'accesskey',
    'action', 'align', 'alt', 'axis', 'border', 'cellpadding', 'cellspacing',
    'char', 'charoff', 'charset', 'checked', 'cite', 'class', 'clear', 'cols',
    'colspan', 'color', 'compact', 'coords', 'datetime', 'dir', 'disabled',
    'enctype', 'for', 'frame', 'headers', 'height', 'href', 'hreflang', 'hspace',
    'id', 'ismap', 'label', 'lang', 'longdesc', 'maxlength', 'media', 'method',
    'multiple', 'name', 'nohref', 'noshade', 'nowrap', 'prompt', 'readonly',
    'rel', 'rev', 'rows', 'rowspan', 'rules', 'scope', 'selected', 'shape', 'size',
    'span', 'src', 'start', 'summary', 'tabindex', 'target', 'title', 'type',
    'usemap', 'valign', 'value', 'vspace', 'width']

  def self.fixup(str)
    ele = Hpricot("#{str}")
    (ele/"*").each do |x|
      next unless x.respond_to? :name
      next if x.name == "embed"
      if OK_ELE.include? x.name
        if x.respond_to? :attributes
          a = x.attributes
          a.keys.each do |k|
            a.delete(k) unless OK_ATTR.include? k
          end
        end
      else
        x.parent.children.delete(x)
      end
    end
    ele.to_html
  end
  module Elem::Trav
    def design(css)
      style = (get_attribute('style')||"").split(/\s*;\s*/).inject({}) do |hsh, att|
        k, v = att.split(/\s*:\s*/, 2)
        hsh[k] = v
        hsh
      end
      str = 
        style.merge(css).map do |k, v|
          "#{k}: #{v};"
        end.join
      set_attribute('style', str)
      self
    end
  end
end

# fake markaby
module Camping
  module Page
    module Custom
      def puts(str)
        self << HTML(str)
      end
      def build(ele, &blk)
        Camping::Page.build(@opts, ele, &blk)
      end
    end
    def self.build(opts = {}, ele = nil, &b)
      ele ||= Hpricot::Doc.new([])

      ele.extend Custom, Hpricot::Builder
      if opts[:mixin]
        ele.extend *opts[:mixin]
      end 
      if opts[:assigns]
        opts[:assigns].each do |k, v|
          ele.instance_variable_set("@#{k}", v)
        end
      end 
      if opts[:self]
        opts[:self].instance_variables.each do |k|
          ele.instance_variable_set(k, opts[:self].instance_variable_get(k))
        end
      end
      ele.instance_variable_set("@opts", opts)
      ele.instance_eval &b
      ele
    end 
  end
end

