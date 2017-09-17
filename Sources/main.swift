//
//  main.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import Foundation

class NewHomzAPI {
    static let shared = NewHomzAPI()
    private(set) var server: HTTPServer
    private(set) var baseURL: URL
    private let baseUri = "/v1"
    private(set) var config: [String:Any]?
    
    init() {
        var routes = Routes(baseUri: baseUri)
        routes.add(ListingResource.routes)
        routes.add(BuilderResource.routes)
        routes.add(InitializationResource.routes)
        
        
        
        server = HTTPServer()
        server.addRoutes(routes)
        server.serverPort = 8181
        server.serverName = Host.current().name ?? ""
        
        baseURL = URL(string: "http://\(server.serverName):\(server.serverPort != 80 ? server.serverPort : 80)\(baseUri)")!
    }
    
    private func loadConfig() {
        if let configArgIndex = CommandLine.arguments.index(of: "-config"), CommandLine.arguments.count > configArgIndex + 1 {
            let configFilePath = CommandLine.arguments[configArgIndex + 1]
            var urlString: String
            
            // Supporting both relative and absolute paths
            if configFilePath.characters.first == "/" {
                urlString = configFilePath
            } else {
                urlString = FileManager.default.currentDirectoryPath.appending("/"+configFilePath)
            }
            
            // Had to go this route in the name of Linux compatibility. Otherwise, NSDictionary(contentsOfFile:) would have been the way to go
            NSLog("Reading config file from \(urlString)")
            if
                let url = URL(string: "file://\(urlString)"),
                let data = try? Data(contentsOf: url) {
                if let result = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] { // [String: Any] which ever it is
                    config = result
                }
            }
            
            guard let config = config else { return }
            
            if let hostname = config["hostname"] as? String {
                server.serverName = hostname
            }
            if let port = (config["port"] as? String)?.intValue {
                server.serverPort = UInt16(port)
            }
            baseURL = URL(string: "http://\(server.serverName):\(server.serverPort != 80 ? server.serverPort : 80)\(baseUri)")!
        }
    }
    
    class func start() {
        do {
            shared.loadConfig()
            try shared.server.start()
        } catch PerfectError.networkError(let err, let msg) {
            print("OOPS: \(err)-\(msg)")
        } catch {
            print("Other error: \(error)")
        }
    }

    
}

NewHomzAPI.start()

