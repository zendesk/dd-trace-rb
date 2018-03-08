require 'securerandom'

begin
  puts "[APP][#{Process.pid}] Starting..."

  DELIMITER = "*DD_DELIM*"
  Span = Struct.new(:name, :span_id)

  r, w = IO.pipe
  worker_pid = Process.spawn("ruby bin/worker.rb", in: r)
  Process.detach(worker_pid)

  5.times do
    sleep(1)
    object = Span.new('rack.request', SecureRandom.uuid)
    puts "[APP][#{Process.pid}] Writing #{object} to pipe."
    w.write(Marshal.dump(object) + DELIMITER)
  end

  puts "[APP][#{Process.pid}] ...done."
rescue => e
  puts "[APP][#{Process.pid}] CRASH!"
  raise
end
