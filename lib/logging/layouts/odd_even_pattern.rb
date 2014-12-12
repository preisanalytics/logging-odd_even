module Logging
  module Layouts
    def self.even_odd_pattern( *args )
      return ::Logging::Layouts::EvenOddPattern if args.empty?
      ::Logging::Layouts::EvenOddPattern.new(*args)
    end

    class EvenOddPattern < Pattern

      def initialize( opts = {} )
        @created_at = Time.now

        @date_pattern = opts.getopt(:date_pattern)
        @date_method = opts.getopt(:date_method)
        @date_pattern = ISO8601 if @date_pattern.nil? and @date_method.nil?

        @pattern = opts.getopt(:pattern,
                               "[%d] %-#{::Logging::MAX_LEVEL_LENGTH}l -- %c : %m\n")

        cs_name = opts.getopt(:color_scheme)
        @color_scheme =
            case cs_name
              when false, nil; nil
              when true; ::Logging::ColorScheme[:default]
              else ::Logging::ColorScheme[cs_name] end

        self.class.create_date_format_methods(self)
        self.class.create_format_method(self)
      end

      DIRECTIVE_TABLE = {
          'c' => 'event.logger'.freeze,
          'd' => 'format_date(event.time)'.freeze,
          'F' => 'event.file'.freeze,
          'l' => '::Logging::LNAMES[event.level]'.freeze,
          'L' => 'event.line'.freeze,
          'm' => 'format_obj(event.data)'.freeze,
          'M' => 'event.method'.freeze,
          'p' => 'Process.pid'.freeze,
          'r' => 'Integer((event.time-@created_at)*1000).to_s'.freeze,
          't' => 'Thread.current.object_id.to_s'.freeze,
          'T' => 'Thread.current[:name]'.freeze,
          'X' => lambda do |var_name| "::Logging.mdc['#{var_name}']" end,
          'x' => lambda do |separator| "::Logging.ndc.context.join('#{separator}')" end,
          '%' => :placeholder
      }.freeze

      class SprintfBag
        def initialize(color_scheme,color_alias_table, directive_table)
          @format_string='"'
          @format_string_bright='"'
          @args=[]
          @name_map={}
          @color_scheme=color_scheme
          @color_alias_table=color_alias_table
          @directive_table = directive_table

        end

        # @param [String] pattern_name like 'message' or 'time'
        # @param [String] string the string that needs coloring
        def add_colored(string,pattern_name,arg=nil)
          if @color_scheme and !@color_scheme.lines?
            @format_string << @color_scheme.color(string,@color_alias_table[pattern_name])
            @format_string_bright << @color_scheme.color(string,"#{@color_alias_table[pattern_name]}_bright")
          else
            self << string
          end

          directive=@directive_table[pattern_name]
          if @directive_table[pattern_name].respond_to?(:call)
            @args << directive.call(arg)
          else
            @args << directive.dup
          end
          self
        end

        def add(str)
          @format_string << str
          @format_string_bright << str
          self
        end
        alias :<< add

        def add_arg(arg, modify=false)
          if modify
            @args.last << arg
          else
            @args << arg
          end
          self
        end

        def add_variable(value,arg="@var")
          map_name="@map_name_#{@name_map.size}"
          @name_map[map_name]=value
          @args << arg.gsub("@var",map_name)
          self
        end

        def set_variables(obj)
          @name_map.each_pair do |name, value|
            obj.instance_variable_set(name.to_sym, value)
          end
        end

        def to_sprintf(bright=false)
          format = bright ? @format_string_bright : @format_string
          sprintf = "sprintf("
          sprintf <<  format + '"'
          sprintf << ', ' + @args.join(', ') unless @args.empty?
          sprintf << ")"

          if @color_scheme and @color_scheme.lines? #generate colors at runtime
            sprintf = "color_scheme.color(#{sprintf}, event.even? ? ::Logging::LNAMES[event.level] : ::Logging::LNAMES[event.level].to_s + '_bright' )"

          end

          sprintf
        end


      end

      def self.create_format_method( pf )
        spf_bag=SprintfBag.new(pf.color_scheme,COLOR_ALIAS_TABLE,DIRECTIVE_TABLE)
        pattern=pf.pattern.dup

        while true
          m = DIRECTIVE_RGXP.match(pattern)
          # * $1 is the stuff before directive or "" if not applicable
          # * $2 is the %#.# match within directive group
          # * $3 is the directive letter
          # * $4 is the precision specifier for the logger name
          # * $5 is the stuff after the directive or "" if not applicable

          spf_bag << m[1] unless m[1].empty?

          case m[3]
            when '%'; spf_bag << '%%'
            when 'c'
              spf_bag.add_colored(m[2]+'s',m[3])
              if m[4]
                precision = Integer(m[4]) rescue nil
                if precision
                  raise ArgumentError, "logger name precision must be an integer greater than zero: #{precision}" unless precision > 0
                  spf_bag.add_arg(".split(::Logging::Repository::PATH_DELIMITER).last(#{m[4]}).join(::Logging::Repository::PATH_DELIMITER)",true)
                else
                  spf_bag << "{#{m[4]}}"
                end
              end
            when 'l' #level is dynamic
              if pf.color_scheme and pf.color_scheme.levels?
                name_map = ::Logging::LNAMES.map { |name| pf.color_scheme.color(("#{m[2]}s" % name), name) }
                name_bright_map = ::Logging::LNAMES.map { |name| pf.color_scheme.color(("#{m[2]}s" % name), "#{name}_bright") }
                the_map={0 => name_map, 1 => name_bright_map}
                spf_bag.add_variable(the_map,"@var[event.odd_even][event.level]") << '%s'
                spf_bag << "{#{m[4]}}" if m[4]
              else
                spf_bag << m[2] + 's'
                spf_bag << "{#{m[4]}}" if m[4]
                spf_bag.add_arg(DIRECTIVE_TABLE[m[3]])
              end
            when 'X'
              raise ArgumentError, "MDC must have a key reference" unless m[4]
              spf_bag.add_colored(m[2] + 's',m[3], m[4])

            when 'x'
              separator = m[4].to_s
              separator = ' ' if separator.empty?
              spf_bag.add_colored(m[2] + 's',m[3], separator)

            when *DIRECTIVE_TABLE.keys
              spf_bag.add_colored(m[2] + 's',m[3])
              spf_bag << "{#{m[4]}}" if m[4]
            when nil; break
            else
              raise ArgumentError, "illegal format character - '#{m[3]}'"
          end

          break if m[5].empty?
          pattern = m[5]
        end

        sprintf=

            code = "undef :format if method_defined? :format\n"
        code << "def format( event )
                  if event.even?
                    #{spf_bag.to_sprintf}
                  else
                    #{spf_bag.to_sprintf(true)}
                  end
                 end"

        ::Logging.log_internal(0) {code}
        spf_bag.set_variables(pf)
        pf._meta_eval(code, __FILE__, __LINE__)
      end

    end
  end
end
