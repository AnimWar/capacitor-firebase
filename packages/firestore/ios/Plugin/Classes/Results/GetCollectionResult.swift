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
            let sanitizedData = sanitizeNaNValues(originalData)
            
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
    
    private func sanitizeNaNValues(_ dictionary: [String: Any]) -> [String: Any] {
        var sanitizedDictionary = dictionary
        
        for (key, value) in dictionary {
            if let number = value as? NSNumber, number.floatValue.isNaN {
                sanitizedDictionary[key] = NSNull()
            } else if let nestedDict = value as? [String: Any] {
                sanitizedDictionary[key] = sanitizeNaNValues(nestedDict)
            } else if let array = value as? [Any] {
                sanitizedDictionary[key] = sanitizeNaNArray(array)
            }
        }
        
        return sanitizedDictionary
    }
    
    private func sanitizeNaNArray(_ array: [Any]) -> [Any] {
        return array.map { item in
            if let number = item as? NSNumber, number.floatValue.isNaN {
                return NSNull()
            } else if let nestedDict = item as? [String: Any] {
                return sanitizeNaNValues(nestedDict)
            } else if let nestedArray = item as? [Any] {
                return sanitizeNaNArray(nestedArray)
            }
            return item
        }
    }
}
