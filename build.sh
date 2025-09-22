#!/bin/bash

# =============================================================================
# Font Self-Hosting Preparation Script
# =============================================================================
# This script processes TTF/OTF font files to create a self-hosted font package
# with proper metadata extraction, WOFF2 conversion, and CSS generation.
#
# Features:
# - Extracts comprehensive font metadata (Author, License, Source, etc.)
# - Calculates SHA-256 checksums for integrity verification
# - Converts fonts to WOFF2 format for optimal web delivery
# - Generates @font-face CSS with fallback support
# - Creates detailed README with licensing and attribution information
# - Provides CSP-compatible hashes for security policies
#
# Author: Educational Project
# License: MIT
# =============================================================================

set -euo pipefail

# =============================================================================
# Configuration
# =============================================================================

readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="2.0.0"
readonly FONT_DIR="./fonts"
readonly OUTPUT_DIR="./output"
readonly README_FILE="$OUTPUT_DIR/README.md"
readonly CSS_FILE="$OUTPUT_DIR/font-face.css"
readonly LOG_FILE="$OUTPUT_DIR/build.log"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# =============================================================================
# Utility Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Create log entry without colors for file
    local log_entry="[$timestamp] [$level] $message"
    
    # Output to console with colors
    case "$level" in
        "INFO")  echo -e "${GREEN}[INFO]${NC} $message" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
        "DEBUG") echo -e "${BLUE}[DEBUG]${NC} $message" ;;
    esac
    
    # Write clean entry to log file
    echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
}

cleanup_text() {
    echo "${1}" | tr -d '\011\012\013\014\015' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

slugify() {
    echo "$1" | iconv -t ascii//TRANSLIT | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/^-+|-+$//g' | tr '[:upper:]' '[:lower:]'
}

show_help() {
    cat << EOF
Font Self-Hosting Preparation Script v$SCRIPT_VERSION

USAGE:
    $SCRIPT_NAME [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --version       Show version information
    -d, --dir DIR       Font directory (default: ./fonts)
    -o, --output DIR    Output directory (default: ./output)
    -f, --force         Force overwrite existing output
    --no-woff2          Skip WOFF2 conversion
    --verbose           Enable verbose logging

DESCRIPTION:
    This script processes TTF/OTF font files to create a self-hosted font package
    with proper metadata extraction, WOFF2 conversion, and CSS generation.

REQUIREMENTS:
    - ttx (fonttools)
    - xmllint (libxml2-utils)
    - woff2_compress (woff2)
    - openssl

EXAMPLES:
    $SCRIPT_NAME
    $SCRIPT_NAME --dir ./my-fonts --output ./dist
    $SCRIPT_NAME --force --verbose

EOF
}

show_version() {
    echo "$SCRIPT_NAME v$SCRIPT_VERSION"
}

# =============================================================================
# Validation Functions
# =============================================================================

check_dependencies() {
    local missing_deps=()
    
    for cmd in ttx xmllint woff2_compress openssl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "ERROR" "Please install the missing tools and try again."
        exit 1
    fi
}

validate_font_directory() {
    if [ ! -d "$FONT_DIR" ]; then
        log "ERROR" "Font directory '$FONT_DIR' does not exist"
        exit 1
    fi
    
    local font_count
    font_count=$(find "$FONT_DIR" -name "*.ttf" -o -name "*.otf" | wc -l)
    if [ "$font_count" -eq 0 ]; then
        log "ERROR" "No TTF or OTF files found in '$FONT_DIR'"
        exit 1
    fi
    
    log "INFO" "Found $font_count font file(s) in '$FONT_DIR'"
}

# =============================================================================
# Font Processing Functions
# =============================================================================

extract_font_metadata() {
    local font_path="$1"
    local font_xml="$2"
    
    # Extract metadata fields from 'name' table using proper nameID mapping
    # Based on the PHP FontMetadata class reference
    local font_family_name font_subfamily font_full_name font_version
    local font_postscript font_designer font_license_url font_license font_copyright
    
    font_family_name=$(xmllint --xpath "string(//namerecord[@nameID='1'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_subfamily=$(xmllint --xpath "string(//namerecord[@nameID='2'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_full_name=$(xmllint --xpath "string(//namerecord[@nameID='4'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_version=$(xmllint --xpath "string(//namerecord[@nameID='5'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_postscript=$(xmllint --xpath "string(//namerecord[@nameID='6'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_designer=$(xmllint --xpath "string(//namerecord[@nameID='9'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_license_url=$(xmllint --xpath "string(//namerecord[@nameID='14'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_license=$(xmllint --xpath "string(//namerecord[@nameID='13'])" "$font_xml" 2>/dev/null || echo "Unknown")
    font_copyright=$(xmllint --xpath "string(//namerecord[@nameID='0'])" "$font_xml" 2>/dev/null || echo "Unknown")
    
    # Fallback logic for font family name
    if [ "$font_family_name" == "Unknown" ] || [ -z "$font_family_name" ]; then
        font_family_name="$font_full_name"
    fi
    
    if [ -z "$font_family_name" ] || [ "$font_family_name" == "Unknown" ]; then
        font_family_name="$(basename "$font_path" .ttf | sed 's/\.otf$//')"
    fi
    
    # Clean up extracted values
    font_family_name=$(cleanup_text "$font_family_name")
    font_subfamily=$(cleanup_text "$font_subfamily")
    font_full_name=$(cleanup_text "$font_full_name")
    font_version=$(cleanup_text "$font_version")
    font_postscript=$(cleanup_text "$font_postscript")
    font_designer=$(cleanup_text "$font_designer")
    font_license_url=$(cleanup_text "$font_license_url")
    font_license=$(cleanup_text "$font_license")
    font_copyright=$(cleanup_text "$font_copyright")
    
    # Export variables for use in calling function
    export FONT_FAMILY_NAME="$font_family_name"
    export FONT_SUBFAMILY="$font_subfamily"
    export FONT_FULL_NAME="$font_full_name"
    export FONT_VERSION="$font_version"
    export FONT_POSTSCRIPT="$font_postscript"
    export FONT_DESIGNER="$font_designer"
    export FONT_LICENSE_URL="$font_license_url"
    export FONT_LICENSE="$font_license"
    export FONT_COPYRIGHT="$font_copyright"
}

determine_font_weight() {
    local subfamily="$1"
    case "$subfamily" in
        "Thin"|"Hairline") echo "font-weight: 100;" ;;
        "ExtraLight"|"UltraLight") echo "font-weight: 200;" ;;
        "Light") echo "font-weight: 300;" ;;
        "Regular"|"Normal") echo "font-weight: 400;" ;;
        "Medium") echo "font-weight: 500;" ;;
        "SemiBold"|"DemiBold") echo "font-weight: 600;" ;;
        "Bold") echo "font-weight: 700;" ;;
        "ExtraBold"|"UltraBold") echo "font-weight: 800;" ;;
        "Black"|"Heavy") echo "font-weight: 900;" ;;
        *) echo "font-weight: 400;" ;;
    esac
}

determine_font_style() {
    local subfamily="$1"
    case "$subfamily" in
        *"Italic"*|*"Oblique"*) echo "font-style: italic;" ;;
        *) echo "font-style: normal;" ;;
    esac
}

generate_css_font_face() {
    local font_family="$1"
    local font_weight="$2"
    local font_style="$3"
    local woff2_file="$4"
    local original_file="$5"
    
    cat >> "$CSS_FILE" << EOF
@font-face {
  font-family: '$font_family';
  src: url('./$(basename "$woff2_file")') format('woff2'),
       url('./$(basename "$original_file")') format('truetype');
  $font_weight
  $font_style
  font-display: swap;
}
EOF
}

process_font_file() {
    local font_path="$1"
    local font_name font_xml
    font_name=$(basename "$font_path")
    font_xml=$(mktemp)
    
    log "INFO" "Processing font: $font_name"
    
    # Dump TTX XML metadata
    if ! ttx -o "$font_xml" -q "$font_path"; then
        log "ERROR" "Failed to extract metadata from $font_name"
        rm -f "$font_xml"
        return 1
    fi
    
    # Extract metadata
    extract_font_metadata "$font_path" "$font_xml"
    
    # Generate checksums
    local font_checksum
    font_checksum=$(shasum -a 256 "$font_path" | awk '{print $1}')
    
    # Add to README
    cat >> "$README_FILE" << EOF
## $FONT_FULL_NAME
- **File**: \`$font_name\`
- **Family**: $FONT_FAMILY_NAME
- **Subfamily**: $FONT_SUBFAMILY
- **Designer**: $FONT_DESIGNER
- **Version**: $FONT_VERSION
- **PostScript Name**: $FONT_POSTSCRIPT
- **Copyright**: $FONT_COPYRIGHT
- **License**: $FONT_LICENSE
- **License URL**: $FONT_LICENSE_URL
- **SHA-256**: \`$font_checksum\`

EOF
    
    # Convert to WOFF2 if enabled
    if [ "$ENABLE_WOFF2" = true ]; then
        local woff2_file woff2_hash
        woff2_file="$OUTPUT_DIR/${font_name%.*}.woff2"
        if woff2_compress "$font_path" && mv "${font_path%.*}.woff2" "$woff2_file"; then
            log "INFO" "Generated WOFF2: $(basename "$woff2_file")"
            echo "- **WOFF2 generated**: $(basename "$woff2_file")" >> "$README_FILE"
            
            # Generate CSP hash for WOFF2
            woff2_hash=$(openssl dgst -sha256 -binary "$woff2_file" | openssl base64)
            echo "- **CSP-Compatible Font Hash** \`sha256-${woff2_hash}\`" >> "$README_FILE"
        else
            log "WARN" "Failed to convert $font_name to WOFF2"
        fi
    fi
    
    # Copy original font to output directory
    local original_output font_weight font_style
    original_output="$OUTPUT_DIR/$font_name"
    cp "$font_path" "$original_output"
    log "INFO" "Copied original font: $font_name"
    
    # Generate CSS
    font_weight=$(determine_font_weight "$FONT_SUBFAMILY")
    font_style=$(determine_font_style "$FONT_SUBFAMILY")
    
    generate_css_font_face "$FONT_FAMILY_NAME" "$font_weight" "$font_style" \
        "${woff2_file:-$original_output}" "$original_output"
    
    echo "" >> "$README_FILE"
    rm -f "$font_xml"
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    local force_overwrite=false
    local enable_woff2=true
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -d|--dir)
                FONT_DIR="$2"
                shift 2
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            -f|--force)
                force_overwrite=true
                shift
                ;;
            --no-woff2)
                enable_woff2=false
                shift
                ;;
            --verbose)
                verbose=true
                shift
                ;;
            *)
                log "ERROR" "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Set global variables
    export ENABLE_WOFF2="$enable_woff2"
    export VERBOSE="$verbose"
    
    # Setup output directory first
    if [ -d "$OUTPUT_DIR" ] && [ "$force_overwrite" = false ]; then
        echo -e "${RED}[ERROR]${NC} Output directory '$OUTPUT_DIR' already exists. Use --force to overwrite."
        exit 1
    fi
    
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Initialize
    log "INFO" "Starting Font Self-Hosting Preparation Script v$SCRIPT_VERSION"
    
    # Validate environment
    check_dependencies
    validate_font_directory
    
    # Initialize output files
    cat > "$README_FILE" << EOF
# Font Self-Hosting Package

This package contains self-hosted font files with their associated metadata, licensing information, and CSS declarations.

## Generated on: $(date)
## Script version: $SCRIPT_VERSION

EOF
    
    cat > "$CSS_FILE" << EOF
/* Generated @font-face rules */
/* This file contains CSS declarations for self-hosted fonts */

EOF
    
    # Process all font files
    local processed_count=0
    local failed_count=0
    
    for font_path in "$FONT_DIR"/*.ttf "$FONT_DIR"/*.otf; do
        [ -e "$font_path" ] || continue
        
        if process_font_file "$font_path"; then
            ((processed_count++))
        else
            ((failed_count++))
        fi
    done
    
    # Generate final integrity information
    if [ -f "$CSS_FILE" ]; then
        local css_checksum
        css_checksum=$(openssl dgst -sha256 -binary "$CSS_FILE" | openssl base64)
        cat >> "$README_FILE" << EOF

## CSS File Integrity
- **File**: font-face.css
- **SHA-256**: \`$css_checksum\`
- **CSP Header**: \`Content-Security-Policy: font-src 'self' 'sha256-${css_checksum}'\`
- **HTML Link**: \`<link rel="stylesheet" href="./font-face.css" integrity="sha256-${css_checksum}" crossorigin="anonymous">\`

## Usage Instructions
1. Copy all files to your web server
2. Include the CSS file in your HTML: \`<link rel="stylesheet" href="./font-face.css">\`
3. Use the font families in your CSS as specified in the @font-face declarations

## Educational Purpose
This tool was created for educational purposes to demonstrate font metadata extraction,
web font optimization, and self-hosting best practices. Always respect font licenses
and attribution requirements.

EOF
    fi
    
    # Final summary
    log "INFO" "Processing complete!"
    log "INFO" "Successfully processed: $processed_count font(s)"
    if [ $failed_count -gt 0 ]; then
        log "WARN" "Failed to process: $failed_count font(s)"
    fi
    log "INFO" "Output saved in: $OUTPUT_DIR"
    log "INFO" "Files generated:"
    log "INFO" "  - $README_FILE"
    log "INFO" "  - $CSS_FILE"
    if [ "$enable_woff2" = true ]; then
        log "INFO" "  - WOFF2 font files"
    fi
    log "INFO" "  - Original font files"
}

# Run main function with all arguments
main "$@"
