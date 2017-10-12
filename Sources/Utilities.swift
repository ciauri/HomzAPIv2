//
//  Utilities.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectMySQL
import PerfectLib
import PerfectHTTP

extension Dictionary {
    static func combining(keyArray keys: [String], valueArray values: [String?]) -> [String:String] {
        precondition(keys.count == values.count)
        var dict = [String:String]()
        for (index, key) in keys.enumerated() {
            dict[key] = values[index]
        }
        return dict
    }  
}


/// Combining two dictionaries
///
/// - Parameters:
///   - left: dictionary to be added to
///   - right: dictionary to be merged
func += <K, V> ( left: inout [K:V], right: [K:V]) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

extension Array where Element == (String,String) {
    var toDictionary: [String:String] {
        var dict: [String:String] = [:]
        forEach({ (key,value) in
            dict[key] = value
        })
        return dict
    }
}


// MARK: - Makes dealing with json/optionals much cleaner
extension String {
    var intValue: Int? {
        return Int(self)
    }
    
    var floatValue: Float? {
        return Float(self)
    }
    
    var doubleValue: Double? {
        return Double(self)
    }
    
    var urlValue: URL? {
        return URL(string: self)
    }
}

extension HTTPResponse {
    func appendBody(jsonRepresentable object: JSONConvertible) {
        do {
            let json = try object.jsonEncodedString()
            appendBody(string: json)
        } catch JSONConversionError.notConvertible(_) {
            NSLog("not convertible?")
        } catch JSONConversionError.invalidKey(_) {
            NSLog("invalid key?")
        } catch JSONConversionError.syntaxError {
            NSLog("syntax?!")
        } catch {
            NSLog("unknown")
        }
    }
    
    func appendBody<T: Encodable>(encodable object: T) throws {
        let encoded = try NewHomzAPI.shared.jsonEncoder.encode(object)
        guard let encodedString = String(data: encoded, encoding: .utf8) else {
            throw JSONConversionError.notConvertible(encoded)
        }
        appendBody(string: encodedString)
    }
}

extension Route {
    var absoluteURLString: String {
        return NewHomzAPI.shared.baseURL.absoluteString.appending("\(self.uri)")
    }
}

extension URL : JSONConvertible {
    public func jsonEncodedString() throws -> String {
        return try self.absoluteString.jsonEncodedString()
    }
}


struct MapRegion: CustomStringConvertible {
    var description: String { return "Lat: \(latitudeBegin) - \(latitudeEnd). Long: \(longitudeBegin) - \(longitudeEnd)"}
    var latitudeBegin: Double
    var latitudeEnd: Double
    var longitudeBegin: Double
    var longitudeEnd: Double
}

struct Coordinate: Codable {
    public let latitude: Double
    public let longitude: Double
}

struct NumberRange: Codable {
    public let min: Float
    public let max: Float
    
    public var rangeString: String {
        return "\(min) - \(max)"
    }
    
    public var intRangeString: String {
        return "\(Int(min)) - \(Int(max))"
    }
}
