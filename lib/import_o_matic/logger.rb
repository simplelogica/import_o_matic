module ImportOMmatic

  class Logger < ::Logger
    attr_accessor :counters

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
    end

    def initialize object_name
      object_name.gsub!('/', '_')
      self.counters = {}
      import_path = "log/importations/#{object_name}"
      FileUtils.mkdir_p(import_path) unless File.directory?(import_path)
      timestamp = Time.now.utc.iso8601.gsub(/\W/, '')
      file_name = "#{timestamp}_#{object_name}_import.log"
      super "#{import_path}/#{file_name}"
    end

    def finish
      self.info "---- End of importation"
      self.info "---- Results:"
      self.counters.each do |key, value|
        self.info "\t\t#{key.upcase}: #{value}" if key
      end
    end

    def counter kind
      counters[kind] = counters[kind].to_i.next
    end

    def print_errors text, item
      self.counter :errors
      self.error "-- Errors with data:"
      self.error "\t#{text}"
      self.error "\t#{item.errors.full_messages.to_sentence}"
    end
  end

end
