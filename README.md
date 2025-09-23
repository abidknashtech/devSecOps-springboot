# Secure Spring Boot Demo (Gradle + GitHub Actions)

This project demonstrates **DevSecOps security checks** integrated into
a Spring Boot application build using **Gradle** and **GitHub Actions**.

## Features

-   Spring Boot 3.x application (Gradle based).
-   GitHub Actions pipeline with:
    -   Dependency vulnerability scanning using **OWASP
        Dependency-Check**.
    -   Secret scanning (detect hardcoded sensitive data like API keys,
        passwords).
    -   Build and test steps.
    -   Docker image build & push (optional).

## Prerequisites

-   JDK 21+
-   Gradle 8.x
-   Docker (optional, if building container images)

## Build & Run

``` bash
./gradlew clean build
./gradlew bootRun
```

## GitHub Actions Workflow

File: `.github/workflows/security.yml`

``` yaml
name: Security & Build Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up JDK
      uses: actions/setup-java@v3
      with:
        java-version: '21'
        distribution: 'temurin'

    - name: Cache Gradle packages
      uses: actions/cache@v3
      with:
        path: ~/.gradle/caches
        key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
        restore-keys: |
          ${{ runner.os }}-gradle-

    - name: Build with Gradle
      run: ./gradlew clean build --no-daemon

    - name: Run Dependency Check
      uses: dependency-check/Dependency-Check_Action@main
      with:
        project: "SecureSpringBootDemo"
        path: "."
        format: "ALL"

    - name: Run Secret Scanning (Gitleaks)
      uses: gitleaks/gitleaks-action@v2
      with:
        config: gitleaks.toml
```

## Secret Scanning

-   This project integrates **Gitleaks** to detect hardcoded secrets in
    code.
-   Configure rules in `gitleaks.toml`.

## Example Sensitive Info Check

❌ Bad:

``` java
private static final String API_KEY = "12345-SECRET-KEY";
```

✅ Good:

``` java
@Value("${app.api.key}")
private String apiKey;
```

(secrets should be stored in environment variables or Vault).