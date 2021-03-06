#
# Sniffer is a very dumb wrapper to start and stop tcpdumps instances, possibly
# with customized filters. Captured traffic is stored in files whose name
# depends on the sniffer name. The resulting captured packets for each sniffers
# can be accessed as an array through its `packets` method.
#
# Use of more rubyish internal ways to sniff a network like with pcap-able gems
# is waaay to much resource consumming, notmuch reliable and soooo slow. Let's
# not bother too much with that. :)
#
# Should put all that in a Module.

class Sniffer

  attr_reader :name, :pcap_file, :pid

  def initialize(name, vmnet)
    @name = name
    @vmnet = vmnet
    pcap_name = sanitize_filename("#{name}.pcap")
    @pcap_file = "#{$config["TMPDIR"]}/#{pcap_name}"
  end

  def capture(filter="not ether src host #{@vmnet.bridge_mac} and not ether proto \\arp and not ether proto \\rarp")
    job = IO.popen(
      [
        "/usr/sbin/tcpdump",
        "-n",
        "-U",
        "--immediate-mode",
        "-i", @vmnet.bridge_name,
        "-w", @pcap_file,
        filter,
        :err => ["/dev/null", "w"]
      ]
    )
    @pid = job.pid
  end

  def stop
    begin
      Process.kill("TERM", @pid)
    rescue
      # noop
    end
  end

  def clear
    if File.exist?(@pcap_file)
      File.delete(@pcap_file)
    end
  end
end
