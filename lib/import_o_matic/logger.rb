module ImportOMmatic

  class Logger < ::Logger
    attr_accessor :counters, :path

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_formatted_s(:db)} #{severity} #{msg}\n"
    end

    def initialize object_name, max_logs = 10
      object_name.gsub!('/', '_')
      self.counters = {}
      log_dir = "log/imports/#{object_name}"
      FileUtils.mkdir_p(log_dir) unless File.directory?(log_dir)
      # Remove all logs unless max_logs -1 and create a new one
      clear_logs log_dir, max_logs.pred
      timestamp = Time.now.utc.iso8601.gsub(/\W/, '')
      file_name = "#{timestamp}_#{object_name}_import.log"
      super self.path = "#{log_dir}/#{file_name}"
    end

    def finish
      self.info "---- End of importation"
      self.info "---- Results:"
      # The returns the counters hash
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

    protected

    def clear_logs dir, max_logs
      old_logs = Dir.glob("#{dir}/*").sort_by { |path| File.mtime(path) }.reverse
      old_logs.shift(max_logs) if max_logs > 0
      File.delete(*old_logs)
    end
  end

end
