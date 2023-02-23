The next are the examples of the draft in cisco style to check with NCS. Currenlty we need to manually load everyting in the ncs system (which is complicated). We need to figure out how to do a better validation pipeline.

> Camilo's note: My current issue is dealing with network-instances over yanglint, need to read about it to see how to make it work.

# Example 1
- Active connection to a station. 
- Route monitoring enabled in "global" network instance
- adj-rib-in-pre enabled for ipv4 and ipv6 only for external peers 

```
bmp monitoring-stations monitoring-station 1 session-stats discontinuity-time 2015-06-19T16:01:27.384-07:00
 connection active station-address 192.0.2.1
 connection active station-port 57992
 connection active local-address 192.0.2.2
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer external
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer external
   !
```

# Example 2

- Passive connection to a station, over the network instance test
- Route monitoring enabled in "global" network instance for adj-ring-in-pre and adj-ring-in-post, only for external peers. Peer 128.66.1.1 is disabled (it is neeed in both ipv4 and ipv6 if you want to disable it in both)
- Route monutoring disabled for monitoring network instance disabled
- Route monutoring enabled in all other network instances for adj-rib-in-pre only, ipv4, ipv6 all peers

```
network-instances network-instance monitoring
network-instances network-instance customer1
network-instances network-instance customer2
!
bmp monitoring-stations monitoring-station 2 session-stats discontinuity-time 2015-06-19T16:01:27.384-07:00
 connection passive network-instance monitoring
 connection passive station-address 192.0.2.1
 connection passive local-address 192.0.2.2
 connection passive local-port 57993
!
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer external
   peer peer 128.66.1.1 disabled
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer external
   peer peer 128.66.1.1 disabled
   !
 bmp-data bmp-route-monitoring network-instances network-instance monitoring
  disabled 
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer bmp-peer-types-all-peers
   !
 ``` 
