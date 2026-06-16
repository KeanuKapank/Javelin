#!/usr/bin/env bash
# Tests for Docker infrastructure configuration added in PR:
#   Javelin.API/Dockerfile
#   Javelin.API/.dockerignore
#   Javelin.API/Properties/launchSettings.json
#   Javelin.API/Javelin.API.csproj
#   docker-compose.yaml

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCKERFILE="$REPO_ROOT/Javelin.API/Dockerfile"
DOCKERIGNORE="$REPO_ROOT/Javelin.API/.dockerignore"
LAUNCH_SETTINGS="$REPO_ROOT/Javelin.API/Properties/launchSettings.json"
CSPROJ="$REPO_ROOT/Javelin.API/Javelin.API.csproj"
COMPOSE="$REPO_ROOT/docker-compose.yaml"

PASS=0
FAIL=0
FAILURES=()

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

assert_contains() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    if grep -qF "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        Expected to find: $pattern"
        echo "        In file: $file"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_not_contains() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    if ! grep -qF "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        Expected NOT to find: $pattern"
        echo "        In file: $file"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_regex() {
    local description="$1"
    local file="$2"
    local pattern="$3"
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        Expected regex match: $pattern"
        echo "        In file: $file"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_file_exists() {
    local description="$1"
    local file="$2"
    if [ -f "$file" ]; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        File not found: $file"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_json_value() {
    local description="$1"
    local file="$2"
    local jq_path="$3"
    local expected="$4"
    local actual
    actual=$(python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
parts = '$jq_path'.strip('.').split('.')
val = data
for p in parts:
    val = val[p]
print(str(val).lower() if isinstance(val, bool) else val)
" 2>/dev/null)
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        Path: $jq_path"
        echo "        Expected: $expected"
        echo "        Actual:   $actual"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_json_key_exists() {
    local description="$1"
    local file="$2"
    local jq_path="$3"
    if python3 -c "
import json, sys
with open('$file') as f:
    data = json.load(f)
parts = '$jq_path'.strip('.').split('.')
val = data
for p in parts:
    if isinstance(val, dict) and p in val:
        val = val[p]
    else:
        sys.exit(1)
sys.exit(0)
" 2>/dev/null; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        JSON path not found: $jq_path"
        echo "        In file: $file"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

assert_xml_value() {
    local description="$1"
    local file="$2"
    local xpath_expr="$3"
    local expected="$4"
    local actual
    actual=$(python3 -c "
import xml.etree.ElementTree as ET
tree = ET.parse('$file')
root = tree.getroot()
el = root.find('$xpath_expr')
if el is not None:
    print(el.text)
else:
    print('')
" 2>/dev/null)
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $description"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $description"
        echo "        XPath: $xpath_expr"
        echo "        Expected: $expected"
        echo "        Actual:   $actual"
        FAIL=$((FAIL + 1))
        FAILURES+=("$description")
    fi
}

count_matches() {
    local file="$1"
    local pattern="$2"
    grep -c "$pattern" "$file" 2>/dev/null || echo "0"
}

section() {
    echo ""
    echo "=== $1 ==="
}

# ---------------------------------------------------------------------------
# File existence checks
# ---------------------------------------------------------------------------

section "File Existence"

assert_file_exists "Dockerfile exists" "$DOCKERFILE"
assert_file_exists ".dockerignore exists" "$DOCKERIGNORE"
assert_file_exists "launchSettings.json exists" "$LAUNCH_SETTINGS"
assert_file_exists "Javelin.API.csproj exists" "$CSPROJ"
assert_file_exists "docker-compose.yaml exists" "$COMPOSE"

# ---------------------------------------------------------------------------
# Dockerfile tests
# ---------------------------------------------------------------------------

section "Dockerfile - Multi-Stage Build Stages"

assert_regex "base stage uses dotnet/aspnet:10.0-alpine image" \
    "$DOCKERFILE" \
    "^FROM mcr\.microsoft\.com/dotnet/aspnet:10\.0-alpine AS base"

assert_regex "build stage uses dotnet/sdk:10.0-alpine image" \
    "$DOCKERFILE" \
    "^FROM mcr\.microsoft\.com/dotnet/sdk:10\.0-alpine AS build"

assert_regex "publish stage derives from build stage" \
    "$DOCKERFILE" \
    "^FROM build AS publish"

assert_regex "final stage derives from base stage" \
    "$DOCKERFILE" \
    "^FROM base AS final"

section "Dockerfile - Port Exposure"

assert_contains "Exposes HTTP port 8080" "$DOCKERFILE" "EXPOSE 8080"
assert_contains "Exposes HTTPS port 8081" "$DOCKERFILE" "EXPOSE 8081"

section "Dockerfile - Security"

assert_contains "Sets APP_UID user for least-privilege execution" "$DOCKERFILE" "USER \$APP_UID"

section "Dockerfile - Working Directories"

assert_regex "Base stage sets WORKDIR to /app" \
    "$DOCKERFILE" \
    "^WORKDIR /app"

assert_regex "Build stage sets WORKDIR to /src" \
    "$DOCKERFILE" \
    "^WORKDIR /src"

section "Dockerfile - Build Configuration"

assert_regex "ARG BUILD_CONFIGURATION defaults to Release in build stage" \
    "$DOCKERFILE" \
    "^ARG BUILD_CONFIGURATION=Release"

assert_contains "dotnet restore uses .csproj file" \
    "$DOCKERFILE" \
    'dotnet restore "./Javelin.API.csproj"'

assert_contains "dotnet build uses project file" \
    "$DOCKERFILE" \
    'dotnet build "./Javelin.API.csproj"'

assert_regex "dotnet build output goes to /app/build" \
    "$DOCKERFILE" \
    "dotnet build.*-o /app/build"

section "Dockerfile - Publish Stage"

assert_contains "dotnet publish disables AppHost for portability" \
    "$DOCKERFILE" \
    "/p:UseAppHost=false"

assert_regex "dotnet publish output goes to /app/publish" \
    "$DOCKERFILE" \
    "dotnet publish.*-o /app/publish"

section "Dockerfile - Final Stage"

assert_contains "Entrypoint runs Javelin.API.dll" \
    "$DOCKERFILE" \
    'ENTRYPOINT ["dotnet", "Javelin.API.dll"]'

assert_contains "Final stage copies from publish artifact" \
    "$DOCKERFILE" \
    "COPY --from=publish /app/publish ."

section "Dockerfile - Layer Caching Optimization"

# Verify .csproj is copied BEFORE the rest of source (restore layer caching)
csproj_line=$(grep -n 'COPY \["Javelin.API.csproj"' "$DOCKERFILE" | cut -d: -f1 | head -1)
restore_line=$(grep -n 'dotnet restore' "$DOCKERFILE" | cut -d: -f1 | head -1)
copy_all_line=$(grep -n '^COPY \. \.' "$DOCKERFILE" | cut -d: -f1 | head -1)

if [ -n "$csproj_line" ] && [ -n "$restore_line" ] && [ -n "$copy_all_line" ]; then
    if [ "$csproj_line" -lt "$restore_line" ] && [ "$restore_line" -lt "$copy_all_line" ]; then
        echo "  PASS: .csproj copied and restored before full source copy (layer caching)"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: Layer caching pattern: .csproj copy should precede dotnet restore which should precede full source copy"
        FAIL=$((FAIL + 1))
        FAILURES+=("Layer caching pattern: .csproj copy -> restore -> source copy")
    fi
else
    echo "  FAIL: Could not determine layer caching order (missing lines)"
    FAIL=$((FAIL + 1))
    FAILURES+=("Layer caching pattern: could not determine order")
fi

section "Dockerfile - Alpine Image Usage"

# Both base images must be Alpine for smaller image size
alpine_count=$(count_matches "$DOCKERFILE" "alpine")
if [ "$alpine_count" -ge 2 ]; then
    echo "  PASS: Both base images use Alpine variant (smaller attack surface)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Expected at least 2 Alpine image references, found $alpine_count"
    FAIL=$((FAIL + 1))
    FAILURES+=("Both base images should use Alpine variant")
fi

section "Dockerfile - Stage Count"

stage_count=$(count_matches "$DOCKERFILE" "^FROM ")
if [ "$stage_count" -eq 4 ]; then
    echo "  PASS: Dockerfile has exactly 4 build stages"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Expected 4 build stages, found $stage_count"
    FAIL=$((FAIL + 1))
    FAILURES+=("Dockerfile should have exactly 4 build stages")
fi

# ---------------------------------------------------------------------------
# .dockerignore tests
# ---------------------------------------------------------------------------

section ".dockerignore - Build Artifacts Excluded"

assert_contains "bin directories excluded from Docker context" "$DOCKERIGNORE" "**/bin"
assert_contains "obj directories excluded from Docker context" "$DOCKERIGNORE" "**/obj"

section ".dockerignore - IDE and Developer Files Excluded"

assert_contains ".vs directories excluded" "$DOCKERIGNORE" "**/.vs"
assert_contains ".vscode directories excluded" "$DOCKERIGNORE" "**/.vscode"
assert_contains ".git directory excluded" "$DOCKERIGNORE" "**/.git"

section ".dockerignore - Sensitive Files Excluded"

assert_contains ".env files excluded (prevents secret leakage)" "$DOCKERIGNORE" "**/.env"
assert_contains "secrets.dev.yaml excluded" "$DOCKERIGNORE" "**/secrets.dev.yaml"
assert_contains "values.dev.yaml excluded" "$DOCKERIGNORE" "**/values.dev.yaml"

section ".dockerignore - Redundant Docker Files Excluded"

assert_contains "docker-compose files excluded from build context" "$DOCKERIGNORE" "**/docker-compose*"
assert_contains "Dockerfile* files excluded from build context" "$DOCKERIGNORE" "**/Dockerfile*"

section ".dockerignore - Other Artifacts Excluded"

assert_contains "node_modules excluded" "$DOCKERIGNORE" "**/node_modules"
assert_contains "npm-debug.log excluded" "$DOCKERIGNORE" "**/npm-debug.log"
assert_contains "LICENSE excluded from build context" "$DOCKERIGNORE" "LICENSE"
assert_contains "README.md excluded from build context" "$DOCKERIGNORE" "README.md"
assert_contains "*.dbmdl files excluded" "$DOCKERIGNORE" "**/*.dbmdl"
assert_contains "azds.yaml excluded" "$DOCKERIGNORE" "**/azds.yaml"
assert_contains "charts directories excluded" "$DOCKERIGNORE" "**/charts"

section ".dockerignore - Explicit Inclusions (Negation Rules)"

assert_contains ".gitignore explicitly included via negation" "$DOCKERIGNORE" "!**/.gitignore"
assert_contains ".git/HEAD explicitly included" "$DOCKERIGNORE" "!.git/HEAD"
assert_contains ".git/config explicitly included" "$DOCKERIGNORE" "!.git/config"
assert_contains ".git/packed-refs explicitly included" "$DOCKERIGNORE" "!.git/packed-refs"
assert_contains ".git/refs/heads/** explicitly included" "$DOCKERIGNORE" "!.git/refs/heads/**"

section ".dockerignore - Java Project Files Excluded"

assert_contains ".classpath excluded (Java artifact)" "$DOCKERIGNORE" "**/.classpath"
assert_contains ".project excluded (Java artifact)" "$DOCKERIGNORE" "**/.project"
assert_contains ".settings excluded (Java artifact)" "$DOCKERIGNORE" "**/.settings"
assert_contains ".jfm files excluded" "$DOCKERIGNORE" "**/*.jfm"

section ".dockerignore - User-Specific Project Files Excluded"

assert_contains "*.user project files excluded" "$DOCKERIGNORE" "**/*.*proj.user"
assert_contains ".toolstarget excluded" "$DOCKERIGNORE" "**/.toolstarget"

# ---------------------------------------------------------------------------
# launchSettings.json tests
# ---------------------------------------------------------------------------

section "launchSettings.json - Schema"

assert_json_value "Schema points to launchsettings schema store" \
    "$LAUNCH_SETTINGS" \
    '.$schema' \
    "https://json.schemastore.org/launchsettings.json"

section "launchSettings.json - Profile Count"

profile_count=$(python3 -c "
import json
with open('$LAUNCH_SETTINGS') as f:
    data = json.load(f)
print(len(data.get('profiles', {})))
" 2>/dev/null)

if [ "$profile_count" -eq 3 ]; then
    echo "  PASS: Exactly 3 launch profiles defined"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Expected 3 profiles, found $profile_count"
    FAIL=$((FAIL + 1))
    FAILURES+=("launchSettings.json should have 3 profiles")
fi

section "launchSettings.json - HTTP Profile"

assert_json_value "http profile commandName is Project" \
    "$LAUNCH_SETTINGS" \
    ".profiles.http.commandName" \
    "Project"

assert_json_value "http profile applicationUrl targets localhost:5148" \
    "$LAUNCH_SETTINGS" \
    ".profiles.http.applicationUrl" \
    "http://localhost:5148"

assert_json_value "http profile ASPNETCORE_ENVIRONMENT is Development" \
    "$LAUNCH_SETTINGS" \
    ".profiles.http.environmentVariables.ASPNETCORE_ENVIRONMENT" \
    "Development"

assert_json_value "http profile dotnetRunMessages is enabled" \
    "$LAUNCH_SETTINGS" \
    ".profiles.http.dotnetRunMessages" \
    "true"

section "launchSettings.json - HTTPS Profile"

assert_json_value "https profile commandName is Project" \
    "$LAUNCH_SETTINGS" \
    ".profiles.https.commandName" \
    "Project"

assert_json_value "https profile applicationUrl includes HTTPS on port 7123" \
    "$LAUNCH_SETTINGS" \
    ".profiles.https.applicationUrl" \
    "https://localhost:7123;http://localhost:5148"

assert_json_value "https profile ASPNETCORE_ENVIRONMENT is Development" \
    "$LAUNCH_SETTINGS" \
    ".profiles.https.environmentVariables.ASPNETCORE_ENVIRONMENT" \
    "Development"

section "launchSettings.json - Container (Dockerfile) Profile"

assert_json_key_exists "Container (Dockerfile) profile exists" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile)"

assert_json_value "Container profile commandName is Docker" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).commandName" \
    "Docker"

assert_json_value "Container profile launchUrl uses scheme/host/port tokens" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).launchUrl" \
    "{Scheme}://{ServiceHost}:{ServicePort}"

assert_json_value "Container profile ASPNETCORE_HTTP_PORTS is 8080" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).environmentVariables.ASPNETCORE_HTTP_PORTS" \
    "8080"

assert_json_value "Container profile ASPNETCORE_HTTPS_PORTS is 8081" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).environmentVariables.ASPNETCORE_HTTPS_PORTS" \
    "8081"

assert_json_value "Container profile publishAllPorts is true" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).publishAllPorts" \
    "true"

assert_json_value "Container profile useSSL is true" \
    "$LAUNCH_SETTINGS" \
    ".profiles.Container (Dockerfile).useSSL" \
    "true"

section "launchSettings.json - Container Port Consistency with Dockerfile"

# HTTP port 8080 must match EXPOSE 8080 in Dockerfile
if grep -q "EXPOSE 8080" "$DOCKERFILE" && \
   python3 -c "import json; d=json.load(open('$LAUNCH_SETTINGS')); assert d['profiles']['Container (Dockerfile)']['environmentVariables']['ASPNETCORE_HTTP_PORTS']=='8080'" 2>/dev/null; then
    echo "  PASS: Container HTTP port 8080 matches Dockerfile EXPOSE"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Container HTTP port 8080 does not match Dockerfile EXPOSE 8080"
    FAIL=$((FAIL + 1))
    FAILURES+=("Container HTTP port must match Dockerfile EXPOSE")
fi

# HTTPS port 8081 must match EXPOSE 8081 in Dockerfile
if grep -q "EXPOSE 8081" "$DOCKERFILE" && \
   python3 -c "import json; d=json.load(open('$LAUNCH_SETTINGS')); assert d['profiles']['Container (Dockerfile)']['environmentVariables']['ASPNETCORE_HTTPS_PORTS']=='8081'" 2>/dev/null; then
    echo "  PASS: Container HTTPS port 8081 matches Dockerfile EXPOSE"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Container HTTPS port 8081 does not match Dockerfile EXPOSE 8081"
    FAIL=$((FAIL + 1))
    FAILURES+=("Container HTTPS port must match Dockerfile EXPOSE")
fi

# ---------------------------------------------------------------------------
# Javelin.API.csproj tests
# ---------------------------------------------------------------------------

section "Javelin.API.csproj - Docker Properties"

assert_xml_value "DockerDefaultTargetOS is Linux" \
    "$CSPROJ" \
    "PropertyGroup/DockerDefaultTargetOS" \
    "Linux"

assert_xml_value "DockerfileContext is dot (current directory)" \
    "$CSPROJ" \
    "PropertyGroup/DockerfileContext" \
    "."

assert_regex "UserSecretsId is a valid GUID" \
    "$CSPROJ" \
    "<UserSecretsId>[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}</UserSecretsId>"

section "Javelin.API.csproj - Package References"

assert_contains "Microsoft.VisualStudio.Azure.Containers.Tools.Targets referenced" \
    "$CSPROJ" \
    'Include="Microsoft.VisualStudio.Azure.Containers.Tools.Targets"'

assert_contains "Container tools at version 1.23.0" \
    "$CSPROJ" \
    'Version="1.23.0"'

assert_contains "Microsoft.AspNetCore.OpenApi package retained" \
    "$CSPROJ" \
    'Include="Microsoft.AspNetCore.OpenApi"'

section "Javelin.API.csproj - Pre-existing Properties Retained"

assert_xml_value "TargetFramework remains net10.0" \
    "$CSPROJ" \
    "PropertyGroup/TargetFramework" \
    "net10.0"

assert_xml_value "Nullable is enabled" \
    "$CSPROJ" \
    "PropertyGroup/Nullable" \
    "enable"

assert_xml_value "ImplicitUsings is enabled" \
    "$CSPROJ" \
    "PropertyGroup/ImplicitUsings" \
    "enable"

section "Javelin.API.csproj - UserSecretsId Specific Value"

assert_contains "UserSecretsId has correct GUID" \
    "$CSPROJ" \
    "13cfe663-27c3-40d3-be72-6f61ac4b0aa9"

# ---------------------------------------------------------------------------
# docker-compose.yaml tests
# ---------------------------------------------------------------------------

section "docker-compose.yaml - Service Definitions"

assert_contains "kafka service defined" "$COMPOSE" "kafka:"
assert_contains "control-center service defined" "$COMPOSE" "control-center:"

section "docker-compose.yaml - Kafka Service Configuration"

assert_contains "Kafka uses Confluent Platform image" \
    "$COMPOSE" \
    "confluentinc/cp-kafka:7.5.14"

assert_contains "Kafka container named 'kafka'" \
    "$COMPOSE" \
    "container_name: kafka"

assert_contains "Kafka hostname set to 'kafka'" \
    "$COMPOSE" \
    "hostname: kafka"

assert_contains "Kafka external port 9092 mapped" \
    "$COMPOSE" \
    '"9092:9092"'

section "docker-compose.yaml - Kafka KRaft Mode"

assert_contains "Kafka CLUSTER_ID set for KRaft mode" \
    "$COMPOSE" \
    "CLUSTER_ID:"

assert_contains "Kafka configured as both broker and controller" \
    "$COMPOSE" \
    '"broker,controller"'

assert_contains "Kafka NODE_ID set to 1" \
    "$COMPOSE" \
    "KAFKA_NODE_ID: 1"

assert_contains "Kafka controller quorum voters configured" \
    "$COMPOSE" \
    "KAFKA_CONTROLLER_QUORUM_VOTERS:"

section "docker-compose.yaml - Kafka Listener Configuration"

assert_contains "Kafka listener security protocol map includes CONTROLLER" \
    "$COMPOSE" \
    "CONTROLLER:PLAINTEXT"

assert_contains "Kafka listeners include internal PLAINTEXT on port 29092" \
    "$COMPOSE" \
    "PLAINTEXT://kafka:29092"

assert_contains "Kafka listeners include external host port 9092" \
    "$COMPOSE" \
    "PLAINTEXT_HOST://0.0.0.0:9092"

assert_contains "Kafka advertised listeners include external localhost:9092" \
    "$COMPOSE" \
    "PLAINTEXT_HOST://localhost:9092"

assert_contains "Kafka inter-broker listener uses PLAINTEXT" \
    "$COMPOSE" \
    'KAFKA_INTER_BROKER_LISTENER_NAME: "PLAINTEXT"'

assert_contains "Kafka controller listener names set to CONTROLLER" \
    "$COMPOSE" \
    'KAFKA_CONTROLLER_LISTENER_NAMES: "CONTROLLER"'

section "docker-compose.yaml - Kafka Replication (Single Node)"

assert_contains "Kafka offsets topic replication factor is 1 (single-node)" \
    "$COMPOSE" \
    "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1"

section "docker-compose.yaml - Kafka Storage"

assert_contains "Kafka log dirs set to /var/lib/kafka/data" \
    "$COMPOSE" \
    'KAFKA_LOG_DIRS: "/var/lib/kafka/data"'

assert_contains "Kafka data volume mounted at /var/lib/kafka/data" \
    "$COMPOSE" \
    "kafka_kraft:/var/lib/kafka/data"

section "docker-compose.yaml - Control Center Service"

assert_contains "Control Center uses Confluent Enterprise image" \
    "$COMPOSE" \
    "confluentinc/cp-enterprise-control-center:7.5.14"

assert_contains "Control Center container named 'control-center'" \
    "$COMPOSE" \
    "container_name: control-center"

assert_contains "Control Center hostname set" \
    "$COMPOSE" \
    "hostname: control-center"

assert_contains "Control Center external port 9021 mapped" \
    "$COMPOSE" \
    '"9021:9021"'

assert_contains "Control Center depends on kafka service" \
    "$COMPOSE" \
    "depends_on:"

assert_contains "Control Center bootstrap servers point to kafka:29092" \
    "$COMPOSE" \
    'CONTROL_CENTER_BOOTSTRAP_SERVERS: "kafka:29092"'

section "docker-compose.yaml - Control Center Replication (Single Node)"

assert_contains "Control Center replication factor is 1" \
    "$COMPOSE" \
    "CONTROL_CENTER_REPLICATION_FACTOR: 1"

assert_contains "Control Center internal topics partitions is 1" \
    "$COMPOSE" \
    "CONTROL_CENTER_INTERNAL_TOPICS_PARTITIONS: 1"

assert_contains "Control Center monitoring interceptor topic partitions is 1" \
    "$COMPOSE" \
    "CONTROL_CENTER_MONITORING_INTERCEPTOR_TOPIC_PARTITIONS: 1"

assert_contains "Confluent metrics topic replication is 1" \
    "$COMPOSE" \
    "CONFLUENT_METRICS_TOPIC_REPLICATION: 1"

assert_contains "Control Center PORT set to 9021" \
    "$COMPOSE" \
    "PORT: 9021"

section "docker-compose.yaml - Volume Definitions"

assert_contains "kafka_kraft named volume declared" "$COMPOSE" "kafka_kraft:"

# Verify volume is used in kafka service
kafka_volume_usage=$(grep -c "kafka_kraft:/var/lib/kafka/data" "$COMPOSE" 2>/dev/null || echo "0")
if [ "$kafka_volume_usage" -ge 1 ]; then
    echo "  PASS: kafka_kraft volume used by kafka service"
    PASS=$((PASS + 1))
else
    echo "  FAIL: kafka_kraft volume not used by kafka service"
    FAIL=$((FAIL + 1))
    FAILURES+=("kafka_kraft volume should be used by kafka service")
fi

section "docker-compose.yaml - Image Version Consistency"

# Both Kafka images should use the same Confluent Platform version
kafka_version=$(grep "confluentinc/cp-kafka" "$COMPOSE" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)
cc_version=$(grep "confluentinc/cp-enterprise-control-center" "$COMPOSE" | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" | head -1)

if [ "$kafka_version" = "$cc_version" ]; then
    echo "  PASS: Kafka and Control Center use same Confluent Platform version ($kafka_version)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Version mismatch: kafka=$kafka_version, control-center=$cc_version"
    FAIL=$((FAIL + 1))
    FAILURES+=("Kafka and Control Center should use same Confluent Platform version")
fi

section "docker-compose.yaml - Cross-Service Bootstrap Connectivity"

# Control center bootstrap must reference the internal kafka listener (kafka:29092)
# not the external host listener (localhost:9092)
if grep -q "CONTROL_CENTER_BOOTSTRAP_SERVERS.*kafka:29092" "$COMPOSE"; then
    echo "  PASS: Control Center connects to Kafka via internal Docker network (kafka:29092)"
    PASS=$((PASS + 1))
else
    echo "  FAIL: Control Center should bootstrap from kafka:29092 (internal network), not localhost"
    FAIL=$((FAIL + 1))
    FAILURES+=("Control Center should use internal kafka:29092 listener for bootstrap")
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "=============================="
echo "Test Summary"
echo "=============================="
echo "  Passed: $PASS"
echo "  Failed: $FAIL"
echo "  Total:  $((PASS + FAIL))"

if [ "${#FAILURES[@]}" -gt 0 ]; then
    echo ""
    echo "Failed tests:"
    for f in "${FAILURES[@]}"; do
        echo "  - $f"
    done
    echo ""
    exit 1
fi

echo ""
echo "All tests passed."
exit 0
