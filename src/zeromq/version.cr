module ZMQ
  VERSION = "0.2.13"

  def self.version
    LibZMQ.version(out major, out minor, out patch)
    {major: major, minor: minor, patch: patch}
  end
end
