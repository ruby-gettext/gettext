require 'locale/util/memoizable'

module GetText
  module ClassInfo
    extend self
    include Locale::Util::Memoizable

    # normalize the klass name
    def normalize_class(klass)
      ret = (klass.kind_of? Module) ? klass : klass.class
      if ret.name =~ /^\#<|^$/ or ret == GetText
        ret = Object
      end
      ret
    end

    # Internal method for related_classes.
    def related_classes_internal(klass, all_classes = [], analyzed_classes = [] )
      ret = []
      klass = normalize_class(klass)

      return [Object] if [Object, Kernel].include? klass

      ary = klass.name.split(/::/)
      while(v = ary.shift)
        ret.unshift(((ret.size == 0) ? Object.const_get(v) : ret[0].const_get(v)))
      end
      ret -= analyzed_classes
      if ret.size > 1
        ret += related_classes_internal(ret[1], all_classes, analyzed_classes)
        ret.uniq!
      end
      analyzed_classes << klass unless analyzed_classes.include? klass
      klass.ancestors[1..-1].each do |v|
        ret += related_classes_internal(v, all_classes, analyzed_classes)
        ret.uniq!
      end

      if all_classes.size > 0
        ((ret - [Kernel]) & all_classes).uniq 
      else
        (ret - [Kernel]).uniq
      end
    end

    # Returns the classes which related to klass 
    # (klass's ancestors, included modules and nested modules)
    def related_classes(klass, all_classes = [])
      ret = related_classes_internal(klass, all_classes)
      (ret + [Object]).uniq
    end
    memoize :related_classes
  end
end