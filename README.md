# Font Self-Hosting Preparation Script

A professional bash script for processing TTF/OTF font files to create self-hosted font packages with comprehensive metadata extraction, WOFF2 conversion, and CSS generation.

## Authorship & AI Assistance

**Original Author:** Leonardo Poletto (hello@leopoletto.com)  
**AI Assistant:** Claude Sonnet 4 (Anthropic) via Cursor IDE

This project was developed through collaboration between Leonardo Poletto and Claude Sonnet 4. Leonardo provided the original technical requirements, code improvements, performance optimizations, bug fixes, and security enhancements. Claude Sonnet 4 assisted with code refactoring, documentation generation, testing framework implementation, and structural improvements under Leonardo's technical direction and oversight.

The README documentation, LICENSE file, and test suite were generated with AI assistance but based on Leonardo's specifications and requirements.

## 🎯 Purpose

This tool was created for **educational purposes** to demonstrate:
- Font metadata extraction from TTF/OTF files
- Web font optimization techniques
- Self-hosting best practices
- Content Security Policy (CSP) integration
- Font licensing and attribution handling

## ✨ Features

- **Comprehensive Metadata Extraction**: Extracts font family, subfamily, designer, version, copyright, license, and more
- **WOFF2 Conversion**: Converts fonts to WOFF2 format for optimal web delivery
- **Fallback Support**: Includes original TTF/OTF files as fallbacks in CSS declarations
- **Integrity Verification**: Generates SHA-256 checksums for all files
- **CSP Compatibility**: Provides base64-encoded hashes for Content Security Policy headers
- **Professional Logging**: Color-coded output with detailed logging
- **Error Handling**: Robust error handling and validation
- **Command Line Interface**: Full CLI with help, version, and configuration options

## 📋 Requirements

### System Dependencies
- `ttx` (fonttools) - For font metadata extraction
- `xmllint` (libxml2-utils) - For XML parsing
- `woff2_compress` (woff2) - For WOFF2 conversion
- `openssl` - For cryptographic operations

### Installation

#### macOS (using Homebrew)
```bash
brew install fonttools woff2 libxml2
```

#### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install fonttools woff2-tools libxml2-utils openssl
```

#### CentOS/RHEL
```bash
sudo yum install fonttools woff2-tools libxml2 openssl
```

## 🚀 Usage

### Basic Usage
```bash
# Process fonts from ./fonts directory
./build.sh

# Process fonts from custom directory
./build.sh --dir ./my-fonts

# Specify custom output directory
./build.sh --dir ./fonts --output ./dist
```

### Advanced Options
```bash
# Show help
./build.sh --help

# Show version
./build.sh --version

# Force overwrite existing output
./build.sh --force

# Skip WOFF2 conversion
./build.sh --no-woff2

# Enable verbose logging
./build.sh --verbose
```

### Command Line Options

| Option | Description |
|--------|-------------|
| `-h, --help` | Show help message |
| `-v, --version` | Show version information |
| `-d, --dir DIR` | Font directory (default: ./fonts) |
| `-o, --output DIR` | Output directory (default: ./output) |
| `-f, --force` | Force overwrite existing output |
| `--no-woff2` | Skip WOFF2 conversion |
| `--verbose` | Enable verbose logging |

## 📁 Directory Structure

```
project/
├── fonts/                    # Input directory (place your TTF/OTF files here)
│   ├── font1.ttf
│   └── font2.otf
├── output/                   # Generated output directory
│   ├── README.md            # Detailed font information and usage
│   ├── font-face.css        # CSS @font-face declarations
│   ├── font1.woff2         # Optimized WOFF2 files
│   ├── font1.ttf           # Original font files (fallbacks)
│   └── build.log           # Build log file
└── build.sh                 # The script itself
```

## 📄 Output Files

### README.md
Contains detailed information about each processed font:
- Font metadata (family, designer, version, etc.)
- Licensing information
- SHA-256 checksums
- CSP-compatible hashes
- Usage instructions

### font-face.css
Generated CSS file with @font-face declarations:
```css
@font-face {
  font-family: 'Font Name';
  src: url('./font.woff2') format('woff2'),
       url('./font.ttf') format('truetype');
  font-weight: 700;
  font-style: normal;
  font-display: swap;
}
```

### Font Files
- **WOFF2 files**: Optimized for web delivery
- **Original files**: TTF/OTF files as fallbacks

## 🔒 Security Features

### Content Security Policy (CSP) Support
The script generates CSP-compatible hashes for secure font loading:

```html
<!-- HTML -->
<link rel="stylesheet" href="./font-face.css" 
      integrity="sha256-..." crossorigin="anonymous">

<!-- HTTP Headers -->
Content-Security-Policy: font-src 'self' 'sha256-...'
```

### Integrity Verification
All files include SHA-256 checksums for integrity verification.

## 🎓 Educational Value

This script demonstrates several important concepts:

### Font Metadata Extraction
- Uses TTX (fonttools) to extract font metadata
- Parses XML to extract name table information
- Handles various font formats and metadata structures

### Web Font Optimization
- Converts fonts to WOFF2 format for better compression
- Implements proper fallback strategies
- Uses `font-display: swap` for better performance

### Security Best Practices
- Generates CSP-compatible hashes
- Provides integrity verification
- Demonstrates secure font loading techniques

### Font Licensing
- Extracts and displays licensing information
- Ensures proper attribution
- Promotes respect for font licenses

## 🛠️ Technical Details

### Font Metadata Fields Extracted
Based on the OpenType specification name table:

| NameID | Field | Description |
|--------|-------|-------------|
| 0 | Copyright | Copyright notice |
| 1 | Font Family | Font family name |
| 2 | Font Subfamily | Font subfamily name |
| 4 | Full Name | Full font name |
| 5 | Version | Font version |
| 6 | PostScript Name | PostScript name |
| 9 | Designer | Font designer |
| 13 | License | License description |
| 14 | License URL | License URL |

### Font Weight Mapping
The script intelligently maps font subfamily names to CSS font-weight values:

- Thin/Hairline → 100
- ExtraLight/UltraLight → 200
- Light → 300
- Regular/Normal → 400
- Medium → 500
- SemiBold/DemiBold → 600
- Bold → 700
- ExtraBold/UltraBold → 800
- Black/Heavy → 900

## ⚠️ Important Notes

### Educational Purpose
This tool is created for educational purposes. Always:
- Respect font licenses and attribution requirements
- Verify licensing before using fonts commercially
- Follow best practices for font self-hosting

### Font Licensing
- Always check and respect font licenses
- Provide proper attribution when required
- Some fonts may have restrictions on self-hosting

### Performance Considerations
- WOFF2 files are significantly smaller than TTF/OTF
- Use `font-display: swap` for better perceived performance
- Consider preloading critical fonts

## 🤝 Contributing

This is an educational project. Contributions that improve the educational value or add new learning opportunities are welcome.

## 📜 License

This script is released under the MIT License. See the script header for details.

## 🔗 Related Resources

- [OpenType Specification](https://docs.microsoft.com/en-us/typography/opentype/spec/)
- [WOFF2 Specification](https://www.w3.org/TR/WOFF2/)
- [Font Display Descriptor](https://developer.mozilla.org/en-US/docs/Web/CSS/@font-face/font-display)
- [Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

**Remember**: This tool is for educational purposes. Always respect font licenses and attribution requirements when using fonts in your projects.
