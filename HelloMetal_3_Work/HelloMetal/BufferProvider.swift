//
//  BufferProvider.swift
//  HelloMetal
//
//  Created by MJ.KONG-MAC on 2020/11/25.
//  Copyright © 2020 razeware. All rights reserved.
//

import Foundation
import Metal

class BufferProvider: NSObject {
    // 1
    let inflightBufferCount: Int
    // 2
    private var uniformsBuffers: [MTLBuffer]
    // 3
    private var availableBufferIndex: Int = 0
    // 4
    var availableResourcesSemaphore: DispatchSemaphore
    
    init(device: MTLDevice, inflightBufferCount: Int, sizeOfUniformsBuffer: Int) {
        self.inflightBufferCount = inflightBufferCount
        uniformsBuffers = [MTLBuffer]()
        
        for _ in 0...inflightBufferCount-1 {
            let uniformsBuffer = device.makeBuffer(length: sizeOfUniformsBuffer, options: [])!
            uniformsBuffers.append(uniformsBuffer)
        }
        
        availableResourcesSemaphore = DispatchSemaphore(value: inflightBufferCount)
    }
    
    deinit {
        for _ in 0...self.inflightBufferCount {
            self.availableResourcesSemaphore.signal()
        }
    }
    
    func nextUniformsBuffer(projectionMatrix: Matrix4, modelViewMatrix: Matrix4) -> MTLBuffer {
        // 1
        let buffer = uniformsBuffers[availableBufferIndex]
        // 2
        let bufferPointer = buffer.contents()
        // 3
        memcpy(bufferPointer, modelViewMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        memcpy(bufferPointer + MemoryLayout<Float>.size * Matrix4.numberOfElements(),
               projectionMatrix.raw(), MemoryLayout<Float>.size * Matrix4.numberOfElements())
        // 4
        availableBufferIndex += 1
        if availableBufferIndex == inflightBufferCount {
            availableBufferIndex = 0
        }
        
        return buffer
    }
}
