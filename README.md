# DevOps Diagnostic CLI

A Bash-based diagnostic command-line application with automated testing, Docker packaging, and a GitHub Actions CI pipeline.

The project demonstrates practical DevOps fundamentals including:

- Bash scripting
- Linux system information
- DNS/host resolution
- TCP connectivity checks
- Input validation
- Exit-code based error handling
- Automated application testing
- Shell syntax and lint validation
- Docker containerization
- Docker smoke testing
- GitHub Actions CI
- Sequential CI job dependencies
- Git-based development workflow

---

## Project Structure

```text
assignment-3/
├── README.md
├── app/
│   └── app.sh
├── scripts/
│   ├── lint.sh
│   └── build.sh
├── tests/
│   └── test.sh
├── .github/
│   └── workflows/
│       └── ci.yml
├── Dockerfile
├── compose.yaml
├── .dockerignore
└── grade.sh