//
//  Package.swift
//  NewHomzAPI
//
//  Created by stephenciauri on 4/8/17.
//
//


import PackageDescription

let package = Package(
	name: "NewHomzAPI",
	targets: [],
	dependencies: [
		.Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2),
        .Package(url:"https://github.com/PerfectlySoft/Perfect-MySQL.git", majorVersion: 2, minor: 0)
    ]
)
