//
//  Serialization.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//

import Foundation
import PerfectHTTP

// Haven't figured out what i'm going to do with you yet
protocol RESTEntity {
    var links: [String:URL] { get }
    var href: URL? { get }
}

protocol Resource {
    static var routes: [Route] { get }
    static var rootRoutes: [Route] { get }
}
