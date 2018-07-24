require "rototiller/task/params"
require "rototiller/utilities/color_text"

module Rototiller
  module Task
    # The main EnvVar type to implement envrironment variable handling
    #   contains its messaging, status, and whether it is required.
    #   The rototiller Param using it knows what to do with its value.
    # @since v0.1.0
    # @api public
    # @attr [String]         default  The default value of this env_var to use. if we have a default and
    #   the system ENV does not have a value this implies the env_var is not required. If not default is specified but the parent parameter has a `#name` then that name is used as the default.
    #   Used internally by CommandFlag, ignored for standalone EnvVar.
    # @attr_reader [Boolean] stop     Whether the state of the EnvVar requires the task to stop
    # @attr_reader [Boolean] value    The value of the ENV based on specified default and environment state
    class EnvVar < RototillerParam
      include Rototiller::ColorText
      STATUS = { nodefault_noexist: 0, nodefault_exist: 1, default_noexist: 2, default_exist: 3 }.freeze

      # this env_var's name (as specified by user)
      # @return [String] the env_var itself
      attr_accessor :name
      # this env_var's default value (as specified by user)
      # @return [String] the env_var's default value if none in system
      attr_accessor :default
      # this env_var's message (as specified by user)
      # @return [String] the env_var's message
      attr_accessor :message
      # this env_var's value
      # @return [String] the env_var's value
      attr_reader   :value
      # should we stop because a required env var is not set?
      # @return [Boolean] stop?
      attr_reader   :stop

      # Creates a new instance of EnvVar, holds information about the ENV in the environment
      # @param [Hash, Array<Hash>] args hash of information about the environment variable
      # @option args [String] :name The environment variable
      # @option args [String] :default The default value for the environment variable
      # @option args [String] :message A message describing the use of this variable
      # for block { |b| ... }
      # @api public
      # @yield EnvVar object with attributes matching method calls supported by EnvVar
      # @return EnvVar object
      def initialize(args = {})
        @parent_name = args[:parent_name]
        @message ||= args[:parent_message]
        args.delete(:parent_name)
        args.delete(:parent_message)
        block_given? ? (yield self) : send_hash_keys_as_methods_to_self(args)

        raise(ArgumentError, "A name must be supplied to add_env") unless @name
        @env_value_set_by_us = false
        reset
      end

      # The formatted messages about this EnvVar's status to be displayed to the user
      # @param indent [String] how far to indent each message
      # @return [String] the EnvVar's message, formatted for color and meaningful to the state of the EnvVar
      # @api public
      INDENT_ARRAY = ["","  "]
      def message(indent=0)
        # INDENT_ARRAY above, only supports to 1
        #   it turns out we really only want one level of indents
        raise ArgumentError.new(indent) if indent > 1
        this_message = String.new

        if env_status    == STATUS[:nodefault_noexist]
          this_message << INDENT_ARRAY[ indent ] + red_text('[E] required: ')
          this_message << "'#{@name}'; '#{@message}'\n"
        elsif env_status == STATUS[:nodefault_exist]
          this_message << INDENT_ARRAY[ indent ] + yellow_text('[I] ')
          this_message << "'#{@name}': using system: '#{@value}', no default; '#{@message}'\n"
        elsif env_status == STATUS[:default_noexist]
          this_message << INDENT_ARRAY[ indent ] + green_text('[I] ')
          this_message << "'#{@name}': using default: '#{@value}'; '#{@message}'\n"
        elsif env_status == STATUS[:default_exist]
          this_message << INDENT_ARRAY[ indent ] + yellow_text('[I] ')
          this_message << "'#{@name}': using system: '#{@value}', default: '#{@default}'; '#{@message}'\n"
        end
      end

      # The string representation of this EnvVar; the value on the system, or nil
      # @return [String] the EnvVar's value
      # @api public
      def to_str
        @value
      end
      alias to_s to_str

      # Sets the name of the EnvVar
      # @raise [ArgumentError] if name contains an illegal character for bash environment variable
      # @api public
      # @return [void]
      def name=(name)
        name.each_char do |char|
          message = "You have defined an environment variable with an illegal character: #{char}"
          raise ArgumentError, message unless char =~ /[a-zA-Z]|\d|_/
        end
        @name = name
      end

      private

      # @api private
      def reset
        # if no default given, use parent param's name
        @default ||= @parent_name
        @stop = env_value_provided_by_user? || @default ? false : true

        if @name
          @value = ENV[@name] || @default
          unless env_value_provided_by_user?
            ENV[@name] = @value
            @env_value_set_by_us = true
          end
        else
          @value = @default
        end
      end

      # @api private
      def env_value_provided_by_user?
        # its possible that name could not be set
        ENV.key?(@name) if @name ? true : false
      end

      # @api private
      def env_status
        return STATUS[:nodefault_noexist] if !@default &&  @env_value_set_by_us
        return STATUS[:nodefault_exist]   if !@default && !@env_value_set_by_us
        return STATUS[:default_noexist]   if  @default &&  @env_value_set_by_us
        return STATUS[:default_exist]     if  @default && !@env_value_set_by_us
      end
    end
  end
end
