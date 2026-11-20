sudo bash <<'EOF'
set -e

for binary in /usr/bin/uu-*; do
    [ -f "$binary" ] || continue

    command="${binary##*/uu-}"

    ln -sf "$binary" "/usr/local/bin/$command"
done

echo "All available uutils commands have been linked."
EOF
