module ZMQ
  VERSION = "0.2.1"

  def self.version
    LibZMQ.version(out major, out minor, out patch)
    {major: major, minor: minor, patch: patch}
  end
end
