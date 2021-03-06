module Degzipper
  class Middleware
    def initialize(app)
      @app = app
    end

    def method_handled?(env)
      !!(env['REQUEST_METHOD'] =~ /(POST|PUT|PATCH)/)
    end

    def encoding_handled?(env)
      ['gzip', 'deflate'].include? env['HTTP_CONTENT_ENCODING']
    end

    def path_in?(env)
      !!(env['PATH_INFO'] =~ /api/)
    end

    def call(env)
      if method_handled?(env) && encoding_handled?(env) && path_in?(env)
        extracted = decode(env['rack.input'], env['HTTP_CONTENT_ENCODING'])

        env.delete('HTTP_CONTENT_ENCODING')
        env['CONTENT_LENGTH'] = extracted.bytesize
        env['rack.input'] = StringIO.new(extracted)
      end

      status, headers, response = @app.call(env)
      return [status, headers, response]
    end

    def decode(input, content_encoding)
      case content_encoding
        when 'gzip' then Zlib::GzipReader.new(input).read
        when 'deflate' then Zlib::Inflate.inflate(input.read)
      end
    end
  end
end
