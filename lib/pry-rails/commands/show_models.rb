# encoding: UTF-8

class PryRails::ShowModels < Pry::ClassCommand
  match "show-models"
  group "Rails"
  description "Show all models."

  def options(opt)
    opt.banner unindent <<-USAGE
      Usage: show-models

      show-models displays the current Rails app's models.
    USAGE

    opt.on :G, "grep", "Filter output by regular expression", :argument => true
  end

  def process
    Rails.application.eager_load!

    @formatter = PryRails::ModelFormatter.new

    display_activerecord_models
    display_mongoid_models
  end

  def display_activerecord_models
    return unless defined?(ActiveRecord::Base)

    models = ActiveRecord::Base.descendants

    str = models.sort_by(&:to_s).map do |model|
      filter @formatter.format_active_record(model)
    end
    stagger_output str.join("\n")
  end

  def display_mongoid_models
    return unless defined?(Mongoid::Document)

    models = []

    ObjectSpace.each_object do |o|
      is_model = false

      begin
        is_model = o.class == Class && o.ancestors.include?(Mongoid::Document)
      rescue
        # If it's a weird object, it's not what we want anyway.
      end

      models << o if is_model
    end

    str = models.sort_by(&:to_s).map do |model|
      filter @formatter.format_mongoid(model)
    end
    stagger_output str.join("\n")
  end

  def filter(str)
    if opts.present?(:G)
      return unless str =~ grep_regex
      colorize_matches(str) # :(
    else
      str
    end
  end

  def colorize_matches(string)
    if Pry.color
      string.to_s.gsub(grep_regex) { |s| "\e[7m#{s}\e[27m" }
    else
      string
    end
  end

  def grep_regex
    @grep_regex ||= Regexp.new(opts[:G], Regexp::IGNORECASE)
  end
end

PryRails::Commands.add_command PryRails::ShowModels
