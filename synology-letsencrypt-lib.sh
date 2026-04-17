#!/bin/bash -e

punycode() {
    if command -v python3 &>/dev/null; then
        python3 -c "import sys; [sys.stdout.write(l.strip().encode('idna').decode('ascii')+'\n') for l in sys.stdin]"
    else
        python2 -c "import sys; [sys.stdout.write(l.strip().decode('utf-8').encode('idna')+'\n') for l in sys.stdin]"
    fi
}


# implement `lego` sanitizedDomain [ref.: https://github.com/go-acme/lego/blob/e0a1fe55277b69a84c45927ef0c075ce062a86a0/cmd/certs_storage.go#L320]
sanitizedDomain() { printf '%s' "$1" | tr ':*' '-_' | punycode; }

