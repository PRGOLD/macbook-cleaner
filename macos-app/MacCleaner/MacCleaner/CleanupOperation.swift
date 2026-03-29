import Foundation

/// Protocol that all cleanup operations conform to
protocol CleanupOperation {
    /// The unique identifier for this operation
    var id: String { get }
    
    /// Human-readable name for this operation
    var name: String { get }
    
    /// Description of what this operation does
    var description: String { get }
    
    /// Executes the cleanup operation
    func execute() async throws -> CleanupResult
}

/// Default implementations
extension CleanupOperation {
    var id: String { String(describing: type(of: self)) }
}
