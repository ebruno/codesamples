#!/usr/bin/env bash
#1.0.0.0 via 10.10.41.1 dev enp1s0 src 10.10.41.191 uid 1000
read -a route_info <<< $(ip route get 1);
ip_addr="${route_info[6]}";
read -a dns_info <<< $(nslookup ${ip_addr});
echo "\S{PRETTY_NAME} \r (\l)" > /etc/issue;
printf "ip addr:${ip_addr}\nFQDN:${dns_info[3]}\n\n" >> /etc/issue;
