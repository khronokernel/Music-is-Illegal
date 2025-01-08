/*
    Endpoint Security Client
    ------------------------
    Heavily based on Brandon7CC's ESClient.swift:
    - https://github.com/Brandon7CC/mac-wheres-my-bootstrap

    Apple Reference Documentation:
    - https://developer.apple.com/documentation/endpointsecurity
 */

import Foundation
import EndpointSecurity


class EndpointSecurityClient: NSObject {

    var endpointClient: OpaquePointer?

    /*
        Start Endpoint Security client
    */
    public func start() {
        self.endpointClient = initializeEndpointClient()
    }


    /*
        Stop Endpoint Security client
    */
    public func stop() {
        es_delete_client(self.endpointClient)
    }

    /*
        Convert es_event_exec_t arguments to Swift array of strings

        - Parameters:
            - event: es_event_exec_t event

        - Returns: Array of strings
    */
    private func esEventArguments(event: inout es_event_exec_t) -> [String] {
        return (0 ..< Int(es_exec_arg_count(&event))).map {
            String(cString: es_exec_arg(&event, UInt32($0)).data)
        }
    }


    /*
        Process Endpoint Security event

        - Parameters:
            - event: UnsafePointer<es_message_t> event
    */
    private func processEvent(event: UnsafePointer<es_message_t>) {
        if event.pointee.event_type != ES_EVENT_TYPE_AUTH_EXEC {
            return
        }

        let executablePath = String(cString: event.pointee.process.pointee.executable.pointee.path.data)
        if executablePath != "/usr/libexec/xpcproxy" {
            es_respond_auth_result(self.endpointClient!, event, ES_AUTH_RESULT_ALLOW, true)
            return
        }

        var mutableEvent = event.pointee.event.exec
        let arguments = esEventArguments(event: &mutableEvent)

        if arguments.count < 1 {
            es_respond_auth_result(self.endpointClient!, event, ES_AUTH_RESULT_ALLOW, true)
            return
        }

        if arguments[0] != "/System/Applications/Music.app/Contents/MacOS/Music" {
            es_respond_auth_result(self.endpointClient!, event, ES_AUTH_RESULT_ALLOW, true)
            return
        }

        print("Apple Music launch event detected! Rejecting authorization...")
        es_respond_auth_result(self.endpointClient!, event, ES_AUTH_RESULT_DENY, true)
    }


    /*
        Determine error upon creating a new Endpoint Security client

        - Parameters:
            - result: es_new_client_result_t result

        - Returns: String message
    */
    private func processNewClientCreation(result: es_new_client_result_t) -> String {
        var message: String = ""
        switch result {
            case ES_NEW_CLIENT_RESULT_ERR_TOO_MANY_CLIENTS:
                message = "More than 50 Endpoint Security clients are connected!"
                break
            case ES_NEW_CLIENT_RESULT_ERR_NOT_ENTITLED:
                message = "Executable is missing com.apple.developer.endpoint-security.client entitlement!"
                break
            case ES_NEW_CLIENT_RESULT_ERR_NOT_PERMITTED:
                message = "Parent is missing Full Disk Access permission!"
                break
            case ES_NEW_CLIENT_RESULT_ERR_NOT_PRIVILEGED:
                message = "Parent is not running as root!"
                break
            case ES_NEW_CLIENT_RESULT_ERR_INTERNAL:
                message = "Internal Endpoint Security error!"
                break
            case ES_NEW_CLIENT_RESULT_ERR_INVALID_ARGUMENT:
                message = "Incorrect arguments to create Endpoint Security client!"
                break
            case ES_NEW_CLIENT_RESULT_SUCCESS:
                break
            default:
                message = "An unknown error occurred while creating a new Endpoint Security client!"
        }

        return message
    }


    /*
        Initialize Endpoint Security client

        - Returns: OpaquePointer to Endpoint Security client
    */
    private func initializeEndpointClient() -> OpaquePointer? {
        var client: OpaquePointer?

        let initResult: es_new_client_result_t = es_new_client(&client){ _, event in
            self.processEvent(event: event)
        }

        let message = processNewClientCreation(result: initResult)
        if message != "" {
            print(message)
            exit(EXIT_FAILURE)
        }

        let subsriptions = [
            ES_EVENT_TYPE_AUTH_EXEC
        ]

        if es_subscribe(client!, subsriptions, UInt32(subsriptions.count)) != ES_RETURN_SUCCESS {
            print("Failed to subscribe to ES_EVENT_TYPE_AUTH_EXEC event!")
            es_delete_client(client)
            exit(EXIT_FAILURE)
        }

        return client
    }
}
