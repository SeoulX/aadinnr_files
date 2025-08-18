#### Client & Server Relationship
- **Client** - gives requests
- **Server** - fulfill the request of the client
#### Network Concepts
- **IP** - A unique string of numbers separated by periods that identifies each computer using the Internet Protocol to communicate over a network.
	- - Types:
	    - **IPv4**: 32-bit (e.g., `192.168.1.1`)
	    - **IPv6**: 128-bit (e.g., `2001:0db8:85a3::8a2e:0370:7334`)
	- **Private IP**: Used within local networks.
	- **Public IP**: Used on the internet.
- **Subnet Mask** - is a 32-bit number that masks an IP address, and divides the IP address into network address and host address. Subnet Mask is made by setting the network bits to all "1"s and setting host bits to all "0"s.
	- Example: `192.168.1.0/24` means 256 IP addresses.

| Address Class | Bits for Subnet Mask                | Subnet Mask   |
| ------------- | ----------------------------------- | ------------- |
| Class A       | 11111111 00000000 00000000 00000000 | 255.0.0.0     |
| Class B       | 11111111 11111111 00000000 00000000 | 255.255.0.0   |
| Class C       | 11111111 11111111 11111111 00000000 | 255.255.255.0 |

| CIDR  | Subnet Mask     | Total IPs  | Usable IPs\* | Common Use                                   |
| ----- | --------------- | ---------- | ------------ | -------------------------------------------- |
| `/8`  | 255.0.0.0       | 16,777,216 | 16,777,214   | Very large private networks (10.x.x.x range) |
| `/16` | 255.255.0.0     | 65,536     | 65,534       | VPC ranges in AWS / Large internal networks  |
| `/24` | 255.255.255.0   | 256        | 254          | Typical home or office LAN subnet            |
| `/22` | 255.255.252.0   | 1,024      | 1,022        | Kubernetes Pod/Service ranges                |
| `/20` | 255.255.240.0   | 4,096      | 4,094        | Large subnet for staging/dev servers         |
| `/30` | 255.255.255.252 | 4          | 2            | Point-to-point router links                  |
| `/32` | 255.255.255.255 | 1          | 1            | Single host (firewall rules, routes)         |

- **Media Access Control (MAC) Address** - Unique hardware address of the network interface card (NIC).
	- Example: `00:1A:2B:3C:4D:5E`
- **Gateway** - a device or software that connects two networks using different protocols, acting as a bridge for data to flow between them. 
- **Static** - IP Address that doesn't change.
	- Often used for servers, routers and other devices requires consistent and reliable access.
- **Dynamic (DHCP)** - IP Address that is temporarily assigned to a device by a DHCP Server and can change each time the device connects to the network.
- **DNS** - translate domain names into IP Addresses.
	- without DNS, we need to remember IPs.
- **Protocols**
	- - **TCP/IP**: Core communication protocol for the internet.
	- **HTTP/HTTPS**: Web traffic.
	- **FTP/SFTP**: File transfer.
	- **SMTP/IMAP/POP3**: Email protocols.
	- **DNS**: Translates domain names to IP addresses.
	- **DHCP**: Assigns IP addresses automatically.
- **Ports**
	- 80 → HTTP
	- 443 → HTTPS
	- 22 → SSH
	- 25 → SMTP
	- 53 → DNS
- **OSI Model (7 Layers)**
	- **Physical** – Cables, switches
	- **Data Link** – MAC addresses, Ethernet
	- **Network** – IP addressing, routing
	- **Transport** – TCP/UDP
	- **Session** – Managing communication sessions
	- **Presentation** – Encryption, compression
	- **Application** – End-user services (HTTP, FTP)
- **Routing & Switching**
	- **Router**: Connects different networks, directs traffic.
	- **Switch**: Connects devices in the same network (LAN).
	- **Gateway**: Acts as a bridge between networks.
- **Firewalls & Security**
	- **Firewall**: Filters network traffic.
	- **VPN**: Encrypts network traffic over public networks.
	- **NAT (Network Address Translation)**: Maps private IPs to a public IP.

