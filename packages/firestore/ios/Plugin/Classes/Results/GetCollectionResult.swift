import Foundation
import FirebaseFirestore
import Capacitor

@objc public class GetCollectionResult: NSObject, Result {
    let querySnapshot: QuerySnapshot
    init(_ querySnapshot: QuerySnapshot) {
        self.querySnapshot = querySnapshot
    }
    
    public func toJSObject() -> AnyObject {
        var snapshotsResult = JSArray()
        for documentSnapshot in querySnapshot.documents {
            let originalData = documentSnapshot.data()
            let sanitizedData = sanitizeSpecialValues(originalData)

            let snapshotDataResult = FirebaseFirestoreHelper.createJSObjectFromHashMap(sanitizedData)
            var snapshotResult = JSObject()
            snapshotResult["id"] = documentSnapshot.documentID
            snapshotResult["path"] = documentSnapshot.reference.path
            
            if let snapshotDataResult = snapshotDataResult {
                snapshotResult["data"] = snapshotDataResult
            } else {
                snapshotResult["data"] = NSNull()
            }
            
            var metadata = JSObject()
            metadata["fromCache"] = documentSnapshot.metadata.isFromCache
            metadata["hasPendingWrites"] = documentSnapshot.metadata.hasPendingWrites
            snapshotResult["metadata"] = metadata
            
            snapshotsResult.append(snapshotResult)
        }
        
        var result = JSObject()
        result["snapshots"] = snapshotsResult
        return result as AnyObject
    }
    
    private func sanitizeSpecialValues(_ dictionary: [String: Any]) -> [String: Any] {
        var sanitizedDictionary = dictionary
        
        for (key, value) in dictionary {
            sanitizedDictionary[key] = sanitizeValue(value)
        }
        
        return sanitizedDictionary
    }
    
    private func sanitizeValue(_ value: Any) -> Any {
        switch value {
        case let number as NSNumber:
            if number.doubleValue.isInfinite || number.doubleValue.isNaN {
                return NSNull()
            }
            return number
            
        case let dict as [String: Any]:
            return sanitizeSpecialValues(dict)
            
        case let array as [Any]:
            return array.map { sanitizeValue($0) }
            
        default:
            return value
        }
    }
}
