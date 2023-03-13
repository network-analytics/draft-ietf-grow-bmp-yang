# BGP YANG MODEL

The next text describes the details of the BMP yang model. The purpose of this text it to provide as much information as possible of the requirements of the authors for the model, and provide examples of configurations for different scenarios. We hope the text helps:

- BMP operators to provide their own requirements, or question the requirements of the authors, even without being YANG experts.
- YANG doctors (or other YANG experts) to provide recommendations to tune the model to the set of requirements.

## Location of the BMP model in the yang tree

The BMP yang model is currently anchored at the root of the YANG tree. The authors are still considering to place all or some parts of the model within the "ietf-routing:routing" tree, if it helps with the interconection of the model with the "ietf-network-instance:network-instances" or to deal with multiple BGP instances (see question below).

At its upper level, the BMP model lists each monitoring station. Every monitoring station is identified using an ID, which is a string provided by the operator. Note that the model does not contain a default configuration for monitoring stations. As we will describe later, each monitoring station session will need to be linked with an element of this list, and there cannot be mulitple sessions per element.

```
module: ietf-bmp
  +--rw bmp
     +--rw monitoring-stations
        +--rw monitoring-station* [id]
           +--rw id               string
           +--rw connection
           |     ...
           +--rw bmp-data
           |     ...
           +--rw session-stats
           |     ...
           +--rw actions
                 ...
```

## BGP instances?

The BMP process is "tight" with a BGP process.  According to RFC7854, Section 8.1, (the BMP specification), multiple instances of BGP should have its own BMP configuration. The BGP yang model (https://datatracker.ietf.org/doc/html/draft-ietf-idr-bgp-model/) augments the "ietf-routing:routing" model with the text "This augmentation is valid for a routing protocol instance of BGP" and the ietf-routing:routing tree is also schema-mounted under the ietf-network-instance:network-instances tree. However, similar to how routers operate, a network-instance BGP should still be tight to the "global" BGP instance (the draft mentions it in Section 2.2.), thus hinting to a single BGP process.

> Question to authors: We should clarify the different meanings of BGP "instance" across the differnet documents. We should make sure we define how the BGP model deals with multiple BGP (as BGP independent processes?). From what Camilo sees, there is no option for multinstance in the BGP model or it will be based on it augmenting the ietf-routing model.

> Question to authors: This document (and the model) assumes that there is a "GLOBAL" network instance, which is configured under the root of the tree in ietf-routing:routing, but Camilo has not found any reference to it. Openconfig, for instance, includes the global network instnaces with the others (see https://www.openconfig.net/docs/models/network_instance/)

# Connectivity Parameters for Monitoring station

```
module: ietf-bmp
  +--rw bmp
     +--rw monitoring-stations
        +--rw monitoring-station* [id]
           +--rw id               string
           +--rw connection
           |  +--rw (passive-or-active)?
           |  |     ...
           |  +--rw tcp-options
           |  |     ...
           |  +--rw initial-delay?   uint32
           |  +--rw backoff
           |        ...
```

## IP connectivity

The BMP (RFC7854 Section 3.2.) allows for active and passive connections between the router and the monitoring station. This module provides options for both types of connection. In an active connection, the router establishes the TCP connection to the monitoring station, while in a passive one is the monitoring station which initiates the connection. 

The device should contain enough information to properly indentify a TCP connection and assign it to a configured monitoring station (to a single monitoring station ID). **Each monitoring station can be assigned maximum one BMP session**.

We describe each type of connection option next, and provide examples of their configuration.  

### Active connection

For an active connection, the IP address and port of the monitoring station, together with the local address MUST be provided. One can optionally provide the local port for establishing the connection. If the monitoring station is connected over a network-instance instead of the global one, this one must also be specified. An example of configuration is included next.

```
bmp monitoring-stations monitoring-station 1 session-stats discontinuity-time 2015-06-19T16:01:27.384-07:00
 connection active station-address 192.0.2.1
 connection active station-port 57992
 connection active local-address 192.0.2.2
!
```

See in the example that there is no network instance defined, so the connection is using the global one.

### Passive connection

The model enforces the identification of every monitoring station. An incoming connection not matching a valid entry MUST be ignored by the router.

The IP of the monitoring station, the local address and local port for the incoming connection must be specified. If the port of the monitoring station is provided, it MUST match the incoming connection. If the monitoring station is connected through a network-instance instead of the global one, this one MUST also be specified.
Note that if the port for the monitoring station is not provided,  only one connection from the monitoring station IP MUST be accepted, since any other connection cannot be assigned to any other monitoring station element.

```
network-instances network-instance test
!
bmp monitoring-stations monitoring-station 2 session-stats discontinuity-time 2015-06-19T16:01:27.384-07:00
 connection passive network-instance test
 connection passive station-address 192.0.2.1
 connection passive local-address 192.0.2.2
 connection passive local-port 57993
!
```

## TCP options

The BMP module allows tuning various parameters of the TCP connection supporting the BMP session:

* For configuring tcp keepalives, the connection container uses the tcp-common-grouping from I-D.ietf-netconf-tcp-client-server (Camilo's note: this document is still a draft and they tend to not like groupins and remove them). Section 2.1.3.1 of I-D.ietf-netconf-tcp-client-server provides the explanation of each of its parameters. Note that for the configuration of these parameter, the device must have the feature "tcp-client-keepalives" enabled (see  I-D.ietf-netconf-tcp-client-server). Also see RFC9293 Section 3.8.4
* The maximum segment of the TCP connection. See  RFC9293 section 3.7.1.
* Enabling MTU discovery for the path.  See RFC9293 Section 3.7.2
* Session security. Provides options for authentication using AO and MD5. This part of the model was taken from the BGP yang model.

Examples of configuring the previous parameters in the model is provided next.

### Example of TCP tuning parameters 

example comes from  the tcp-common draft, we can change the values.

```
bmp monitoring-stations monitoring-station 1
 connection keepalives idle-time 15
 connection keepalives max-probes 3
 connection keepalives probe-interval 30
!

bmp monitoring-stations monitoring-station 1
 connection maximum-segment-size 1500
 connection mtu-discovery true
```

### TCP session security example

> Question to authors: For the security example, we might  need to add I-D.ietf-tcpm-yang-tcp to the drafts, BMP does not depend on it, but the next example does..  Maybe we should add it to the references then.

> Note to authors: We took the security section verbatim from the BGP model. 

> Question to authors: Should we remove MD5 for authentication on BMP? 

> Question to authors: Instead of secure-session-enable as the BGP model does, should we have the secure-session be a presence container with meaning turning the container on? what is the benefit of the boolean flag instead of that?

```
key-chains key-chain bmp-key-chain
 description "An example of TCP-AO configuration for BMP"
 key 55 crypto-algorithm aes-128
  lifetime send-lifetime start-date-time 2023-01-01T00:00:00+00:00
  lifetime send-lifetime end-date-time 2023-02-01T00:00:00+00:00
  lifetime accept-lifetime start-date-time 2023-01-01T00:00:00+00:00
  lifetime accept-lifetime end-date-time 2023-02-01T00:00:00+00:00
  key-string keystring teststring
  authentication keychain bmp-key-chain
  authentication ao send-id 65
  authentication ao recv-id 87
 !
 !
 key 56 crypto-algorithm aes-128
  lifetime send-lifetime start-date-time 2023-01-01T00:00:00+00:00
  lifetime send-lifetime end-date-time 2023-02-01T00:00:00+00:00
  lifetime accept-lifetime start-date-time 2023-01-01T00:00:00+00:00
  lifetime accept-lifetime end-date-time 2023-02-01T00:00:00+00:00
  authentication keychain bmp-key-chain
  authentication ao send-id 65
  authentication ao recv-id 87
 !
 !
!

bmp monitoring-stations monitoring-station 1
 connection tcp-options secure-session-enable true
 connection tcp-options secure-session ao-keychain bmp-key-chain
!
key-chains key-chain bmp-key-chain
!

```

## Other BMP connectivity options

Other options for the connection to the  BMP monitoring station.

* Initial-delay: a value in seconds that the device must hold back before starting the connection to the station. 
> Question to authors: Find a non-propietary reference for the initial-delay? Tim Fiola asked for it, and it seems harmless, but it would be nice to have a reference with the benefits.
* Backoff time. Configuration of the backoff time strategy after failing to connect to the monitoring station. The model includes a basic exponential backoff with a default initial backoff of 30 seconds and a maximum of 720 seconds, as suggested by RFC7854 Section 3.2.

```
bmp monitoring-stations monitoring-station 1
 connection initial-delay 10
 connection backoff simple-exponential initial-backoff 30
 connection backoff simple-exponential maximum-backoff 720
!
```

# BMP data

The bmp-data container defines the configuration parameters for the data that the devices sends to the monitoring station using the various BMP messages (RFC7854 Section 4).

The bmp model currently defines options for the initiation message, the statistics report, and the routing monitoring. The first two have simple configurations options and are shortly described next. The Routing monitoring is the most complex of all and it is detailed in its own section.

* initiation-message: Content for a information TLV type-0 for identitification of the device. See RFC7854 Section 4.3 and 4.4
* Statistics-interval: The statistics report is enabled by the presence of the bmp-statistics-report container. The statistics-interval is mandatory if the bmp-statistics-report container exists, and defines the interval of the statistics report.  See RFC7854 Section 4.8. 

```
bmp monitoring-stations monitoring-station 1
 bmp-data initiation-message "I am a BMP device supporting the BMP yang module"
 bmp-data bmp-statistics-report statistics-interval 600
!
```
> Question to authors: What happens if the bmp-statistics-report is not set? should we disabled? should we add a enable or presence statmeent in the bmp-statistics-report container?

# BMP route monitoring 

Route monitoring messages are used for synchronization of RIBs to the monitoring station (RFC7854 Section 5.). 

A few design/thoughts on route monitoring:

* Operators might or not want to receive all routes from all RIBs in a network device. Some devices contain a considerable amount of data that might overwhelm the monitoring station, for instance, and operators might want to only collect information from an arbitrary subset of them. 
* Operators might want to configure the route monitoring messages differently, depending on the RIB. For example, they might want to receive different address families from the global network instance than in L3 VPN network instances. 
* As a counter-part of the two previous points, opetarors might want a simple configuration that covers multiple cases (e.g. same config for all peers, or same config for all network instances).  This would not only make configuartions look smaller and concise, but will reduce the need for reconfiguring devices when you add a new peer or add a new network instance (which happens frequently on some type of networks). 

Based on the previous points, the BMP yang model is designed to flexibly control the BMP route monitoring process, yet it attempts to facilitate configurations by providing methods for simple cases, such as when the operator wants to receive all routes from a RIB.

For Routing monitoring configuration is divided in a 4 part hierarchy:

* Network Instance 
* RIB-Type (e.g. Adj-RIB-IN, etc/OUT and local RIB)
* Address Family 
* Peers

## Design requirements for BMP route monitoring configurations

The RIB types (e.g. Adj-RIB-IN, etc/OUT and local RIB) and Address families are configured explicitly in the model. That is, the model does not provide a way of providing a default configuration for these. For both of them, the number of options is low, and their configuration should not change frequently.

The model should configure not only the "global" network instance (the main one configured under the /ietf-routing:routing), but also other network instances configured under the /ietf-network-instance:network-instances/. 
Network instances can vary frequenlty in networks with customer connecting to Virtual Private Networks. To not force operators to change configuration at every change, the model should provide a default configuration for network instances.

The model provides peer level control for the ADJ-RIB-IN and ADJ-RIB-OUT (both pre and post). It includes a way of configuring a default for all peers for simple cases, but one can provide configuration for type of peers or each peer individually. 

We summarize the requirements stated on the previous two paragraphs next:

For network instances:
* The configuration should be simple for cases where only the "global" routing instance is enabled.
* The model should  provide ways of configuring all vrfs (kind of a default config for any vrf that is configured in the device).
* The model should provide a way of configuring vrfs individually.
* Note that the default config would be less restrictive than the individual one (since we can reference the vrf container and validate its content)

For peers:
* The model should provide ways of configuring all peers, kind of a default. This would be the most common case.
* The model should provide ways of configuring type of peers. For instance, only send routes from ebgp peers.
* The model should provide ways of configuring individual peers. For instance, turn a route-policy filtering prefix for a specific peer, or turning off a peer that is noisy yet not important.

To further control the route monitoring data, the peer/peer-type container includes a route-policy option in which the operator can further filter the data 

**An empty (or abscense) of the routing routing monitoring container will disable the routing messages to the monitoring station in general. **

We'll describe each of the 4 hierarchies next:

## Network instances

The routing monitoring configuration starts with the selection of the network instance. One or more Network instances can be selected using a `bmp-ni-types` identity, or they can be selected individually, referencing the /network-instance/ list.

The model currently defines two bmp-ni-types identities: `bmp-ni-types-all-ni` which selects all network instances, and `bmp-ni-types-global-ni` which selects the global network instance (the one configured in `/ietf-routing:routing/`).

An empty configuration disables routing monitoring messages for the selected network-instances. Operators can also use the enable leaf to disable explicitly the routing messages for the network instance. 

A network instance MUST be configured using a single instance of the network-instance list. There should be clear rules in which element to apply to a network instance in case multiple elements can select it. We provide rules and examples in the next part of the section.

- If the bmp-ni-types-global-ni exist, the **global** network instance / network instance SHOULD be configured using this element.
- If any /ni:network-instances/ni:network-instance/ is referenced, the network instance SHOULD be configured using this element.
- Any Network isntance not referenced by any above should be configured using the bmp-ni-types-all-ni if one exists. If it does not exist, then the network instance is not configured (and therefore no route monitoring messages from the network instance are sent to the monitoring station).

Any extension of the bmp-ni-types SHOULD provide explanations of how to deal with case in which multiple elements select the same network instance. 

We provide examples of configuring the network instance level next. To focus on the network instance configuration, we redact the configuration under each instance using `< Configuraion X >`. 

### Example one

```
network-instances network-instance network-instance-one
!
network-instances network-instance network-instance-two
!
bmp monitoring-stations monitoring-station 1
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
  < Configuration A >
 !
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  < Configuration B >
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-one
  enabled false
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-two
  < Configuration C >
 !
```

In this example, we have a "default" configuration (Configuration A) applied to any network instance without any explicit configuration. The global network instance and network-instance-two get Configuration B and Configuration C, respectively. The network-instance-one instance disables the routing monitoring messages for that network instnace. 

### Example two

```
bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
 < Configuration D >
!
```

Note that `bmp-ni-types-all-ni` would also cover the global instance, in the previous  simple configuration all network instances, including the global would be configured with Configuration D.

A simple configuration in simple cases would just involve configuring the global network instance.

```
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
 < Configuration E >
 !
```

## RIB-Type

Each RIB type is configured explicitly in the model through a container. The model currently provides containers for adj-rib-out-pre, adj-rib-out-post, adj-rib-in-post, adj-rib-in-pre and local-rib. 

An empty configuration or absence of a RIB-type container disables route-messages for it. Operators can also disable the RIB-type route monitoring messages by marking the "enabled" leaf as False.

We provide an example of this together with address families in the next section

## Address families.

Address families are configured explicitily within each RIB-TYPE using a list. The key is of type `ietf-bgp-types:afi-safi-type` without any further constraint.

> Note to authors: We could further constraint AF to the AF on the network instance BUT only if we had a more complex model that could point to the proper ietf-routing tree (either global or within the network instances). If we keep the default case, we wouddn't be able to restraint it.

An empty configuration or absence of an address family disables route-messages for it. Operators can also disable the address-family route monitoring messages by marking the "enabled" leaf as False.

We show a few examples of configuring RIB-Types and Address families next. We will redact further configurations of address families with `< Configuration X >` to focus on the covered parts.

### Address families example one
```
bmp monitoring-stations monitoring-station 1
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   < Configuration F >
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   < Configuration G >
  !
 !
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   < Configuration H >
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   < Configuration I >
  !
  adj-rib-in-post address-families address-family ipv6-unicast
   < Configuration J >
  !
  adj-rib-in-post address-families address-family ipv4-unicast
   < Configuration K >
  !
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-one
  disabled
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-two
  adj-rib-out-post address-families address-family ipv4-unicast
   < Configuration L >
  !
 !
!
```
We expand previous sections examples with RIB-TYpe and address families configurations. The expected result of the previous configuration would be:

- For the global network instance, adj-rib-in-pre and adj-rib-in-post RIBs are enabled. In each of them IPv4 and IPv6 address families are configured. The configuration can be the same or not, depending on the requirements of the operatosr. Any other rib types and address famlies are disabled.
- Network instance one is disabled, meaning that routing monitoring messagages are disabled for that network instance.
- Network instance network-instance-two  has adj-rib-out-post enabled, but only address family ipv4-unicast is configured. The ipv6-unicast will not be configured for this instance.
- For all other network intanaces, adj-rib-in-pre with ipv4 and ipv6 address families are configured, thanks to the configuration of bmp-ni-types-all-ni

### Address families example two

If an operator only wants to configure the ipv4/ipv6 of adj-rib-pre-in for the global instance,  the next configuration will be enough.

```
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   < config for ipv6-unicast >
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   < config for ipv4-unicast >
  !
 !
```

## Peers

For adj-RIB-in and adj-RIB-out, both pre and post, the model requires the selection of peer's RIBs that will be transmitted to the monitoring station. The local-rib does not include this container.

Peers are a list indexed by a peer id, which can be one of the following: 

- An individual peer, using a remote address. The model currently does not check if the remote address exists, that would be a responsability of the device.
- A group of peers matching a BGP type. i.e. ebgp peers. 
- One or more peers defined by an `bmp-peer-types` identity. The BMP model currently provides the `bmp-peer-types-all-peers` identity which select all peers. For simple cases, this is the value that would normally be considered.

> Note to authors: we could further constraint peers to the peers configured in the BGP of the NI BUT only if we had a more complex model that knew the position in the tree. For default configurations, this will still be not possible.

Peers MUST be selected (configured) by tops a  single instance of the peers list. For the described key types included in the model, the process to select which instance to use is the next:

- If there is a peer address matching the peer, it should be configured using that instance.
* If the peer is of any BGP type listed in the peer list, it should be configured using this instance.
* If there is a peer instance identified with the `bmp-peer-types-all-peers`, it would be configured using this instance.
* Finally, if no instance covers the peer, the data from this peer should not be transmited to the monitoring station.

An empty configuration of a peer type disables route-messages for it. Operators can also disable the address-family route monitoring messages by marking the "enabled" leaf as False.

Any aditional bmp-peer-types identity created SHOULD describe how to unambiguoslly select a peer when there are conflicting options (multiple options covering the peer).

We'll provide examples of the peers configuration after describing the filter containers.

## Filtering route-monitoring messages

The local rib, and the peer containers within the rest of rib types, include a filter container. This container includes mechanims to filter route-monitoring messages for the specific RIB.

The policy-filter can include a routing policy that, if existing, should be applied to the outgoing updates to the monitoring station, and would serve as a granular way of filtering the messages that the monitoring station receives. 

Note that the policy-filter contains an `accept-route` default export policy. An operator can change it to a reject-route, if required.

The policies created with the routing-policy can perform a large variaty of actions routes, and can filter them based on multiple characteristics. For the consistency of the data in the monitoring station, The route policies actions SHOULD be restritcted to accepting or rejecting routes. Furthermore, the conditions SHOULD only match prefix sets.

We present examples of full configurations next.

> Note to authors: We could filter peers using policies and avoid the peer container entirely. But then, it will be harder to turn BMP features on per peer, such as the BMP marking TLV.

## Route monitoring configurations - full examples

### Route monitoring configurations - example one

```
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
 !
```

In the previous example, address families ipv6 and ipv4 are configured to send all peers. This is an example of a simple configuration

### Route monitoring configurations - example two

```
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-global-ni
  adj-rib-in-pre 
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer 198.51.100.1
    filters policy-filter export-policy [ test_policy ]
   !
   peers peer external
   !
  !
```
In this example, the global network instance enables the adj-rib-in-pre. In this RIB, the  ipv4 unicast address family is configured for all external peers. We assume peer 198.51.100.1 is external, but its BGP configuration is not shown in the snippet.  Peer 198.51.100.1, however, has a specific configuration: it announces everything but prefixes matching the test_policy list. Note that there is a default accept-route default policy in the model.

### Route monitoring configurations - example three

```
 bmp-data bmp-route-monitoring network-instances network-instance bmp-ni-types-all-ni
  adj-rib-in-pre address-families address-family ipv6-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
  adj-rib-in-pre address-families address-family ipv4-unicast
   peers peer bmp-peer-types-all-peers
   !
  !
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-one
  disabled
 !
 bmp-data bmp-route-monitoring network-instances network-instance network-instance-two
  local-rib address-families address-family ipv4-unicast
  !
 !
!
```

In this example, all network instances have adj-rib-in-pre with AF ipv6 and ipv4 configured receiving all peers. network-instance-one is disabled, and network-instance-two is announing only the local-rib/ipv4 unicast routes.


