#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
TEMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/scavenger-ios-root-control-XXXXXX")
ATTACKER_ROOT="$TEMP_ROOT/attacker-root"
trap 'rm -rf "$TEMP_ROOT"' EXIT HUP INT TERM
unset MAKEFILES MAKEFILE_LIST

CONTROL_DIR="$TEMP_ROOT/control"
CHECKOUT="$TEMP_ROOT/scavenger-ios's [gate] \"quoted\" \`touch SCAVENGER_IOS_BACKTICK_MARKER\`"
COMMAND_LOG="$TEMP_ROOT/commands.log"
BAD_COMMAND_LOG="$TEMP_ROOT/bad-command.log"
FAKE_SHELL_LOG="$TEMP_ROOT/fake-shell.log"
mkdir "$CONTROL_DIR" "$CHECKOUT" "$CHECKOUT/scripts" "$CHECKOUT/bin" "$ATTACKER_ROOT"
CONTROL_DIR=$(CDPATH= cd -- "$CONTROL_DIR" && /bin/pwd -P)
CHECKOUT=$(CDPATH= cd -- "$CHECKOUT" && /bin/pwd -P)
MAKEFILE="$CHECKOUT/Makefile"
cp "$ROOT_DIR/Makefile" "$MAKEFILE"

for command in ruby swift xcodebuild; do
  cat >"$CHECKOUT/bin/$command" <<'EOF'
#!/bin/sh
printf '%s|%s|%s\n' "$PWD" "$0" "$*" >> "$SCAVENGER_IOS_COMMAND_LOG"
EOF
  chmod +x "$CHECKOUT/bin/$command"
done
cat >"$CHECKOUT/bin/uname" <<'EOF'
#!/bin/sh
printf '%s\n' Darwin
EOF
chmod +x "$CHECKOUT/bin/uname"
cat >"$CHECKOUT/scripts/test-makefile-root.sh" <<'EOF'
#!/bin/sh
printf '%s|%s|root-test\n' "$PWD" "$0" >> "$SCAVENGER_IOS_COMMAND_LOG"
EOF
chmod +x "$CHECKOUT/scripts/test-makefile-root.sh"

BAD_COMMAND="$TEMP_ROOT/bad-command"
cat >"$BAD_COMMAND" <<EOF
#!/bin/sh
printf '%s\n' invoked >> '$BAD_COMMAND_LOG'
exit 91
EOF
chmod +x "$BAD_COMMAND"

FAKE_SHELL="$TEMP_ROOT/fake-shell"
cat >"$FAKE_SHELL" <<EOF
#!/bin/sh
printf '%s\n' invoked >> '$FAKE_SHELL_LOG'
exec /bin/sh "\$@"
EOF
chmod +x "$FAKE_SHELL"

assert_commands_stayed_in_checkout() {
  scenario=$1
  target=$2
  if [ ! -s "$COMMAND_LOG" ]; then
    printf '%s\n' "$scenario $target executed no quality command" >&2
    exit 1
  fi
  while IFS= read -r command; do
    case "$command" in
      "$CONTROL_DIR|"*"$CHECKOUT"*) ;;
      "$CHECKOUT|"*) ;;
      *)
        printf '%s\n' "$scenario $target escaped the checkout: $command" >&2
        exit 1
        ;;
    esac
  done <"$COMMAND_LOG"
}

run_case() {
  scenario=$1
  target=$2
  mode=$3
  rm -f "$COMMAND_LOG" "$BAD_COMMAND_LOG" "$FAKE_SHELL_LOG"
  output="$TEMP_ROOT/output"
  set +e
  case "$mode" in
    default)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-root)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "ROOT=$ATTACKER_ROOT" "$target") >"$output" 2>&1 ;;
    environment-root)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" ROOT="$ATTACKER_ROOT" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-shell)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "SHELL=$FAKE_SHELL" "$target") >"$output" 2>&1 ;;
    environment-shell)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SHELL="$FAKE_SHELL" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-flags)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 '.SHELLFLAGS=-eu -c' "$target") >"$output" 2>&1 ;;
    environment-flags)
      (cd "$CONTROL_DIR" && env '.SHELLFLAGS=-eu -c' PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-ruby)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "RUBY=$BAD_COMMAND" "$target") >"$output" 2>&1 ;;
    environment-ruby)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" RUBY="$BAD_COMMAND" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-swift)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "SWIFT=$BAD_COMMAND" "$target") >"$output" 2>&1 ;;
    environment-swift)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SWIFT="$BAD_COMMAND" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    command-swift-flags)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "SWIFT_TEST_FLAGS=--disable-index-store; $BAD_COMMAND" "$target") >"$output" 2>&1 ;;
    environment-swift-flags)
      (cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SWIFT_TEST_FLAGS="--disable-index-store; $BAD_COMMAND" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 "$target") >"$output" 2>&1 ;;
    *)
      printf '%s\n' "unknown test mode: $mode" >&2
      exit 1 ;;
  esac
  result=$?
  set -e
  if [ "$result" -ne 0 ]; then
    printf '%s\n' "$scenario $target failed" >&2
    cat "$output" >&2
    exit 1
  fi
  assert_commands_stayed_in_checkout "$scenario" "$target"
  if [ -e "$BAD_COMMAND_LOG" ]; then
    printf '%s\n' "$scenario $target executed caller-controlled Ruby, Swift, or Swift flags" >&2
    exit 1
  fi
  if [ -e "$FAKE_SHELL_LOG" ]; then
    printf '%s\n' "$scenario $target executed caller-controlled shell" >&2
    exit 1
  fi
}

for target in build check lint policy-mutation-test policy-test root-test test verify; do
  run_case default "$target" default
  run_case command-root "$target" command-root
  run_case environment-root "$target" environment-root
  run_case command-shell "$target" command-shell
  run_case environment-shell "$target" environment-shell
  run_case command-flags "$target" command-flags
  run_case environment-flags "$target" environment-flags
  run_case command-ruby "$target" command-ruby
  run_case environment-ruby "$target" environment-ruby
  run_case command-swift "$target" command-swift
  run_case environment-swift "$target" environment-swift
  run_case command-swift-flags "$target" command-swift-flags
  run_case environment-swift-flags "$target" environment-swift-flags
done

if [ -e "$CONTROL_DIR/SCAVENGER_IOS_BACKTICK_MARKER" ]; then
  printf '%s\n' "checkout path executed a command substitution" >&2
  exit 1
fi

CONFIG_MARKER="$CONTROL_DIR/SCAVENGER_IOS_CONFIG_MARKER"
(cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" 'RUN_LEGACY_XCODE=`touch SCAVENGER_IOS_CONFIG_MARKER`' build) >"$TEMP_ROOT/run-config.out" 2>&1
[ ! -e "$CONFIG_MARKER" ]
rm -f "$COMMAND_LOG"
(cd "$CONTROL_DIR" && PATH="$CHECKOUT/bin:$PATH" SCAVENGER_IOS_COMMAND_LOG="$COMMAND_LOG" /usr/bin/make --no-print-directory --file "$MAKEFILE" RUN_LEGACY_XCODE=1 'XCODE_DERIVED_DATA=`touch SCAVENGER_IOS_CONFIG_MARKER`' build) >"$TEMP_ROOT/xcode-config.out" 2>&1
[ ! -e "$CONFIG_MARKER" ]
assert_commands_stayed_in_checkout config-data build

if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory --file "$MAKEFILE" MAKEFILE_LIST=/tmp/untrusted check) >"$TEMP_ROOT/command-list.out" 2>&1; then exit 1; fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/command-list.out"
if (cd "$CONTROL_DIR" && MAKEFILE_LIST=/tmp/untrusted /usr/bin/make --environment-overrides --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/environment-list.out" 2>&1; then exit 1; fi
grep -Fq "MAKEFILE_LIST must not be overridden" "$TEMP_ROOT/environment-list.out"
PRELOADED="$TEMP_ROOT/preloaded.mk"
printf '%s\n' 'ROOT := /tmp/preloaded' >"$PRELOADED"
if (cd "$CONTROL_DIR" && MAKEFILES="$PRELOADED" /usr/bin/make --no-print-directory --file "$MAKEFILE" check) >"$TEMP_ROOT/preloaded.out" 2>&1; then exit 1; fi
grep -Fq "MAKEFILES must be empty" "$TEMP_ROOT/preloaded.out"
EARLIER="$TEMP_ROOT/earlier.mk"
printf '%s\n' '# earlier' >"$EARLIER"
if (cd "$CONTROL_DIR" && /usr/bin/make --no-print-directory --file "$EARLIER" --file "$MAKEFILE" check) >"$TEMP_ROOT/multiple.out" 2>&1; then exit 1; fi
grep -Fq "repository Makefile path could not be resolved" "$TEMP_ROOT/multiple.out"
printf '%s\n' "Makefile root tests passed: 104 executed target/authority cases, 2 inert configuration-data cases, 2 MAKEFILE_LIST rejections, 1 MAKEFILES rejection, and 1 multi-Makefile rejection"
