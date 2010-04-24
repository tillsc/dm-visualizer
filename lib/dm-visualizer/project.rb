require 'set'

module DataMapper
  module Visualizer
    #
    # Defines the paths and directories to load for a DataMapper project.
    #
    class Project

      # The directories to include
      attr_reader :include_dirs

      # The path glob patterns to require
      attr_reader :require_globs

      #
      # Creates a new project.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @option options [Array] :include
      #   The directories to include into the `$LOAD_PATH` global variable.
      #
      # @option options [Array] :require
      #   The path globs to require.
      #
      def initialize(options={})
        @include_dirs = Set[]
        @require_globs = Set[]

        if options[:include]
          @include_dirs += options[:include]
        end

        if options[:require]
          @require_globs += options[:require]
        end
      end

      #
      # Creates a new project and loads it's files.
      #
      # @param [Hash] options
      #   Additional options.
      #
      # @yield [project]
      #
      # @yieldparam [Project] project
      #
      def Project.load(options={},&block)
        project = Project.new(options)
        project.load!

        block.call(project) if block
        return project
      end

      #
      # Activates the project by adding it's include directories to the
      # `$LOAD_PATH` global variable.
      #
      # @return [true]
      #
      def activate!
        @include_dirs.each do |dir|
          $LOAD_PATH << dir if File.directory?(dir)
        end

        return true
      end

      #
      # De-activates the project by removing it's include directories to the
      # `$LOAD_PATH` global variable.
      #
      # @return [true]
      #
      def deactivate!
        $LOAD_PATH.reject! { |dir| @include_dirs.include?(dir) }
        return true
      end

      #
      # Attempts to load all of the projects files.
      #
      # @return [true]
      #
      def load!
        activate!

        @require_globs.each do |glob|
          @include_dirs.each do |dir|
            Dir[File.join(dir,glob)].each do |path|
              relative_path = path[(dir.length + 1)..-1]

              begin
                require relative_path
              rescue LoadError => e
                STDERR.puts "dm-visualizer: unable to load #{relative_path} from #{dir}"
                STDERR.puts "dm-visualizer: #{e.message}"
              end
            end
          end
        end

        deactivate!
        return true
      end

      #
      # Enumerates over each DataMapper Model loaded from the project.
      #
      # @yield [model]
      #   The given block will be passed every model registered with
      #   DataMapper.
      #
      # @yieldparam [DataMapper::Model]
      #   A model loaded from the project.
      #
      def each_model(&block)
        DataMapper::Model.descendants.each(&block)
      end

      #
      # Enumerates over each DataMapper property from each model.
      #
      # @yield [property,model]
      #   The given block will be passed every property from every model
      #   that is registered with DataMapper.
      #
      # @yieldparam [DataMapper::Property] property
      #   The property.
      #
      # @yieldparam [DataMapper::Model] model
      #   The model that the property belongs to.
      #
      def each_property
        each_model do |model|
          model.properties.each do |property|
            yield property, model
          end
        end
      end

      #
      # Enumerates over each DataMapper relationship between each model.
      #
      # @yield [relationship,model]
      #   The given block will be passed every relationship from every
      #   model registered with DataMapper.
      #
      # @yieldparam [DataMapper::Relationship] relationship
      #   The relationship.
      #
      # @yieldparam [DataMapper::Model] model
      #   The model that the relationship belongs to.
      #
      def each_relationship
        each_model do |model|
          model.relationships.each_value do |relationship|
            yield relationship, model
          end
        end
      end

    end
  end
end
