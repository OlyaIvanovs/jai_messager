main :: () {
    print("Server is running ...");

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

    address_info := getaddrinfo(DEFAULT_SERVER_NODE, DEFAULT_SERVER_PORT, *hints, *result);
    if address_info != 0 {
        print("getaddrinfo failed %\n", address_info);
        return;
    }

    // Create socket: socket exists in namespace, but it has no name assigned to it.
    listen_socket := INVALID_SOCKET;
    listen_socket = socket(result.ai_family, result.ai_socktype, result.ai_protocol);
    defer closesocket(listen_socket);

    if listen_socket == INVALID_SOCKET {
        print("socket failed\n");
        return;
    }


    // Bind to establish the local association of the socket by assigning a local name to an unnamed socket.
    // Name = address family + host address + port number
    // Client applications use the IP address and port to connect to the host network.

    // Bind the listening socket using theinformation in the sockaddr structure
    r := bind(listen_socket, result.ai_addr, xx result.ai_addrlen);
    if r < 0 {
        print("bind failed \n");
        freeaddrinfo(result);
        return;
    }



    // Listen
    if listen(listen_socket, SOMAXCONN) == SOCKET_ERROR {
        print("listen failed with error: %", WSAGetLastError());
        return;
    }

    while true {
        client_socket := INVALID_SOCKET;
        client_socket = accept(listen_socket, null, null);
        if client_socket == INVALID_SOCKET {
            print("accept failed \n");
            return;
        }

        recvbuf : [DEFAULT_BUFLEN]u8;

        while true {
            read := recv(client_socket, recvbuf.data, xx recvbuf.count, 0);

            if read > 0 {
                str: string;
                str.data = recvbuf.data;
                str.count = read;

                print("\n str % \n", str);
                write := send(client_socket, str.data, xx str.count, 0);
                if write == SOCKET_ERROR {
                    print("send failed %\n", WSAGetLastError());
                }
                // free(str);
            } else if read == 0 {
                print("Connection closing.. \n");
                break;
            } else {
                print("recv failed %\n", WSAGetLastError());
                break;
            }
        }
    }


    // Close
    WSACleanup();

}

DEFAULT_SERVER_PORT :: "27016";
DEFAULT_SERVER_NODE :: "127.0.0.1";
DEFAULT_BUFLEN :: 1024;
SEGMENT_SIZE :: 32;

#import "Basic";
#import "Socket";