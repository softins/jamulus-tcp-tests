# jamulus-tcp-tests

This repo contains some scripts for testing the Jamulus TCP implementation in the Pull Request https://github.com/jamulussoftware/jamulus/pull/3636 using firewall rules in Linux via `nft`. These are applicable to **Debian** and **Raspberry Pi OS**. Also to **Ubuntu**. Not sure about other linux distributions.

They could be included in the [main repo](https://github.com/jamulussoftware/jamulus) if desired, but they are primarily of use during the review process prior to merging.

The proposed TCP implementation uses TCP as a fallback (much like DNS does) when a large UDP message containing a server list or client list gets lost due to fragmentation. For most servers, which are small, it won't need to be enabled.

When TCP is enabled, the server will send a `CLM_TCP_SUPPORTED` message after the list of servers or clients. Where the list arrives intact, this will almost always happen before the `CLM_TCP_SUPPORTED` message arrives. The receiving Jamulus will not need to retry its request via TCP. If the `CLM_TCP_SUPPORTED` arrives when the expected list has not arrived, the client will then initiate a TCP connection to retry the request and fetch the list via a reliable transport.

In order to verify that the TCP fallback kicks in when needed, it is necessary to simulate the loss of an outgoing UDP server or client list. This can be done using `nft` firewall rules to drop specific packets. These scripts simplify those actions, and must be run on the same host as the server under test:

All the scripts output the new list of rules to confirm the current state.

### Enable nftables firewall

If necessary, install `nftables` with `sudo apt install nftables`.

If the `nft-list-rules.sh` script below does not output anything, it is probable that the `nftables` firewall has not been enabled or started.

- Start `nftables` with `sudo systemctl start nftables`

To make sure `nftables` is always started, do `sudo systemctl enable nftables`

### Show current ruleset

#### `nft-list-rules.sh`
Lists the current firewall rules:

```
$ ./nft-list-rules.sh
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
        }
}
```

The above shows no drop rules in place.

### Dropping OUTPUT messages

#### `nft-output-drop-client-list.sh`
Takes a server port number and drops (and logs) any UDP `CLM_CONN_CLIENTS_LIST` message sent by the server under test from that port. This will cause the client under test to initiate TCP to fetch the list.

```
$ ./nft-output-drop-client-list.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
                udp sport 22120 @ih,16,16 0xf503 log # handle 23
                udp sport 22120 @ih,16,16 0xf503 drop # handle 24
        }
}
```

#### `nft-output-drop-red-server-list.sh`
Takes a server port number and drops (and logs) any UDP `CLM_RED_SERVER_LIST` message sent by the directory server under test from that port. This doesn't cause any TCP operation, but does prevent the client from displaying a server list with reduced detail.

```
$ ./nft-output-drop-red-server-list.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
                udp sport 22120 @ih,16,16 0xfa03 log # handle 25
                udp sport 22120 @ih,16,16 0xfa03 drop # handle 26
        }
}
```

#### `nft-output-drop-server-list.sh`
Takes a server port number and drops (and logs) any UDP `CLM_SERVER_LIST` message sent by the directory server under test from that port. This will cause the client under test to initiate TCP to fetch the list.

```
$ ./nft-output-drop-server-list.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
                udp sport 22120 @ih,16,16 0xee03 log # handle 27
                udp sport 22120 @ih,16,16 0xee03 drop # handle 28
        }
}
```

#### `nft-output-drop-tcp-supported.sh`
Takes a server port number and drops (and logs) any UDP `CLM_TCP_SUPPORTED` message sent by the directory or server under test from that port. This can be used to observe the behaviour when the TCP connection cannot be initiated.

```
$ ./nft-output-drop-tcp-supported.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
                udp sport 22120 @ih,16,16 0xfb03 log # handle 29
                udp sport 22120 @ih,16,16 0xfb03 drop # handle 30
        }
}
```

#### `nft-output-delete-rules.sh`
Deletes one or more OUTPUT rules by specifying their handle numbers. For example starting from the rule list above:

```
$ ./nft-output-delete-rules.sh 29 30
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
        }
}
```

### Dropping input messages

#### `nft-input-drop-tcp-connect.sh`
Takes a server or directory port number and _drops_ any received TCP connection attempts. This should cause a timeout. Can be used to test the client behaviour when the server is not correctly receiving TCP connections.

```
$ ./nft-input-drop-tcp-connect.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
                tcp dport 22120 log # handle 31
                tcp dport 22120 drop # handle 32
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
        }
}
```

#### `nft-input-reject-tcp-connect.sh`
Takes a server or directory port number and _rejects_ any received TCP connection attempts. This should cause an immediate connection refused. Can be used to test the client behaviour when the server is not correctly receiving TCP connections.

```
$ ./nft-input-reject-tcp-connect.sh 22120
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
                tcp dport 22120 log # handle 33
                tcp dport 22120 reject # handle 34
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
        }
}
```

#### `nft-input-delete-rules.sh`
Deletes one or more INPUT rules by specifying their handle numbers. For example starting from the rule list above:

```
$ ./nft-input-delete-rules.sh 33 34
table inet filter { # handle 1
        chain input { # handle 1
                type filter hook input priority filter; policy accept;
        }

        chain forward { # handle 2
                type filter hook forward priority filter; policy accept;
        }

        chain output { # handle 3
                type filter hook output priority filter; policy accept;
        }
}
```

