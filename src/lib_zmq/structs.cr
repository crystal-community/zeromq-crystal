lib LibZMQ
  struct Msg
    message : UInt8[64]
  end

  struct PollItem
    socket : Void*
    fd : LibC::Int
    events : LibC::Short
    revents : LibC::Short
  end
end
