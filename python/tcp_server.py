# tcpserver.py
 
from socket import *
 
#host = '3.138.190.214'
host = ''
port = 8888
 
tcp_server_socket = socket(AF_INET,SOCK_STREAM)
 
server_addr = (host,port)
tcp_server_socket.bind(server_addr)
 
tcp_server_socket.listen(128)
 
try:
    while True:
        print('waiting for connect...')
        
        client_socket, client_addr = tcp_server_socket.accept()
        
        print('a client connnect from:', client_addr)
 
        while(True):
            
            client_socket.send('Hello, client!'.encode())
 
            
            data = client_socket.recv(1024)
            print('recv data is ', data.decode())
 
            
            if "quit" in data.decode():
                break
        
        
        client_socket.close()
        server_socket.close()
        print("socket closed.")
        break
except:
    client_socket.close()
    server_socket.close()
    print("socket closed.")
