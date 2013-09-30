# hcgrep - shell helper to ease hard classes grepping

## AUTHOR
Loïc Pefferkorn <loic-cfengine@loicp.eu>

## PLATFORM
Any OS with bash, awk and grep.

## DESCRIPTION
Because cf-promises -v displays hard classes as a single line, 
it requires a thorough read to determine if a specific hard class is defined,
and grep did not help much because they are returned as a single line: 

    $ cf-promises -v|grep freebsd
    cf3> Operating System Type is freebsd
    cf3> Using internal soft-class freebsd for host bsd82.local
    cf3> Additional hard class defined as: freebsd_8_2_RELEASE_p4
    cf3> Additional hard class defined as: freebsd_amd64
    cf3> Additional hard class defined as: freebsd_amd64_8_2_RELEASE_p4
    cf3> GNU autoconf class from compile time: compiled_on_freebsd8_2
    cf3>  -> Hard classes = { 172_16_100_1 172_16_2_1 192_168_2_14 1_cpu 64_bit Afternoon Day17 GMT_Hr12 Hr13 Hr13_Q1 Lcycle_0 March Min00
    Min00_05 PK_MD5_e964d2ce7a4dd7887a7374142cff1fb7 Q1 Sunday Yr2013 amd64 any bsd82 bsd82_local cfengine cfengine_3 cfengine_3_5 
    cfengine_3_5_0a2 common community_edition compiled_on_freebsd8_2 freebsd freebsd_8_2 freebsd_8_2_RELEASE_p4 freebsd_amd64 
    freebsd_amd64_8_2_RELEASE_p4 freebsd_amd64_8_2_RELEASE_p4_FreeBSD_8_2_RELEASE_p4__1__Sat_Nov_26_18_29_54_CET_2011
    ipv4_172 ipv4_172_16 ipv4_172_16_100 ipv4_172_16_100_1 ipv4_172_16_2 ipv4_172_16_2_1 ipv4_192 ipv4_192_168 ipv4_192_168_2 
    ipv4_192_168_2_14 local mac_unknown net_iface_em0 net_iface_gif0 net_iface_le0 verbose_mode }


hcgrep (hard classes grep) is a grep enhancer which splits each hard class over separate lines:

    $ cf-promises -v| hcgrep freebsd  
    compiled_on_freebsd8_2
    freebsd
    freebsd_8_2
    freebsd_8_2_RELEASE_p4
    freebsd_amd64
    freebsd_amd64_8_2_RELEASE_p4
    freebsd_amd64_8_2_RELEASE_p4_FreeBSD_8_2_RELEASE_p4__1__Sat_Nov_26_18_29_54_CET_2011

    $ cf-promises -v| hcgrep net_iface
    net_iface_em0
    net_iface_gif0
    net_iface_le0

    $ cf-promises -v| hcgrep cfengine 
    cfengine
    cfengine_3
    cfengine_3_5
    cfengine_3_5_0a2

Add the content of *hcgrep.bash* to your ~/.bashrc or ~/.profile, and source it with source ~/.bashrc

## LESS KEYSTROKES
The alias can be prefixed with “cf-promises -v” to shorten the command, 
but you will miss the ability to use a specific cf-promises binary. 

    myhcgrep() {
      cf-promises -v | awk '/Hard classes/ {for (i=7;i<=NF-1;i++) {print $i}}' | grep $1
    }
    alias hcgrep=myhcgrep

    # hcgrep net_iface
    net_iface_em0
    net_iface_gif0
    net_iface_le0

## REQUIREMENTS

- Bash  
- CFEngine 3.4+

## LICENSE
The MIT License (MIT)
Copyright (c) 2013 Loïc Pefferkorn

## NOTES
* Full description: http://www.loicp.eu/blog/cfengine_easy_hard_classes_grepping
* hcgrep.$(shell) for your favorite shell is welcome :)

