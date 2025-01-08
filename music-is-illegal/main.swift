/*
    Project Entry Point
 */

import Foundation

print("\(projectName) v(\(projectVersion))")

let client = EndpointSecurityClient()
client.start()

dispatchMain()
