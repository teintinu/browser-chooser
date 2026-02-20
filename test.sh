#!/bin/bash

# Test script for Teintinu Browser Chooser

./build.sh

# If an argument is passed, use it as the URL
if [ -n "$1" ]; then
    URL="$1"
else
    echo "🌐 Teintinu Browser Chooser - Test Menu"
    echo "This script simulates opening common URLs to test your rules and AI."
    echo "--------------------------------------------------------------------------------"

    options=(
        "Linear (Subdomain + Query + Fragment) - https://app.linear.app/team/issue/ENG-123?auth=true#comment-456"
        "Google (Simple) - https://www.google.com"
        "AWS Console (Specific domain) - https://console.aws.amazon.com/ec2/v2/home"
        "Slack (Deep Link) - https://slack.com/app_redirect?channel=C01234567"
        "GitHub (Repository) - https://github.com/teintinu/browser-chooser"
        "YouTube (Video) - https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        "Amazon (Product) - https://www.amazon.com.br/dp/B08P8P9V6H?ref=pe_detail"
        "Zoom (Meeting) - https://zoom.us/j/123456789"
        "LinkedIn (Profile) - https://www.linkedin.com/in/user-profile/"
        "StackOverflow (Question) - https://stackoverflow.com/questions/123456/how-to-do-x"
        "Enter custom URL..."
        "Exit"
    )

    PS3="Choose an option (1-${#options[@]}): "

    select opt in "${options[@]}"
    do
        case $opt in
            "Enter custom URL...")
                read -p "Type the full URL: " CUSTOM_URL
                URL=$CUSTOM_URL
                break
                ;;
            "Exit")
                echo "Exiting test."
                exit 0
                ;;
            *)
                if [ -n "$opt" ]; then
                    URL=$(echo "$opt" | sed 's/.* - //')
                    break
                else
                    echo "Invalid option."
                fi
                ;;
        esac
    done
fi

if [ -n "$URL" ]; then
    echo "🧪 Testing URL opening: $URL"
    # Ensure URL has a scheme if manual
    if [[ ! $URL =~ ^https?:// ]]; then
        URL="https://$URL"
    fi
    
    open "$URL"
    if [ $? -eq 0 ]; then
        echo "✅ 'open' command sent successfully."
    else
        echo "❌ Error trying to open URL."
    fi
fi
