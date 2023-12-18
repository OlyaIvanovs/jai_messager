main :: () {
    print("Client running...\n\n");
    wsa_data : WSAData;
    b1: u8 = 0x2;
    b2: u8 = 0x2;
    w : u16 = (cast(u16)b1) << 8 | cast(u16)b2;

     // Initialize Winsock
    wVersionRequested := w;
    res := WSAStartup(wVersionRequested, *wsa_data);

    result : *ADDRINFOA;
    hints : addrinfo;
    hints.ai_socktype = .SOCK_STREAM;
    hints.ai_protocol = .TCP;
    hints.ai_flags =  .PASSIVE;
    hints.ai_family = AF_INET;

    address_info := getaddrinfo(DEFAULT_SERVER_NODE, DEFAULT_CLIENT_PORT, *hints, *result);
    if address_info != 0 {
        print("getaddrinfo failed %\n", address_info);
        return;
    }

    // Create socket: socket exists in namespace, but it has no name assigned to it.
    client_socket := INVALID_SOCKET;
    client_socket = socket(result.ai_family, result.ai_socktype, result.ai_protocol);

    if client_socket == INVALID_SOCKET {
        print("socket failed\n");
        return;
    }
    defer closesocket(client_socket);

    // SERVER
    result_server : *ADDRINFOA;
    hints_server : addrinfo;
    hints_server.ai_socktype = .SOCK_STREAM;
    hints_server.ai_protocol = .TCP;
    hints_server.ai_flags =  .PASSIVE;
    hints_server.ai_family = AF_INET;

    address_info_server := getaddrinfo(DEFAULT_SERVER_NODE, DEFAULT_SERVER_PORT, *hints_server, *result_server);
    if address_info_server != 0 {
        print("getaddrinfo failed %\n", address_info_server);
        return;
    }

    if (connect(client_socket, result_server.ai_addr, xx result_server.ai_addrlen) == SOCKET_ERROR) {
        print("Error connecting to server: %\n", WSAGetLastError());
        return;
    }

    // Send messages to server
    msgs := string.["first", "second", "third"];

    recvbuf : [DEFAULT_BUFLEN]u8;
    for msgs {
        // Write to socket
        str := it;
        write := send(client_socket, str.data, xx str.count, 0);
        if write == SOCKET_ERROR {
            print("\nsend failed %\n", WSAGetLastError());
            return;
        }

        // Receive data from a connected socket
        // if no coming data is available at the socket, the recv call blocks and waits for data
        // to arrive according to the blocking rules

        read := recv(client_socket, recvbuf.data, xx recvbuf.count, 0);

        if read > 0 {
            str: string;
            str.data = recvbuf.data;
            str.count = read;
            print("Server's reply: %\n", str);
        } else if read == 0 {
            print("Connection closing.. \n");
        } else {
            print("recv failed %\n", WSAGetLastError());
        }

    }

    // Close
    WSACleanup();
}

DEFAULT_CLIENT_PORT :: "27015";
DEFAULT_SERVER_PORT :: "27016";
DEFAULT_SERVER_NODE :: "127.0.0.1";
DEFAULT_BUFLEN :: 1024;
SEGMENT_SIZE :: 32;

#import "Basic";
#import "Socket";