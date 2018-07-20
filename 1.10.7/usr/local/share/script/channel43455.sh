#!/bin/sh

CHANNEL_AUTO ()
{
    wl down
    wl apsta 0
    wl ap 1
    wl mpc 0
    wl band b
    wl up
    wl mpc 0
    wl autochannel 1
    AP_CHANNEL=14
    AUTO_LOOP_MIN=0
    AUTO_LOOP_MAX=50

    while [ ${AUTO_LOOP_MIN} -lt ${AUTO_LOOP_MAX} ]; do
        sleep 0.2
        wl autochannel > /tmp/channel.auto
        AP_CHANNEL=`cat /tmp/channel.auto | awk '{print $1}'`
        if [ -n "$(echo $AP_CHANNEL | sed -n "/^[0-9]\+$/p")" ]; then
            break
        else
            AUTO_LOOP_MIN=$((${AUTO_LOOP_MIN}+1))
        fi
    done

    if [ ${AUTO_LOOP_MIN} -ge ${AUTO_LOOP_MAX} ] || [ ${AP_CHANNEL} -ge 14 ]; then
        AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
        echo " CHANNEL_AUTO Default >> AP_CHANNEL = ${AP_CHANNEL}"
    else
        echo " CHANNEL_AUTO >> AP_CHANNEL = ${AP_CHANNEL}"
    fi

    export AP_CHANNEL
}

CHANNEL_INIT ()
{
    echo " CHANNEL_INIT >> AP_COUNTRY = ${AP_COUNTRY}   AP_CHANNEL = ${AP_CHANNEL}   AP_CHANNEL_5G = ${AP_CHANNEL_5G}"
    dhd_priv country ${AP_COUNTRY}

    case ${AP_COUNTRY} in
        HK | ID | MY | UA | IN | MX | VN | BY | MM | BD | IR)
            #wl country XZ/0
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        ES | FR | PL | DE | IT | GB | PT | GR | NL | HU | SK | NO | FI)
            #wl country EU/0
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        CA)
            #wl country CA/2
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        CN)
            #wl country ${AP_COUNTRY}
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 153 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        CZ)
            #wl country CZ
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        US)
            #wl country ${AP_COUNTRY}
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 153 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        RU)
            #wl country RU
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        JP)
            #wl country JP/5
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        KR)
            #wl country KR/24
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 3) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        IL)
            #wl country IL
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                CHANNEL_AUTO
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        SE)
            #wl country SE
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        SG)
            #wl country SG
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 153 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        TR)
            #wl country TR/7
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        RU | ID | IL)
            #5G :NULL 2.4G 1-13
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                #export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
                CHANNEL_AUTO
            else
                #export AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        JP)
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                echo "open DJ 5G"
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 36 ))`
            else
                #export AP_CHANNEL=`echo $(( ($RANDOM % 3) * 5 + 1 ))`
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        TH)
            #wl country TH
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 153 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        PH)
            #wl country PH
            if [ ${AP_CHANNEL_5G} -eq 1 ]; then
                export AP_CHANNEL=`echo $(( ($RANDOM % 4) * 4 + 153 ))`
            else
                CHANNEL_AUTO
            fi

            if [ ${AP_CHANNEL} -eq 10 ]; then
                AP_CHANNEL=6
            fi
            ;;
        *)
            CHANNEL_AUTO
            ;;
    esac
}

CHANNEL_INIT

exit ${AP_CHANNEL}
