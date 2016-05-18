@[Link("zmq")]
lib LibZMQ
  fun ctx_term = zmq_ctx_term(context : Void*) : LibC::Int
  fun ctx_shutdown = zmq_ctx_shutdown(ctx_ : Void*) : LibC::Int

  fun send_const = zmq_send_const(s : Void*, buf : Void*, len : LibC::SizeT, flags : LibC::Int) : LibC::Int

  fun z85_encode = zmq_z85_encode(dest : LibC::Char*, data : UInt8*, size : LibC::SizeT) : LibC::Char*
  fun z85_decode = zmq_z85_decode(dest : UInt8*, string : LibC::Char*) : UInt8*

  fun curve_keypair = zmq_curve_keypair(z85_public_key : LibC::Char*, z85_secret_key : LibC::Char*) : LibC::Int
end
