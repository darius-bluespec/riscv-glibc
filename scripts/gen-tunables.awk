# Generate dl-tunable-list.h from dl-tunables.list

BEGIN {
  tunable=""
  ns=""
  top_ns=""
}

# Skip over blank lines and comments.
/^#/ {
  next
}

/^[ \t]*$/ {
  next
}

# Beginning of either a top namespace, tunable namespace or a tunable, decided
# on the current value of TUNABLE, NS or TOP_NS.
$2 == "{" {
  if (top_ns == "") {
    top_ns = $1
  }
  else if (ns == "") {
    ns = $1
  }
  else if (tunable == "") {
    tunable = $1
  }
  else {
    printf ("Unexpected occurrence of '{': %s:%d\n", FILENAME, FNR)
    exit 1
  }

  next
}

# End of either a top namespace, tunable namespace or a tunable.
$1 == "}" {
  if (tunable != "") {
    # Tunables definition ended, now fill in default attributes.
    if (!types[top_ns][ns][tunable]) {
      types[top_ns][ns][tunable] = "STRING"
    }
    if (!minvals[top_ns][ns][tunable]) {
      minvals[top_ns][ns][tunable] = "0"
    }
    if (!maxvals[top_ns][ns][tunable]) {
      maxvals[top_ns][ns][tunable] = "0"
    }
    if (!env_alias[top_ns][ns][tunable]) {
      env_alias[top_ns][ns][tunable] = "NULL"
    }
    if (!security_level[top_ns][ns][tunable]) {
      security_level[top_ns][ns][tunable] = "SXID_ERASE"
    }

    tunable = ""
  }
  else if (ns != "") {
    ns = ""
  }
  else if (top_ns != "") {
    top_ns = ""
  }
  else {
    printf ("syntax error: extra }: %s:%d\n", FILENAME, FNR)
    exit 1
  }
  next
}

# Everything else, which could either be a tunable without any attributes or a
# tunable attribute.
{
  if (ns == "") {
    printf("Line %d: Invalid tunable outside a namespace: %s\n", NR, $0)
    exit 1
  }

  if (tunable == "") {
    # We encountered a tunable without any attributes, so note it with a
    # default.
    types[top_ns][ns][$1] = "STRING"
    next
  }

  # Otherwise, we have encountered a tunable attribute.
  split($0, arr, ":")
  attr = gensub(/^[ \t]+|[ \t]+$/, "", "g", arr[1])
  val = gensub(/^[ \t]+|[ \t]+$/, "", "g", arr[2])

  if (attr == "type") {
    types[top_ns][ns][tunable] = val
  }
  else if (attr == "minval") {
    minvals[top_ns][ns][tunable] = val
  }
  else if (attr == "maxval") {
    maxvals[top_ns][ns][tunable] = val
  }
  else if (attr == "env_alias") {
    env_alias[top_ns][ns][tunable] = sprintf("\"%s\"", val)
  }
  else if (attr == "security_level") {
    if (val == "SXID_ERASE" || val == "SXID_IGNORE" || val == "NONE") {
      security_level[top_ns][ns][tunable] = val
    }
    else {
      printf("Line %d: Invalid value (%s) for security_level: %s, ", NR, val,
	     $0)
      print("Allowed values are 'SXID_ERASE', 'SXID_IGNORE', or 'NONE'")
      exit 1
    }
  }
  else if (attr == "default") {
    if (types[top_ns][ns][tunable] == "STRING") {
      default_val[top_ns][ns][tunable] = sprintf(".strval = \"%s\"", val);
    }
    else {
      default_val[top_ns][ns][tunable] = sprintf(".numval = %s", val)
    }
  }
}

END {
  if (ns != "") {
    print "Unterminated namespace.  Is a closing brace missing?"
    exit 1
  }

  print "/* AUTOGENERATED by gen-tunables.awk.  */"
  print "#ifndef _TUNABLES_H_"
  print "# error \"Do not include this file directly.\""
  print "# error \"Include tunables.h instead.\""
  print "#endif"
  print "#include <dl-procinfo.h>\n"

  # Now, the enum names
  print "\ntypedef enum"
  print "{"
  for (t in types) {
    for (n in types[t]) {
      for (m in types[t][n]) {
        printf ("  TUNABLE_ENUM_NAME(%s, %s, %s),\n", t, n, m);
      }
    }
  }
  print "} tunable_id_t;\n"

  # Finally, the tunable list.
  print "\n#ifdef TUNABLES_INTERNAL"
  print "static tunable_t tunable_list[] attribute_relro = {"
  for (t in types) {
    for (n in types[t]) {
      for (m in types[t][n]) {
        printf ("  {TUNABLE_NAME_S(%s, %s, %s)", t, n, m)
        printf (", {TUNABLE_TYPE_%s, %s, %s}, {%s}, NULL, TUNABLE_SECLEVEL_%s, %s},\n",
		types[t][n][m], minvals[t][n][m], maxvals[t][n][m],
		default_val[t][n][m], security_level[t][n][m], env_alias[t][n][m]);
      }
    }
  }
  print "};"
  print "#endif"
}