#!/bin/bash

print_color() {
    case $2 in
        "green") echo -e "\e[32m$1\e[0m" ;;
        "red") echo -e "\e[31m$1\e[0m" ;;
        *) echo "$1" ;;
    esac
}

test_endpoint() {
    local url="$1"
    local expected_status="$2"
    local expected_body="$3"
    local custom_header="$4"

    echo "Testing endpoint: $url"

    if [ -n "$custom_header" ]; then
        response=$(curl -s -i -H "$custom_header" "$url")
    else
        response=$(curl -s -i "$url")
    fi

    if [ $? -ne 0 ]; then
        print_color "Error: Failed to connect to the server. Is it running?" "red"
        return 1
    fi

    status_code=$(echo "$response" | head -n1 | awk '{print $2}')

    body=$(echo "$response" | awk 'BEGIN {RS="\r\n\r\n"; ORS=""} NR==2 {print; exit}')

    echo "Received status code: $status_code"
    # echo "Received body: $body"

    if [ "$status_code" = "$expected_status" ]; then
        if [ -n "$expected_body" ]; then
            if [[ "$body" == *"$expected_body"* ]]; then
                print_color "Test passed! Status code and body match expected values." "green"
                return 0
            else
                print_color "Test failed! Status code matches but body doesn't contain expected value." "red"
                echo "Expected body: $expected_body"
                echo "Actual body: $body"
                return 1
            fi
        else
            print_color "Test passed! Status code matches expected value." "green"
            return 0
        fi
    else
        print_color "Test failed! Expected status '$expected_status' but got '$status_code'" "red"
        return 1
    fi
}

run_tests() {
    local base_url="http://127.0.0.1:4221"
    local failed_tests=0

    # Test 1: Root endpoint
    test_endpoint "$base_url/" "200"
    failed_tests=$((failed_tests + $?))

    # Test 2: Invalid endpoint
    test_endpoint "$base_url/invalid" "404"
    failed_tests=$((failed_tests + $?))

    # Test 3: Echo endpoint
    test_endpoint "$base_url/echo/abc" "200" "abc"
    failed_tests=$((failed_tests + $?))

    # Test 4: User-agent endpoint
    user_agent="curl/7.64.1"
    test_endpoint "$base_url/user-agent" "200" "$user_agent" "User-Agent: $user_agent"
    failed_tests=$((failed_tests + $?))

    # Test 5: concurrency
    echo "Testing concurrency with: oha http://127.0.0.1:4221"
    oha --no-tui http://127.0.0.1:4221
    if [ $? -ne 0 ]; then
        print_color "Test failed!" "red"
        failed_tests=$((failed_tests + 1))
    else
        print_color "Test passed!" "green"
    fi

    if [ $failed_tests -eq 0 ]; then
        print_color "All tests passed successfully!" "green"
        exit 0
    else
        print_color "$failed_tests test(s) failed." "red"
        exit 1
    fi
}

run_tests
