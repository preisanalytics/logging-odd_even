module Logging
  class ColorScheme

    RED_BRIGHT        = "\e[1;31m".freeze    # Set the terminal's foreground ANSI color to red.
    GREEN_BRIGHT      = "\e[1;32m".freeze    # Set the terminal's foreground ANSI color to green.
    YELLOW_BRIGHT     = "\e[1;33m".freeze    # Set the terminal's foreground ANSI color to yellow.
    BLUE_BRIGHT       = "\e[1;34m".freeze    # Set the terminal's foreground ANSI color to blue.
    MAGENTA_BRIGHT    = "\e[1;35m".freeze    # Set the terminal's foreground ANSI color to magenta.
    CYAN_BRIGHT       = "\e[1;36m".freeze    # Set the terminal's foreground ANSI color to cyan.
    WHITE_BRIGHT      = "\e[1;37m".freeze    # Set the terminal's foreground ANSI color to white.

    ON_RED_BRIGHT     = "\e[1;41m".freeze    # Set the terminal's background ANSI color to red.
    ON_GREEN_BRIGHT   = "\e[1;42m".freeze    # Set the terminal's background ANSI color to green.
    ON_YELLOW_BRIGHT  = "\e[1;43m".freeze    # Set the terminal's background ANSI color to yellow.
    ON_BLUE_BRIGHT    = "\e[1;44m".freeze    # Set the terminal's background ANSI color to blue.
    ON_MAGENTA_BRIGHT = "\e[1;45m".freeze    # Set the terminal's background ANSI color to magenta.
    ON_CYAN_BRIGHT    = "\e[1;46m".freeze    # Set the terminal's background ANSI color to cyan.
    ON_WHITE_BRIGHT   = "\e[1;47m".freeze    # Set the terminal's background ANSI color to white.

  end
end

module Logging
  class LogEvent
    @@last_odd_even=0

    def odd_even
      @odd_even ||= @@last_odd_even=(@@last_odd_even-1).abs
    end
    def even?
      odd_even == 0
    end
    def odd?
      odd_even == 1
    end
  end
end
