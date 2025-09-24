#!/bin/bash
# scan-fixed.sh - Fixed security scanning script for Ubuntu/Debian systems

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="monarchxmat/ibex-webapp:latest"
REPORTS_DIR="reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SNYK_ORG="a4865e9e-c24d-47d2-b309-8ac466896006"

# Detect if running as root
if [ "$EUID" -eq 0 ]; then 
   SUDO=""
else
   SUDO="sudo"
fi

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

# Create reports directory structure
setup_reports_dir() {
    print_header "Setting up reports directory"
    
    mkdir -p ${REPORTS_DIR}/{trivy,snyk,checkov,docker-scout,summary}
    mkdir -p ${REPORTS_DIR}/trivy/{docker,terraform}
    mkdir -p ${REPORTS_DIR}/snyk/{docker,terraform}
    mkdir -p ${REPORTS_DIR}/docker-scout
    
    print_success "Reports directory structure created"
}

# Install system dependencies
install_system_deps() {
    print_header "Installing system dependencies"
    
    # Update package list
    print_info "Updating package list..."
    $SUDO apt-get update -qq
    
    # Install python3-venv if not present
    if ! dpkg -l | grep -q python3-venv; then
        print_info "Installing python3-venv..."
        $SUDO apt-get install -y python3-venv python3-pip
        print_success "Python venv installed"
    else
        print_success "Python venv already installed"
    fi
    
    # Install curl if not present
    if ! command -v curl &> /dev/null; then
        print_info "Installing curl..."
        $SUDO apt-get install -y curl
    fi
    
    # Install npm if not present (for Snyk)
    if ! command -v npm &> /dev/null; then
        print_info "Installing npm for Snyk..."
        $SUDO apt-get install -y npm
    fi
}

# Check and install tools
check_tools() {
    print_header "Checking required tools"
    
    # Check Trivy
    if command -v trivy &> /dev/null; then
        print_success "Trivy is installed ($(trivy --version 2>&1 | head -n1))"
    else
        print_warning "Trivy not found. Installing..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | $SUDO sh -s -- -b /usr/local/bin
        if command -v trivy &> /dev/null; then
            print_success "Trivy installed successfully"
        else
            print_error "Failed to install Trivy"
        fi
    fi
    
    # Check Snyk
    if command -v snyk &> /dev/null; then
        print_success "Snyk is installed"
        # Check if authenticated
        if ! snyk auth --check &> /dev/null; then
            print_warning "Snyk not authenticated. Please run: snyk auth"
            print_info "Get your token from: https://app.snyk.io/account"
        else
            print_success "Snyk authenticated with org: ${SNYK_ORG}"
        fi
    else
        print_warning "Snyk not found. Installing..."
        if command -v npm &> /dev/null; then
            $SUDO npm install -g snyk
            print_success "Snyk installed"
            print_info "Please authenticate: snyk auth"
        else
            print_error "npm not found. Cannot install Snyk"
        fi
    fi
    
    # Check Docker Scout
    if docker scout version &> /dev/null 2>&1; then
        print_success "Docker Scout is available"
    else
        print_warning "Docker Scout not available. Installing plugin..."
        # Install Docker Scout plugin for Linux
        curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | $SUDO sh -s --
        if docker scout version &> /dev/null 2>&1; then
            print_success "Docker Scout installed"
        else
            print_warning "Docker Scout installation failed - will skip Scout scans"
        fi
    fi
    
    # Check Checkov
    if command -v checkov &> /dev/null; then
        print_success "Checkov is installed ($(checkov --version 2>&1 | head -n1))"
    elif [ -f "checkov-env/bin/checkov" ]; then
        print_success "Checkov found in virtual environment"
    else
        print_warning "Checkov not found. Installing in virtual environment..."
        python3 -m venv checkov-env
        ./checkov-env/bin/pip install --upgrade pip
        ./checkov-env/bin/pip install checkov
        if [ -f "checkov-env/bin/checkov" ]; then
            print_success "Checkov installed in virtual environment"
        else
            print_error "Failed to install Checkov"
        fi
    fi
    
    # Check Docker
    if command -v docker &> /dev/null; then
        print_success "Docker is installed ($(docker --version))"
    else
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
}

# Scan Docker image with Docker Scout
scan_docker_scout() {
    print_header "Scanning Docker image with Docker Scout"
    
    if ! docker scout version &> /dev/null 2>&1; then
        print_warning "Docker Scout not available, skipping..."
        return 0
    fi
    
    REPORT_FILE="${REPORTS_DIR}/docker-scout/scout-${TIMESTAMP}.txt"
    
    print_info "Scanning ${DOCKER_IMAGE} with Docker Scout..."
    
    # Quick view scan
    docker scout quickview ${DOCKER_IMAGE} > ${REPORT_FILE} 2>&1 || true
    
    # CVE scan with details (only if quickview succeeds)
    if [ -s ${REPORT_FILE} ]; then
        print_info "Running CVE analysis..."
        docker scout cves ${DOCKER_IMAGE} --only-severity critical,high >> ${REPORT_FILE} 2>&1 || true
        
        print_success "Docker Scout scan complete"
        print_info "Report: ${REPORT_FILE}"
    else
        print_warning "Docker Scout scan produced no results"
    fi
}

# Scan Docker image with Trivy
scan_docker_trivy() {
    print_header "Scanning Docker image with Trivy"
    
    if ! command -v trivy &> /dev/null; then
        print_warning "Trivy not available, skipping..."
        return 0
    fi
    
    REPORT_FILE="${REPORTS_DIR}/trivy/docker/trivy-docker-${TIMESTAMP}.txt"
    JSON_FILE="${REPORTS_DIR}/trivy/docker/trivy-docker-${TIMESTAMP}.json"
    
    print_info "Scanning ${DOCKER_IMAGE}..."
    
    # Pull image first to ensure it's available
    docker pull ${DOCKER_IMAGE} || true
    
    # Text report
    trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE} > ${REPORT_FILE} 2>&1 || true
    
    # JSON report for processing
    trivy image --format json --severity HIGH,CRITICAL ${DOCKER_IMAGE} > ${JSON_FILE} 2>&1 || true
    
    if [ -s ${REPORT_FILE} ]; then
        print_success "Docker image scanned with Trivy"
        # Quick summary
        if grep -q "Total:" ${REPORT_FILE}; then
            echo "Summary:" 
            grep "Total:" ${REPORT_FILE} | head -n5
        fi
    else
        print_warning "No results from Trivy scan"
    fi
    
    print_info "Reports saved:"
    print_info "  - Text: ${REPORT_FILE}"
    print_info "  - JSON: ${JSON_FILE}"
}

# Scan Docker image with Snyk
scan_docker_snyk() {
    print_header "Scanning Docker image with Snyk (+ Dashboard Reporting)"
    
    if ! command -v snyk &> /dev/null; then
        print_warning "Snyk not installed, skipping..."
        return 0
    fi
    
    # Check authentication
    if ! snyk auth --check &> /dev/null; then
        print_warning "Snyk not authenticated. Skipping Snyk scans."
        print_info "Run: snyk auth"
        return 0
    fi
    
    REPORT_FILE="${REPORTS_DIR}/snyk/docker/snyk-docker-${TIMESTAMP}.txt"
    JSON_FILE="${REPORTS_DIR}/snyk/docker/snyk-docker-${TIMESTAMP}.json"
    
    print_info "Scanning ${DOCKER_IMAGE} and sending to Snyk Dashboard..."
    
    # Monitor (send to dashboard)
    print_info "Sending to Snyk Dashboard (org: ${SNYK_ORG})..."
    snyk container monitor ${DOCKER_IMAGE} --org=${SNYK_ORG} --project-name="ibex-webapp-docker-${TIMESTAMP}" > ${REPORT_FILE}.monitor 2>&1 || true
    
    if grep -q "Explore this snapshot at" ${REPORT_FILE}.monitor 2>/dev/null; then
        print_success "Sent to Snyk Dashboard successfully!"
        grep "Explore this snapshot at" ${REPORT_FILE}.monitor
    fi
    
    # Local test
    print_info "Running local scan..."
    snyk container test ${DOCKER_IMAGE} --severity-threshold=high --org=${SNYK_ORG} > ${REPORT_FILE} 2>&1 || true
    
    # JSON report
    snyk container test ${DOCKER_IMAGE} --json --severity-threshold=high --org=${SNYK_ORG} > ${JSON_FILE} 2>&1 || true
    
    if [ -s ${REPORT_FILE} ]; then
        print_success "Docker image scanned with Snyk"
    fi
    
    print_info "Local report: ${REPORT_FILE}"
    print_info "Dashboard: https://app.snyk.io/org/${SNYK_ORG}/projects"
}

# Scan Terraform with Trivy
scan_terraform_trivy() {
    print_header "Scanning Terraform with Trivy"
    
    if ! command -v trivy &> /dev/null; then
        print_warning "Trivy not available, skipping..."
        return 0
    fi
    
    # Navigate to terraform directory
    if [ -d "terraform" ]; then
        cd terraform
    elif [ -f "main.tf" ]; then
        :  # Already in terraform directory
    else
        print_warning "Terraform files not found, skipping..."
        return 0
    fi
    
    REPORT_FILE="../${REPORTS_DIR}/trivy/terraform/trivy-terraform-${TIMESTAMP}.txt"
    JSON_FILE="../${REPORTS_DIR}/trivy/terraform/trivy-terraform-${TIMESTAMP}.json"
    
    print_info "Scanning Terraform configuration..."
    
    # Text report
    trivy config . > ${REPORT_FILE} 2>&1 || true
    
    # JSON report
    trivy config --format json . > ${JSON_FILE} 2>&1 || true
    
    if [ -s ${REPORT_FILE} ]; then
        print_success "Terraform scanned with Trivy"
    fi
    
    print_info "Report: ${REPORT_FILE}"
    
    cd - > /dev/null 2>&1 || true
}

# Scan Terraform with Snyk
scan_terraform_snyk() {
    print_header "Scanning Terraform with Snyk (+ Dashboard Reporting)"
    
    if ! command -v snyk &> /dev/null; then
        print_warning "Snyk not installed, skipping..."
        return 0
    fi
    
    # Check authentication
    if ! snyk auth --check &> /dev/null; then
        print_warning "Snyk not authenticated. Skipping..."
        return 0
    fi
    
    # Navigate to terraform directory
    if [ -d "terraform" ]; then
        cd terraform
    elif [ -f "main.tf" ]; then
        :  # Already in terraform directory
    else
        print_warning "Terraform files not found, skipping..."
        return 0
    fi
    
    REPORT_FILE="../${REPORTS_DIR}/snyk/terraform/snyk-terraform-${TIMESTAMP}.txt"
    JSON_FILE="../${REPORTS_DIR}/snyk/terraform/snyk-terraform-${TIMESTAMP}.json"
    
    print_info "Scanning Terraform and sending to Snyk Dashboard..."
    
    # Test and report to dashboard
    snyk iac test --report --org=${SNYK_ORG} --project-name="ibex-terraform-${TIMESTAMP}" > ${REPORT_FILE} 2>&1 || true
    
    # JSON report
    snyk iac test --json --org=${SNYK_ORG} > ${JSON_FILE} 2>&1 || true
    
    if [ -s ${REPORT_FILE} ]; then
        print_success "Terraform scanned and reported to Snyk Dashboard"
    fi
    
    print_info "Local report: ${REPORT_FILE}"
    print_info "Dashboard: https://app.snyk.io/org/${SNYK_ORG}/projects"
    
    cd - > /dev/null 2>&1 || true
}

# Scan Terraform with Checkov
scan_terraform_checkov() {
    print_header "Scanning Terraform with Checkov"
    
    # Determine checkov command
    if command -v checkov &> /dev/null; then
        CHECKOV_CMD="checkov"
    elif [ -f "checkov-env/bin/checkov" ]; then
        CHECKOV_CMD="$(pwd)/checkov-env/bin/checkov"
    else
        print_warning "Checkov not available, skipping..."
        return 0
    fi
    
    # Navigate to terraform directory
    if [ -d "terraform" ]; then
        cd terraform
    elif [ -f "main.tf" ]; then
        :  # Already in terraform directory
    else
        print_warning "Terraform files not found, skipping..."
        return 0
    fi
    
    REPORT_FILE="../${REPORTS_DIR}/checkov/checkov-terraform-${TIMESTAMP}.txt"
    JSON_FILE="../${REPORTS_DIR}/checkov/checkov-terraform-${TIMESTAMP}.json"
    
    print_info "Scanning Terraform configuration with Checkov..."
    
    # Text report
    ${CHECKOV_CMD} -d . --framework terraform > ${REPORT_FILE} 2>&1 || true
    
    # JSON report
    ${CHECKOV_CMD} -d . --framework terraform -o json > ${JSON_FILE} 2>&1 || true
    
    if [ -s ${REPORT_FILE} ]; then
        print_success "Terraform scanned with Checkov"
        # Extract summary
        if grep -q "Passed checks:" ${REPORT_FILE}; then
            grep "checks:" ${REPORT_FILE} | head -n3
        fi
    fi
    
    print_info "Report: ${REPORT_FILE}"
    
    cd - > /dev/null 2>&1 || true
}

# Generate summary report
generate_summary() {
    print_header "Generating Summary Report"
    
    SUMMARY_FILE="${REPORTS_DIR}/summary/security-scan-summary-${TIMESTAMP}.md"
    
    cat > ${SUMMARY_FILE} << EOF
# Security Scan Summary Report
**Generated:** $(date)
**Docker Image:** ${DOCKER_IMAGE}
**Snyk Organization:** ${SNYK_ORG}

## Dashboard Links
- **Snyk Dashboard:** [View Projects](https://app.snyk.io/org/${SNYK_ORG}/projects)

## Scan Results

### Docker Image Scans
EOF
    
    # Add scan results if they exist
    [ -f "${REPORTS_DIR}/docker-scout/scout-${TIMESTAMP}.txt" ] && echo "- Docker Scout: ✓" >> ${SUMMARY_FILE}
    [ -f "${REPORTS_DIR}/trivy/docker/trivy-docker-${TIMESTAMP}.txt" ] && echo "- Trivy: ✓" >> ${SUMMARY_FILE}
    [ -f "${REPORTS_DIR}/snyk/docker/snyk-docker-${TIMESTAMP}.txt" ] && echo "- Snyk: ✓ (Dashboard updated)" >> ${SUMMARY_FILE}
    
    echo "" >> ${SUMMARY_FILE}
    echo "### Terraform Scans" >> ${SUMMARY_FILE}
    
    [ -f "${REPORTS_DIR}/trivy/terraform/trivy-terraform-${TIMESTAMP}.txt" ] && echo "- Trivy: ✓" >> ${SUMMARY_FILE}
    [ -f "${REPORTS_DIR}/snyk/terraform/snyk-terraform-${TIMESTAMP}.txt" ] && echo "- Snyk: ✓ (Dashboard updated)" >> ${SUMMARY_FILE}
    [ -f "${REPORTS_DIR}/checkov/checkov-terraform-${TIMESTAMP}.txt" ] && echo "- Checkov: ✓" >> ${SUMMARY_FILE}
    
    print_success "Summary report generated: ${SUMMARY_FILE}"
}

# Main execution
main() {
    print_header "Security Scanning Suite for Ibex DevOps Task"
    
    # Install system dependencies first
    install_system_deps
    
    # Setup
    setup_reports_dir
    check_tools
    
    # Docker Image Scans
    scan_docker_scout
    scan_docker_trivy
    scan_docker_snyk
    
    # Terraform Scans
    scan_terraform_trivy
    scan_terraform_snyk
    scan_terraform_checkov
    
    # Generate Summary
    generate_summary
    
    print_header "Scan Complete"
    print_success "All reports saved in: ${REPORTS_DIR}/"
    print_info "Summary: ${REPORTS_DIR}/summary/security-scan-summary-${TIMESTAMP}.md"
    
    # Display quick stats
    echo ""
    echo "Reports generated:"
    find ${REPORTS_DIR} -name "*${TIMESTAMP}*" -type f 2>/dev/null | wc -l
    
    if snyk auth --check &> /dev/null 2>&1; then
        echo ""
        print_info "Check Snyk Dashboard: https://app.snyk.io/org/${SNYK_ORG}/projects"
    fi
}

# Run main function
main "$@"
