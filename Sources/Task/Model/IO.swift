import Foundation

public final class IO {
    // MARK: - Properties
    public var input: Channel = .standardInput()
    public var output: Channel = .standardOutput()
    public var error: Channel = .standardError()
    
    public private(set) var readOutputData: Data?
    public private(set) var readErrorData: Data?

    // MARK: - Convenience
    public func enableReadableOutputDataCapturing() {
        readOutputData = Data()
        output = .pipe()
        output.readabilityHandler = { handle in
            handle.withAvailableData { available in
                self.readOutputData?.append(available)
            }
        }
    }
    
    public func enableErrorOutputCapturing() {
        readErrorData = Data()
        error = .pipe()
        error.readabilityHandler = { handle in
            handle.withAvailableData { available in
                self.readErrorData?.append(available)
            }
        }
    }

}

