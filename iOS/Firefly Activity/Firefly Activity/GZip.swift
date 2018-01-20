//
//  GZip.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/18/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation
import zlib

class GZip {
    
    enum LocalError: Error {
        case deflate(Int32)
        case inflate(Int32)
    }
    
    static func hasGZipMagicHeader(data: Data) -> Bool {
        return data.starts(with: [0x1f, 0x8b])
    }
    
    static func newStream(data: Data) -> z_stream {
        var stream = z_stream()
        data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            stream.next_in = UnsafeMutablePointer<UInt8>(mutating: bytes)
        }
        stream.avail_in = uint(data.count)
        return stream
    }
    
    static func compress(data: Data) throws -> Data {
        var stream = newStream(data: data)
        
        var status = deflateInit2_(&stream, Z_BEST_COMPRESSION, Z_DEFLATED, MAX_WBITS + 16, MAX_MEM_LEVEL, Z_DEFAULT_STRATEGY, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        if status != Z_OK {
            throw LocalError.deflate(status)
        }
        
        let block = 2^14
        var compressedData = Data(capacity: block)
        while stream.avail_out == 0 {
            if Int(stream.total_out) >= compressedData.count {
                compressedData.count += block
            }
            compressedData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(data.count) - uInt(stream.total_out)
            status = deflate(&stream, Z_FINISH)
        }
        deflateEnd(&stream)
        if status != Z_STREAM_END {
            throw LocalError.deflate(status)
        }
        compressedData.count = Int(stream.total_out)
        
        return compressedData
    }
    
    static func decompress(data: Data) throws -> Data {
        var stream = newStream(data: data)
        
        var status = inflateInit2_(&stream, MAX_WBITS + 32, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        if status != Z_OK {
            throw LocalError.inflate(status)
        }
        var decompressedData = Data(capacity: data.count * 2)
        repeat {
            if Int(stream.total_out) >= decompressedData.count {
                decompressedData.count += data.count / 2
            }
            decompressedData.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
                stream.next_out = bytes.advanced(by: Int(stream.total_out))
            }
            stream.avail_out = uInt(decompressedData.count) - uInt(stream.total_out)
            status = inflate(&stream, Z_SYNC_FLUSH)
        } while status == Z_OK
        inflateEnd(&stream)
        if status != Z_STREAM_END {
            throw LocalError.deflate(status)
        }
        decompressedData.count = Int(stream.total_out)
        
        return decompressedData
    }
    
}
