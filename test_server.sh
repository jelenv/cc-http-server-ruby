#!/bin/bash

print_color() {
    case $2 in
        "green") echo -e "\e[32m$1\e[0m" ;;
        "red") echo -e "\e[31m$1\e[0m" ;;
        *) echo "$1" ;;
    esac
}

test_endpoint() {
    local url="$1" method="${2:-GET}" expect_status="$3" expect_body="$4" header="$5" data="$6"
    echo "Testing: $method $url"

    response=$(curl -s -i -X "$method" ${header:+-H "$header"} ${data:+-d "$data"} "$url")
    status_code=$(echo "$response" | head -n1 | awk '{print $2}')
    body=$(echo "$response" | awk 'BEGIN {RS="\r\n\r\n"} NR==2')

    echo "Status: $status_code"
    if [ "$status_code" = "$expect_status" ] && { [ -z "$expect_body" ] || [[ "$body" == *"$expect_body"* ]]; }; then
        print_color "Test passed!" green
        return 0
    else
        print_color "Test failed! Expected status $expect_status${expect_body:+ and body containing '$expect_body'}" red
        [ -n "$expect_body" ] && echo "Actual body: $body"
        return 1
    fi
}

check_file() {
    if [ -f "$1" ] && [ "$(cat "$1")" = "$2" ]; then
        print_color "File content matches." green
        return 0
    else
        print_color "File check failed. Expected: $2" red
        return 1
    fi
}

run_tests() {
    local base_url="http://127.0.0.1:4221"
    local failed_tests=0

    # Test 1: Root endpoint
    test_endpoint "$base_url/" "GET" "200"
    failed_tests=$((failed_tests + $?))

    # Test 2: Invalid endpoint
    test_endpoint "$base_url/invalid" "GET" "404"
    failed_tests=$((failed_tests + $?))

    # Test 3: Echo endpoint
    test_endpoint "$base_url/echo/abc" "GET" "200" "abc"
    failed_tests=$((failed_tests + $?))

    # Test 4: User-agent endpoint
    user_agent="curl/7.64.1"
    test_endpoint "$base_url/user-agent" "GET" "200" "$user_agent" "User-Agent: $user_agent"
    failed_tests=$((failed_tests + $?))

    # Test 5: Concurrency
    echo "Testing concurrency with: oha http://127.0.0.1:4221"
    oha --no-tui http://127.0.0.1:4221
    if [ $? -ne 0 ]; then
        print_color "Concurrency test failed!" red
        failed_tests=$((failed_tests + 1))
    else
        print_color "Concurrency test passed!" green
    fi

    # Test 6: Download existing file
    echo -n 'Hello, World!' > /tmp/foo
    test_endpoint "$base_url/files/foo" "GET" "200" "Hello, World!"
    failed_tests=$((failed_tests + $?))

    # Test 7: Download non-existing file
    test_endpoint "$base_url/files/non-existing-file" "GET" "404"
    failed_tests=$((failed_tests + $?))

    # Test 8: Upload a file to the server
    local filename="test_file.txt"
    local file_content="This is a test file content."
    test_endpoint "$base_url/files/$filename" "POST" "201" "" "Content-Type: application/octet-stream" "$file_content"
    failed_tests=$((failed_tests + $?))
    check_file "/tmp/$filename" "$file_content"
    failed_tests=$((failed_tests + $?))
    rm /tmp/test_file.txt

    if [ $failed_tests -eq 0 ]; then
        print_color "All tests passed successfully!" "green"
        exit 0
    else
        print_color "$failed_tests test(s) failed." "red"
        exit 1
    fi
}

run_tests
