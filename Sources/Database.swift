//
//  Database.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/9/17.
//
//

import Foundation
import MySQL
import Dispatch

class Database {
    typealias SQLView = [[String?]]
    let mysql: MySQL
    private let queue = DispatchQueue(label: "HomzSQL", attributes: .concurrent)


    init() {
        mysql = MySQL()
        guard
            let host = NewHomzAPI.shared.config?["db_host"] as? String,
            let port = (NewHomzAPI.shared.config?["db_port"] as? String)?.intValue,
            let username = NewHomzAPI.shared.config?["db_username"] as? String,
            let password = NewHomzAPI.shared.config?["db_password"] as? String,
            let database = NewHomzAPI.shared.config?["db_name"] as? String else {
                NSLog("No database credentials provided. Game over, man.")
                return
        }
        guard mysql.connect(host: host, user: username, password: password, db: database, port: UInt32(port)) else {
            NSLog("Unable to connect to database")
            return
        }
    }
    
    func performQuery(statement: String, completion: @escaping (SQLView?)->()) {
        let mysql = self.mysql
        queue.sync {
            guard
                mysql.query(statement:statement),
                let resultsPointer = mysql.storeResults() else {
                    completion(nil)
                    return
            }
            var view = SQLView()
            resultsPointer.forEachRow(callback: { row in
                view.append(row)
            })
            completion(view)
        }
    }

    deinit {
        mysql.close()
    }

}
