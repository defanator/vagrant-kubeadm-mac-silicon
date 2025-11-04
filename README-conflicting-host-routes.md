
# Conflicting host routes affecting pods communications

With the following interfaces being up on a VM launched from vagrant with vmware provider -

```
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.99.99.142  netmask 255.255.255.0  broadcast 10.99.99.255
        inet6 fe80::20c:29ff:fef3:e866  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:f3:e8:66  txqueuelen 1000  (Ethernet)
        RX packets 658090  bytes 719564688 (686.2 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 209357  bytes 64667807 (61.6 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 23  memory 0x3fe00000-3fe20000

eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.99.99.10  netmask 255.255.255.0  broadcast 10.99.99.255
        inet6 fe80::20c:29ff:fef3:e870  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:f3:e8:70  txqueuelen 1000  (Ethernet)
        RX packets 20794  bytes 1403061 (1.3 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 469  bytes 175047 (170.9 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
        device interrupt 30  memory 0x3fb00000-3fb20000
```

we have 2 conflicting / duplicate routes for the same host subnet:

```
[root@controlplane network-scripts]# ip route show | grep -- '10.99.99.0/24'
10.99.99.0/24 dev eth0 proto kernel scope link src 10.99.99.142
10.99.99.0/24 dev eth1 proto kernel scope link src 10.99.99.10
```

This leads to the fact that communication between nodes (control IPs are tied to eth1) is happening in fact through eth0:

```
[root@controlplane network-scripts]# ip route get 10.99.99.11
10.99.99.11 dev eth0 src 10.99.99.142 uid 0
    cache
[root@controlplane network-scripts]# ip route get 10.99.99.12
10.99.99.12 dev eth0 src 10.99.99.142 uid 0
    cache
```

(10.99.99.11 is node01 and 10.99.99.12 is node02 in the above example; similar routes are in place on nodes themselves)

This, in turn, makes it impossible for pods to be able to communicate to each other across the different nodes.

Removing net route via eth0 "fixes" the issue:

```
root@node02:/home/vagrant# ip route del 10.99.99.0/24 dev eth0
root@node02:/home/vagrant# ip route show
default via 10.99.99.2 dev eth0
10.99.99.0/24 dev eth1 proto kernel scope link src 10.99.99.12
172.20.49.64/26 via 10.99.99.10 dev tunl0 proto bird onlink
blackhole 172.20.140.64/26 proto bird
172.20.196.128/26 via 10.99.99.11 dev tunl0 proto bird onlink
```

However, that makes vagrant unable to communicate with the VM via e.g. `vagrant ssh` because it is still using 1st VNIC and IP for that.

TODO: come up with a better permanent solution.

