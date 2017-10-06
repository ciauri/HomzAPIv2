//
//  InitializationResource.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 9/16/17.
//

import Foundation
import PerfectHTTP
import PerfectLib

class InitializationResource {
    static let initRoute = Route(method: .get, uri: "/", handler: initHandler)
    
    class func initHandler(request: HTTPRequest, response: HTTPResponse) {
        response.setHeader(.contentType, value: "application/json")
//        response.setHeader(.cacheControl, value: "max-age=86400")
        
        let encoded = try! NewHomzAPI.shared.jsonEncoder.encode(Initialization())

        response.appendBody(string: String(data: encoded, encoding: .utf8)!)
        
        response.completed(status: .ok)
    }
}

extension InitializationResource: Resource {
    class var routes: [Route] {
        return [initRoute]
    }
    
    class var rootRoutes: [Route] {
        return routes
    }
}
