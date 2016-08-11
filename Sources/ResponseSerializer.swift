// ResponseSerializer.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

public struct ResponseSerializer: AsyncResponseSerializer {
    
    let transport: AsyncStream
    
    public init(stream: AsyncStream) {
        self.transport = stream
    }

    public func serialize(_ response: Response, completion: @escaping ((Void) throws -> Void) -> Void = { _ in }){
        let newLine: Data = [13, 10]

        transport.send("HTTP/\(response.version.major).\(response.version.minor) \(response.status.statusCode) \(response.status.reasonPhrase)".data)
        transport.send(newLine)

        for (name, value) in response.headers.headers {
            transport.send("\(name): \(value)".data)
            transport.send(newLine)
        }

        for cookie in response.cookies {
            transport.send("Set-Cookie: \(cookie)".data)
            transport.send(newLine)
        }

        transport.send(newLine)

        switch response.body {
        case .buffer(let buffer):
            self.transport.send(buffer)
            completion{}
        case .asyncReceiver(let receiver):
            receiver.receive(upTo: 2014) { result in
                do {
                    let data = try result()
                    self.transport.send(String(data.count, radix: 16).data)
                    self.transport.send(newLine)
                    self.transport.send(data)
                    self.transport.send(newLine)
                    if receiver.closed {
                        self.transport.send("0".data)
                        self.transport.send(newLine)
                        self.transport.send(newLine)
                        completion{}
                    }
                } catch {
                  completion {
                      throw error
                  }
                }
            }
        case .asyncSender(let sender):
            let body = AsyncBodyStream(transport)
            sender(body) { result in
                do {
                    try result()
                    self.transport.send("0".data)
                    self.transport.send(newLine)
                    self.transport.send(newLine)
                    completion{}
                } catch {
                  completion {
                      throw error
                  }
                }
            }
        default:
            completion {
                throw BodyError.inconvertibleType
            }
        }

        transport.flush()
    }
}
