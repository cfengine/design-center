  myhcgrep() {
    awk '/Hard classes/ {for (i=7;i<=NF-1;i++) {print $i}} /Discovered hard classes/ {for (i=4;i<=NF-1;i++) {print $i}}' | grep $1
  }
  alias hcgrep=myhcgrep
