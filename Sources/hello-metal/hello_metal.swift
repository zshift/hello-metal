import MetalKit

let count: Int = 3000000

// Create our random arrays
var array1 = getRandomArray()
var array2 = getRandomArray()

func compute(arr1: [Float], arr2: [Float]) {

    let startTime = CFAbsoluteTimeGetCurrent()

    // The GPU we want to use
    let device = MTLCreateSystemDefaultDevice()

    // A FIFO queue for sending comands to the gpu
    let commandQueue = device?.makeCommandQueue()

    // A library for getting our metal functions
    var gpuFunctionLibrary: MTLLibrary!
    do {
        let url = Bundle.module.url(forResource: "compute", withExtension: "metal")
        let source = try String(contentsOf: url!)
        gpuFunctionLibrary = try device?.makeLibrary(source: source, options: nil)
    } catch  {
        print(error)
    }


    // Grab our gpu function
    let additionGpuFunction = gpuFunctionLibrary?.makeFunction(name: "addition_compute_function") // MUST match compute.metal

    var additionComputePipelineState: MTLComputePipelineState!
    do {
        additionComputePipelineState = try device?.makeComputePipelineState(function: additionGpuFunction!)
    } catch {
        print(error)
    }

    print()
    print("Compute")

    // Create the buffers to be sent to the gpu from our arrays
    let arr1Buff = device?.makeBuffer(bytes: arr1,
                                      length: MemoryLayout<Float>.size * count,
                                      options: .storageModeShared)

    let arr2Buff = device?.makeBuffer(bytes: arr2,
                                      length: MemoryLayout<Float>.size * count,
                                      options: .storageModeShared)

    let resultBuff = device?.makeBuffer(length: MemoryLayout<Float>.size * count,
                                        options: .storageModeShared)

    // Create a buffer to be sent to the command queue
    let commandBuffer = commandQueue?.makeCommandBuffer()

    // Create an encoder to set values on the compute function
    let commandEncoder = commandBuffer?.makeComputeCommandEncoder()
    commandEncoder?.setComputePipelineState(additionComputePipelineState)

    // set the parameters of our gpu function
    commandEncoder?.setBuffer(arr1Buff, offset: 0, index: 0)
    commandEncoder?.setBuffer(arr2Buff, offset: 0, index: 1)
    commandEncoder?.setBuffer(resultBuff, offset: 0, index: 2)

    // Figure out howmany threads we need to use for our operation
    let threadsPerGrid = MTLSize(width: count, height: 1, depth: 1)
    let maxThreadsPerThreadGroup = additionComputePipelineState.maxTotalThreadsPerThreadgroup
    let threadsPerThreadGroup = MTLSize(width: maxThreadsPerThreadGroup, height: 1, depth: 1)
    commandEncoder?.dispatchThreads(threadsPerGrid,
                                    threadsPerThreadgroup: threadsPerThreadGroup)

    // Tell the encoder that it is done encoding. Now we can send this off to the gpu.
    commandEncoder?.endEncoding()

    // Push this command to the command queue for processing
    commandBuffer?.commit()

    // wait until the gpu function completes before working with any of the data
    commandBuffer?.waitUntilCompleted()

    var resultBufferPointer = resultBuff?.contents().bindMemory(to: Float.self,
                                                                capacity: MemoryLayout<Float>.size * count)

    // Print out all of our new added together array information
    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(Float(resultBufferPointer!.pointee) as Any)")
        resultBufferPointer = resultBufferPointer?.advanced(by: 1)
    }

    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%0.5f", timeElapsed)) seconds")
}

func basicForLoop(arr1: [Float], arr2: [Float]) {
    print("Basic For Loop")

    let startTime = CFAbsoluteTimeGetCurrent()

    var result = [Float].init(repeating: 0.0, count: count)

    // Process our additions of the arrays together
    for i in 0..<count {
        result[i] = arr1[i] + arr2[i]
    }

    for i in 0..<3 {
        print("\(arr1[i]) + \(arr2[i]) = \(result[i])")
    }

    // Print out the elapsed time
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed \(String(format: "%.05f", timeElapsed)) seconds")

    print()
}

func getRandomArray() -> [Float] {
    var result: [Float] = []
    for _ in 0..<count {
        result.append(Float.random(in: 1.0..<100.0))
    }
    return result
}

@main
class App {
    static func main() {
        // craft our functions
        compute(arr1: array1, arr2: array2)
        basicForLoop(arr1: array1, arr2: array2)
    }
}