
begin
  puts "[WORKER][#{Process.pid}] Starting..."

  DELIMITER = "*DD_DELIM*"
  Span = Struct.new(:name, :span_id)

  6.times do |i|
    sleep(2)
    puts "[WORKER][#{Process.pid}] Reading from pipe... "
    line = STDIN.gets(DELIMITER)
    puts "[WORKER][#{Process.pid}] #{line.bytes.to_a}" if line
    object = !line.nil? && !line.empty? ? Marshal.load(line) : nil
    puts "[WORKER][#{Process.pid}] #{object}" if object
  end
  puts "[WORKER][#{Process.pid}] ...done."
rescue => e
  puts "[WORKER][#{Process.pid}] CRASH!"
  raise
end
