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
        do {
            try response.appendBody(encodable: Initialization())
        } catch {
            NSLog("Failed to serialize listings")
            response.completed(status: .internalServerError)
            return
        }
        
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
