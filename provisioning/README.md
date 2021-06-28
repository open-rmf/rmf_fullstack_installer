# provisioning
This document describes how to provision the RMF machine. 

## Local Machine
This is the simplest setup: You need one computer running the described [specs](/README.md#Infrastructure-Requirements). This should be sufficient for local testing.

## Cloud Machine
The following script provides a step-by-step guide to the necessary steps to provision a cloud machine.
```
bash provision-cloud-machine.bash
```

### DNS
You might want to set up DNS for your EC2 instance to access it over a human-readable URL. Here is how you can do so.

We will be using AWS Route 53 to do this. We assume that we have rights to some domain, such as open-rmf.org.

In Route 53, you will first have to create a hosted zone, containing NS, A and CNAME records to your domain provider.

Finally, you will need to create an A record pointing your device public IP address. For example, the record name is openrobotics.demo.open-rmf.org.

You should now be able to resolve the IP address of openrobotics.demo.open-rmf.org. For example:

```
# dig openrobotics.demo.open-rmf.org

; <<>> DiG 9.16.16 <<>> openrobotics.demo.open-rmf.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 48230
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;openrobotics.demo.open-rmf.org.        IN      A

;; ANSWER SECTION:
openrobotics.demo.open-rmf.org. 299 IN  A       13.213.154.74

;; Query time: 19 msec
;; SERVER: 8.8.8.8#53(8.8.8.8)
;; WHEN: Wed Jun 02 08:38:02 UTC 2021
;; MSG SIZE  rcvd: 75
```
